defmodule Threadline.Query do
  @moduledoc """
  Ecto query implementations for the Threadline public API.

  All functions require an explicit `:repo` option and return plain lists of
  Ecto structs. DB errors propagate as exceptions, consistent with `Ecto.Repo.all/2`.

  ## Timeline filters

  `timeline/2`, `timeline_query/1`, and `Threadline.Export` accept the same
  filter keyword list. Only these keys are allowed: `:repo`, `:table`, `:actor_ref`,
  `:from`, `:to`. Unknown keys raise `ArgumentError` (breaking vs pre-1.0 callers
  that relied on silent ignores — see CHANGELOG when upgrading).

  ## See also

  - `Threadline.Export` — CSV / JSON export using the same filter vocabulary.
  """

  import Ecto.Query

  alias Threadline.Capture.AuditChange
  alias Threadline.Capture.AuditTransaction
  alias Threadline.Semantics.ActorRef

  @allowed_timeline_filter_keys ~w(repo table actor_ref from to)a

  @doc """
  Validates that `filters` contains only timeline filter keys.

  Allowed keys: `:repo`, `:table`, `:actor_ref`, `:from`, `:to`.

  Returns `:ok` or raises `ArgumentError`.
  """
  @spec validate_timeline_filters!(keyword()) :: :ok
  def validate_timeline_filters!(filters) when is_list(filters) do
    for {key, _} <- filters do
      if key in @allowed_timeline_filter_keys do
        :ok
      else
        raise ArgumentError,
              "unknown filter key #{inspect(key)}; allowed keys: :repo, :table, :actor_ref, :from, :to"
      end
    end

    :ok
  end

  @doc """
  Builds the shared `AuditChange` query used by `timeline/2` and export.

  Does **not** call `validate_timeline_filters!/1` — callers must validate first
  when accepting external filter lists.
  """
  @spec timeline_query(keyword()) :: Ecto.Query.t()
  def timeline_query(filters) when is_list(filters) do
    AuditChange
    |> join(:inner, [ac], at in AuditTransaction, on: ac.transaction_id == at.id)
    |> filter_by_table(Keyword.get(filters, :table))
    |> filter_by_actor(Keyword.get(filters, :actor_ref))
    |> filter_by_from(Keyword.get(filters, :from))
    |> filter_by_to(Keyword.get(filters, :to))
    |> order_by([ac], desc: ac.captured_at)
    |> order_by([ac], desc: ac.id)
  end

  @doc """
  Query returning one row per matching change with change + transaction columns
  for export (`Threadline.Export`).

  Validates filters, then reuses `timeline_query/1` and extends with `select`.
  """
  @spec export_changes_query(keyword()) :: Ecto.Query.t()
  def export_changes_query(filters) when is_list(filters) do
    validate_timeline_filters!(filters)

    timeline_query(filters)
    |> select([ac, at], %{
      id: ac.id,
      transaction_id: ac.transaction_id,
      table_schema: ac.table_schema,
      table_name: ac.table_name,
      op: ac.op,
      captured_at: ac.captured_at,
      table_pk: ac.table_pk,
      data_after: ac.data_after,
      changed_fields: ac.changed_fields,
      changed_from: ac.changed_from,
      tx_occurred_at: at.occurred_at,
      tx_actor_ref: at.actor_ref,
      tx_source: at.source
    })
  end

  @doc """
  Returns `AuditChange` records for a given schema record, ordered by
  `captured_at` descending.

  ## Options

  - `:repo` — required `Ecto.Repo` module

  ## Example

      Threadline.history(MyApp.User, user.id, repo: MyApp.Repo)

  Each `AuditChange` loads all table columns mapped on the schema, including
  `changed_from` when the database column is populated (no narrowing `select`).
  """
  def history(schema_module, id, opts) do
    repo = Keyword.fetch!(opts, :repo)
    table = schema_module.__schema__(:source)
    [pk_field] = schema_module.__schema__(:primary_key)
    pk_map = %{to_string(pk_field) => id}

    AuditChange
    |> where([ac], ac.table_name == ^table)
    |> where([ac], fragment("? @> ?::jsonb", ac.table_pk, ^pk_map))
    |> order_by([ac], desc: ac.captured_at)
    |> repo.all()
  end

  @doc """
  Returns `AuditTransaction` records for a given actor, ordered by
  `occurred_at` descending.

  For anonymous actors, returns all anonymous transactions (no actor_id
  distinction — all anonymous transactions are equivalent by design, per ACTR-03).

  ## Options

  - `:repo` — required `Ecto.Repo` module

  ## Example

      Threadline.actor_history(actor_ref, repo: MyApp.Repo)
  """
  def actor_history(%ActorRef{} = actor_ref, opts) do
    repo = Keyword.fetch!(opts, :repo)
    actor_map = ActorRef.to_map(actor_ref)

    AuditTransaction
    |> where([at], fragment("? @> ?::jsonb", at.actor_ref, ^actor_map))
    |> order_by([at], desc: at.occurred_at)
    |> repo.all()
  end

  @doc """
  Returns `AuditChange` records across tables, filtered by the given options,
  ordered by `captured_at` descending, then `id` descending.

  ## Options

  - `:table` — string or atom; filters by `table_name`
  - `:actor_ref` — `%ActorRef{}`; filters by actor via joined `audit_transactions`
  - `:from` — `DateTime`; inclusive lower bound on `captured_at`
  - `:to` — `DateTime`; inclusive upper bound on `captured_at`
  - `:repo` — required `Ecto.Repo` module (in `filters` or `opts`; see `Threadline.Export`)

  ## Example

      Threadline.timeline(table: "users", from: ~U[2026-01-01 00:00:00Z], repo: MyApp.Repo)

  ## See also

  - `Threadline.Export` — CSV / JSON export using the same filter vocabulary.
  - `Threadline.export_csv/2` and `Threadline.export_json/2` — top-level delegators.
  """
  def timeline(filters \\ [], opts \\ []) do
    repo =
      Keyword.get(opts, :repo) ||
        Keyword.fetch!(filters, :repo)

    validate_timeline_filters!(filters)

    timeline_query(filters)
    |> select([ac, at], ac)
    |> repo.all()
  end

  # --- Private filter pipeline (expects `at` binding from timeline_query) ---

  defp filter_by_table(query, nil), do: query

  defp filter_by_table(query, table) when is_atom(table) do
    filter_by_table(query, to_string(table))
  end

  defp filter_by_table(query, table) when is_binary(table) do
    where(query, [ac], ac.table_name == ^table)
  end

  defp filter_by_actor(query, nil), do: query

  defp filter_by_actor(query, %ActorRef{} = actor_ref) do
    actor_map = ActorRef.to_map(actor_ref)

    where(query, [ac, at], fragment("? @> ?::jsonb", at.actor_ref, ^actor_map))
  end

  defp filter_by_from(query, nil), do: query

  defp filter_by_from(query, %DateTime{} = from) do
    where(query, [ac], ac.captured_at >= ^from)
  end

  defp filter_by_to(query, nil), do: query

  defp filter_by_to(query, %DateTime{} = to) do
    where(query, [ac], ac.captured_at <= ^to)
  end
end
