defmodule Threadline.Query.ActionHydration do
  @moduledoc false

  # Hidden materialization of AuditTransaction's virtual `:action` field,
  # split out of Threadline.Query to keep that file under the source-size
  # contract's 800-line limit (test/threadline/source_size_contract_test.exs).
  # Groups two cohesive concerns: the batched hydrate_actions/3 replacement
  # for the removed capture/semantics Ecto associations (API-07), and the
  # deprecated public :preload shim that feeds it.

  import Ecto.Query

  alias Threadline.Capture.AuditChange
  alias Threadline.Capture.AuditTransaction
  alias Threadline.Semantics.AuditAction

  @doc false
  # Hidden, batched replacement for the removed capture/semantics Ecto
  # associations. Accepts nil, a single AuditTransaction or AuditChange, or a
  # list of either. AuditChange elements must already have `:transaction`
  # preloaded (an Ecto.Association.NotLoaded transaction raises). Dedupes the
  # non-nil `action_id`s and issues exactly one `WHERE id IN ^ids` query
  # against `audit_actions`, threading `Threadline.Query.storage_opts/2`
  # exactly like the `repo.preload` calls this helper replaces.
  @spec hydrate_actions(
          nil
          | AuditTransaction.t()
          | AuditChange.t()
          | [AuditTransaction.t() | AuditChange.t()],
          module(),
          keyword()
        ) ::
          nil
          | AuditTransaction.t()
          | AuditChange.t()
          | [AuditTransaction.t() | AuditChange.t()]
  def hydrate_actions(items, repo, opts \\ [])

  def hydrate_actions(nil, _repo, _opts), do: nil

  def hydrate_actions(items, repo, opts) when is_list(items) do
    transactions = Enum.map(items, &hydrate_target_transaction/1)

    action_ids =
      transactions
      |> Enum.map(&(&1 && &1.action_id))
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()

    actions_by_id = fetch_actions_by_id(action_ids, repo, opts)

    items
    |> Enum.zip(transactions)
    |> Enum.map(fn {item, transaction} ->
      apply_hydrated_action(item, transaction, actions_by_id)
    end)
  end

  def hydrate_actions(%AuditTransaction{} = transaction, repo, opts) do
    [hydrated] = hydrate_actions([transaction], repo, opts)
    hydrated
  end

  def hydrate_actions(%AuditChange{} = change, repo, opts) do
    [hydrated] = hydrate_actions([change], repo, opts)
    hydrated
  end

  defp hydrate_target_transaction(%AuditTransaction{} = transaction), do: transaction

  defp hydrate_target_transaction(
         %AuditChange{transaction: %Ecto.Association.NotLoaded{}} = change
       ) do
    raise ArgumentError,
          "hydrate_actions/3 requires AuditChange :transaction to be preloaded, got: #{inspect(change)}"
  end

  defp hydrate_target_transaction(%AuditChange{transaction: transaction}), do: transaction

  defp fetch_actions_by_id([], _repo, _opts), do: %{}

  defp fetch_actions_by_id(ids, repo, opts) do
    AuditAction
    |> where([a], a.id in ^ids)
    |> repo.all(Threadline.Query.storage_opts([], opts))
    |> Map.new(&{&1.id, &1})
  end

  defp apply_hydrated_action(%AuditTransaction{} = transaction, _transaction, actions_by_id) do
    %{transaction | action: Map.get(actions_by_id, transaction.action_id)}
  end

  defp apply_hydrated_action(%AuditChange{} = change, nil, _actions_by_id), do: change

  defp apply_hydrated_action(
         %AuditChange{} = change,
         %AuditTransaction{} = transaction,
         actions_by_id
       ) do
    hydrated_transaction = %{transaction | action: Map.get(actions_by_id, transaction.action_id)}
    %{change | transaction: hydrated_transaction}
  end

  @doc false
  # Pulls a bare `:action` (audit_transaction/2) out of a :preload value
  # before it ever reaches `repo.preload/3` — AuditTransaction no longer
  # declares that association, so passing it straight through would raise a
  # raw Ecto error instead of this project's own ArgumentError. A nested key
  # under :action (e.g. `action: :x`) always raises, because AuditAction has
  # no associations to traverse.
  def extract_action_preload(:action), do: {true, []}
  def extract_action_preload(preloads) when is_atom(preloads), do: {false, preloads}

  def extract_action_preload(preloads) when is_list(preloads) do
    Enum.reduce(preloads, {false, []}, fn
      :action, {_found, acc} ->
        {true, acc}

      {:action, _nested}, _acc ->
        raise ArgumentError,
              "AuditAction has no associations to preload through :action, got preload: #{inspect(preloads)}"

      other, {found, acc} ->
        {found, acc ++ [other]}
    end)
  end

  @doc false
  # Same shim for audit_changes_for_transaction/2's `transaction: :action` /
  # `transaction: [:action, ...]` shapes.
  def extract_tx_action_preload(preloads) when is_list(preloads) do
    Enum.reduce(preloads, {false, []}, fn
      {:transaction, :action}, {_found, acc} ->
        {true, acc ++ [:transaction]}

      {:transaction, inner}, {found, acc} when is_list(inner) ->
        case extract_nested_transaction_action(inner, preloads) do
          {true, []} -> {true, acc ++ [:transaction]}
          {true, remaining_inner} -> {true, acc ++ [{:transaction, remaining_inner}]}
          {false, _} -> {found, acc ++ [{:transaction, inner}]}
        end

      other, {found, acc} ->
        {found, acc ++ [other]}
    end)
  end

  defp extract_nested_transaction_action(inner, full_preloads) do
    Enum.reduce(inner, {false, []}, fn
      :action, {_found, acc} ->
        {true, acc}

      {:action, _nested}, _acc ->
        raise ArgumentError,
              "AuditAction has no associations to preload through :action, got preload: #{inspect(full_preloads)}"

      other, {found, acc} ->
        {found, acc ++ [other]}
    end)
  end

  @doc false
  def maybe_warn_deprecated_action_preload(false), do: :ok

  def maybe_warn_deprecated_action_preload(true) do
    IO.warn(
      "Threadline: preloading :action is deprecated and will be removed no earlier than " <>
        "Threadline 2.0. AuditTransaction no longer declares an :action association. Drop " <>
        ":action from :preload; Threadline.transaction_context/2 and " <>
        "Threadline.incident_bundle/2 return the linked AuditAction."
    )
  end
end
