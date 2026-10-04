defmodule Threadline.Evidence do
  @moduledoc """
  Threadline evidence records snapshot a subject's status and details at a point in time.

  Use `record_*` functions to append posture snapshots. Use `list_history/2` or
  `list_subject_ref_history/4` to inspect history, `list_latest_subject_refs/3`
  or `list_overview/2` to inspect current snapshots, and
  `get_latest_subject_ref/3` for one subject reference.
  """

  import Ecto.Query

  alias Threadline.Evidence.Subject
  alias Threadline.Governance.EvidenceRecord
  alias Threadline.Semantics.ActorRef
  alias Threadline.StorageSchema

  @schema_version 1
  @allowed_history_filter_keys ~w(repo subject subject_ref from to limit)a
  @allowed_subject_ref_history_filter_keys ~w(repo from to limit)a
  @allowed_latest_filter_keys ~w(repo from to limit)a

  @typedoc "A subject reference represented with atom or string keys and JSON-compatible values."
  @type subject_ref_value ::
          Threadline.json_value()
          | atom()
          | %{optional(atom() | String.t()) => subject_ref_value()}

  @typedoc "A subject reference accepted by an Evidence writer. Atom keys and values are normalized to strings."
  @type subject_ref :: %{optional(atom() | String.t()) => subject_ref_value()}

  @typedoc "Options accepted by Evidence record writers."
  @type record_opt :: Threadline.repo_opt() | Threadline.storage_schema_opt()

  @typedoc "Values accepted for redaction-policy evidence fields cast by the record changeset."
  @type redaction_policy_attr_value ::
          String.t()
          | DateTime.t()
          | NaiveDateTime.t()
          | ActorRef.t()
          | subject_ref()
          | pos_integer()
          | nil

  @typedoc "Caller fields accepted by the changeset: `:summary_status`, `:recorded_at`, `:actor_ref`, `:provenance`, `:detail`, and `:schema_version`. Threadline supplies `:subject`, `:subject_ref`, and defaults."
  @type redaction_policy_attrs :: %{
          optional(atom() | String.t()) => redaction_policy_attr_value()
        }

  @typedoc "Common caller fields cast by Evidence record changesets: `:summary_status`, `:recorded_at`, `:actor_ref`, `:provenance`, `:detail`, and `:schema_version`. Threadline supplies the subject fields and defaults."
  @type record_attrs :: redaction_policy_attrs()

  @typedoc "A top-level atom or string key in redaction-policy evidence attrs."
  @type redaction_policy_attr_key :: atom() | String.t()

  @typedoc "Redaction-policy attrs as a map or keyword list."
  @type redaction_policy_attrs_input ::
          redaction_policy_attrs()
          | [{redaction_policy_attr_key(), redaction_policy_attr_value()}]

  @typedoc "Caller fields for a trigger-coverage snapshot as a map or keyword list. See `record_attrs/0` for the accepted keys."
  @type trigger_coverage_attrs ::
          record_attrs()
          | [{redaction_policy_attr_key(), redaction_policy_attr_value()}]

  @typedoc "Caller fields for a retention-run snapshot as a map or keyword list. See `record_attrs/0` for the accepted keys."
  @type retention_run_attrs ::
          record_attrs()
          | [{redaction_policy_attr_key(), redaction_policy_attr_value()}]

  @typedoc "Caller fields for a retention-policy snapshot as a map or keyword list. See `record_attrs/0` for the accepted keys."
  @type retention_policy_attrs ::
          record_attrs()
          | [{redaction_policy_attr_key(), redaction_policy_attr_value()}]

  @typedoc "Caller fields for an export-delivery snapshot as a map or keyword list. See `record_attrs/0` for the accepted keys."
  @type export_delivery_attrs ::
          record_attrs()
          | [{redaction_policy_attr_key(), redaction_policy_attr_value()}]

  @typedoc "Caller fields for a support-scope snapshot as a map or keyword list. See `record_attrs/0` for the accepted keys."
  @type support_scope_posture_attrs ::
          record_attrs()
          | [{redaction_policy_attr_key(), redaction_policy_attr_value()}]

  @typedoc "A history filter accepted by `list_history/2`."
  @type history_filter ::
          Threadline.repo_opt()
          | {:subject, Subject.subject_descriptor()}
          | {:subject_ref, subject_ref()}
          | {:from, DateTime.t()}
          | {:to, DateTime.t()}
          | {:limit, pos_integer()}

  @typedoc "A subject-reference history filter accepted by `list_subject_ref_history/4`."
  @type subject_ref_history_filter ::
          Threadline.repo_opt()
          | {:from, DateTime.t()}
          | {:to, DateTime.t()}
          | {:limit, pos_integer()}

  @typedoc "A latest-snapshot filter accepted by latest-read functions."
  @type latest_filter ::
          Threadline.repo_opt()
          | {:from, DateTime.t()}
          | {:to, DateTime.t()}
          | {:limit, pos_integer()}

  @typedoc "Options accepted by `list_history/2`."
  @type list_history_opt :: record_opt()

  @typedoc "Options accepted by `list_subject_ref_history/4`."
  @type list_subject_ref_history_opt :: record_opt()

  @typedoc "Options accepted by `list_latest_subject_refs/3`."
  @type list_latest_subject_refs_opt :: record_opt()

  @typedoc "Options accepted by `list_overview/2`."
  @type list_overview_opt :: record_opt()

  @typedoc "Options accepted by `get_latest_subject_ref/3`."
  @type get_latest_subject_ref_opt :: record_opt()

  @typedoc "Result returned by an Evidence record writer."
  @type record_result ::
          {:ok, EvidenceRecord.t()}
          | {:error, Ecto.Changeset.t()}
          | {:error, :missing_repo}
          | {:error, {:invalid_subject_ref, invalid_subject_ref()}}

  @typedoc "A non-map value rejected as an Evidence subject reference."
  @type invalid_subject_ref ::
          atom()
          | bitstring()
          | number()
          | tuple()
          | list()
          | pid()
          | port()
          | reference()
          | function()

  @doc false
  @spec __filter_keys__(atom()) :: [atom()] | :not_closed
  def __filter_keys__(:list_history), do: @allowed_history_filter_keys

  def __filter_keys__(:list_subject_ref_history),
    do: @allowed_subject_ref_history_filter_keys

  def __filter_keys__(:list_latest_subject_refs), do: @allowed_latest_filter_keys
  def __filter_keys__(:list_overview), do: @allowed_latest_filter_keys
  def __filter_keys__(_name), do: :not_closed

  @doc """
  Records a redaction-policy evidence snapshot for `subject_ref` and returns `{:ok, record}` after persistence.

  Evidence records are append-only snapshots. The caller supplies the policy
  status and optional actor, source context, and details.

  ## Options

  - `:repo` — the Ecto repository used to persist the record (required).
  - `:storage_schema` — string storage schema override.

  ## Returns

  Returns `{:ok, %Threadline.Governance.EvidenceRecord{}}` when persisted,
  `{:error, changeset}` when record validation fails, `{:error, :missing_repo}`
  when `:repo` is omitted, or `{:error, {:invalid_subject_ref, value}}` when
  `subject_ref` is not a map.
  Raises `ArgumentError` for an invalid storage schema.
  """
  @spec record_redaction_policy(subject_ref(), redaction_policy_attrs_input(), [record_opt()]) ::
          record_result()
  def record_redaction_policy(subject_ref, attrs, opts \\ []) do
    record_subject("redaction_policy", subject_ref, attrs, opts)
  end

  @doc """
  Records a trigger-coverage evidence snapshot for `subject_ref` and returns `{:ok, record}` after persistence.

  Evidence records are append-only snapshots. The caller supplies the coverage
  status and optional actor, source context, and details.

  ## Options

  - `:repo` — Ecto repository module. Required.
  - `:storage_schema` — string storage schema override. Optional.

  ## Returns

  Returns `{:ok, record}` when persisted, `{:error, changeset}` when record
  validation fails, `{:error, :missing_repo}` when `:repo` is omitted, or
  `{:error, {:invalid_subject_ref, value}}` when `subject_ref` is not a map.
  Raises `ArgumentError` for an invalid storage schema.
  """
  @spec record_trigger_coverage(subject_ref(), trigger_coverage_attrs(), [record_opt()]) ::
          record_result()
  def record_trigger_coverage(subject_ref, attrs, opts \\ []) do
    record_subject("trigger_coverage", subject_ref, attrs, opts)
  end

  @doc """
  Records a retention-run evidence snapshot for `subject_ref` and returns `{:ok, record}` after persistence.

  Evidence records are append-only snapshots. The caller supplies the run
  status and optional actor, source context, and details.

  ## Options

  - `:repo` — Ecto repository module. Required.
  - `:storage_schema` — string storage schema override. Optional.

  ## Returns

  Returns `{:ok, record}` when persisted, `{:error, changeset}` when record
  validation fails, `{:error, :missing_repo}` when `:repo` is omitted, or
  `{:error, {:invalid_subject_ref, value}}` when `subject_ref` is not a map.
  Raises `ArgumentError` for an invalid storage schema.
  """
  @spec record_retention_run(subject_ref(), retention_run_attrs(), [record_opt()]) ::
          record_result()
  def record_retention_run(subject_ref, attrs, opts \\ []) do
    record_subject("retention_run", subject_ref, attrs, opts)
  end

  @doc """
  Records a retention-policy evidence snapshot for `subject_ref` and returns `{:ok, record}` after persistence.

  Evidence records are append-only snapshots. The caller supplies the policy
  status and optional actor, source context, and details.

  ## Options

  - `:repo` — Ecto repository module. Required.
  - `:storage_schema` — string storage schema override. Optional.

  ## Returns

  Returns `{:ok, record}` when persisted, `{:error, changeset}` when record
  validation fails, `{:error, :missing_repo}` when `:repo` is omitted, or
  `{:error, {:invalid_subject_ref, value}}` when `subject_ref` is not a map.
  Raises `ArgumentError` for an invalid storage schema.
  """
  @spec record_retention_policy(subject_ref(), retention_policy_attrs(), [record_opt()]) ::
          record_result()
  def record_retention_policy(subject_ref, attrs, opts \\ []) do
    record_subject("retention_policy", subject_ref, attrs, opts)
  end

  @doc """
  Records an export-delivery evidence snapshot for `subject_ref` and returns `{:ok, record}` after persistence.

  Evidence records are append-only snapshots. The caller supplies the delivery
  status and optional actor, source context, and details.

  ## Options

  - `:repo` — Ecto repository module. Required.
  - `:storage_schema` — string storage schema override. Optional.

  ## Returns

  Returns `{:ok, record}` when persisted, `{:error, changeset}` when record
  validation fails, `{:error, :missing_repo}` when `:repo` is omitted, or
  `{:error, {:invalid_subject_ref, value}}` when `subject_ref` is not a map.
  Raises `ArgumentError` for an invalid storage schema.
  """
  @spec record_export_delivery(subject_ref(), export_delivery_attrs(), [record_opt()]) ::
          record_result()
  def record_export_delivery(subject_ref, attrs, opts \\ []) do
    record_subject("export_delivery", subject_ref, attrs, opts)
  end

  @doc """
  Records a support-scope evidence snapshot for `subject_ref` and returns `{:ok, record}` after persistence.

  Evidence records are append-only snapshots. The caller supplies the scope
  status and optional actor, source context, and details.

  ## Options

  - `:repo` — Ecto repository module. Required.
  - `:storage_schema` — string storage schema override. Optional.

  ## Returns

  Returns `{:ok, record}` when persisted, `{:error, changeset}` when record
  validation fails, `{:error, :missing_repo}` when `:repo` is omitted, or
  `{:error, {:invalid_subject_ref, value}}` when `subject_ref` is not a map.
  Raises `ArgumentError` for an invalid storage schema.
  """
  @spec record_support_scope_posture(subject_ref(), support_scope_posture_attrs(), [record_opt()]) ::
          record_result()
  def record_support_scope_posture(subject_ref, attrs, opts \\ []) do
    record_subject("support_scope_posture", subject_ref, attrs, opts)
  end

  @doc """
  Returns matching `EvidenceRecord` snapshots ordered newest first by recorded time and ID.

  Use `list_subject_ref_history/4` to read one subject reference's history.
  This function can combine multiple subjects and references; `:from` and
  `:to` are inclusive, and `:limit` caps the returned list.

  ## Filters

  - `:repo` — Ecto repository module. Optional when supplied in options.
  - `:subject` — supported subject name, atom, or descriptor. Optional.
  - `:subject_ref` — subject reference map. Optional.
  - `:from` — `DateTime`. Optional; inclusive lower bound on `recorded_at`.
  - `:to` — `DateTime`. Optional; inclusive upper bound on `recorded_at`.
  - `:limit` — positive integer. Optional; caps the result list.

  Unknown keys raise `ArgumentError` naming the allowed keys.

  ## Options

  - `:repo` — Ecto repository module. Required in filters or options; the option takes precedence.
  - `:storage_schema` — string storage schema override. Optional.

  ## Returns

  Returns a list of `%Threadline.Governance.EvidenceRecord{}` rows, including
  an empty list when no records match. Raises `ArgumentError` for invalid
  filters, a missing repository, or an invalid storage schema.
  """
  @spec list_history([history_filter()], [list_history_opt()]) :: [EvidenceRecord.t()]
  def list_history(filters, opts \\ []) when is_list(filters) and is_list(opts) do
    filters = validate_filters!(filters, @allowed_history_filter_keys, :history)
    repo = evidence_repo!(filters, opts)

    EvidenceRecord
    |> maybe_filter_subject(Keyword.get(filters, :subject))
    |> maybe_filter_subject_ref(Keyword.get(filters, :subject_ref))
    |> maybe_filter_from(Keyword.get(filters, :from))
    |> maybe_filter_to(Keyword.get(filters, :to))
    |> order_by([record], desc: record.recorded_at, desc: record.id)
    |> maybe_limit(Keyword.get(filters, :limit))
    |> repo.all(StorageSchema.repo_opts(filters ++ opts))
  end

  @doc """
  Returns `EvidenceRecord` snapshots for one subject and subject reference, newest first by recorded time and ID.

  Use `list_history/2` to combine multiple subjects or references. The supplied
  filters add inclusive time bounds and a result limit to the fixed subject and
  reference.

  ## Filters

  - `:repo` — Ecto repository module. Optional when supplied in options.
  - `:from` — `DateTime`. Optional; inclusive lower bound on `recorded_at`.
  - `:to` — `DateTime`. Optional; inclusive upper bound on `recorded_at`.
  - `:limit` — positive integer. Optional; caps the result list.

  Unknown keys raise `ArgumentError` naming the allowed keys.

  ## Options

  - `:repo` — Ecto repository module. Required in filters or options; the option takes precedence.
  - `:storage_schema` — string storage schema override. Optional.

  ## Returns

  Returns a list of matching `%Threadline.Governance.EvidenceRecord{}` rows,
  including an empty list when none match. Raises `ArgumentError` for an
  unsupported subject, invalid subject reference or filter, a missing
  repository, or an invalid storage schema.
  """
  @spec list_subject_ref_history(
          Subject.subject_descriptor(),
          subject_ref(),
          [subject_ref_history_filter()],
          [list_subject_ref_history_opt()]
        ) :: [EvidenceRecord.t()]
  @spec list_subject_ref_history(
          Subject.subject_descriptor(),
          subject_ref(),
          [list_subject_ref_history_opt()]
        ) :: [EvidenceRecord.t()]
  def list_subject_ref_history(subject, subject_ref, filters \\ [], opts)
      when is_list(filters) and is_list(opts) do
    filters =
      filters
      |> validate_filters!(@allowed_subject_ref_history_filter_keys, :subject_ref_history)
      |> Keyword.put(:subject, subject)
      |> Keyword.put(:subject_ref, subject_ref)

    list_history(filters, opts)
  end

  @doc """
  Returns the newest `EvidenceRecord` for each reference in one subject family, newest first.

  Use `list_history/2` to inspect every snapshot in the family. The date bounds
  apply before the newest row per reference is selected.

  ## Filters

  - `:repo` — Ecto repository module. Optional when supplied in options.
  - `:from` — `DateTime`. Optional; inclusive lower bound on `recorded_at`.
  - `:to` — `DateTime`. Optional; inclusive upper bound on `recorded_at`.
  - `:limit` — positive integer. Optional; caps the result list.

  Unknown keys raise `ArgumentError` naming the allowed keys.

  ## Options

  - `:repo` — Ecto repository module. Required in filters or options; the option takes precedence.
  - `:storage_schema` — string storage schema override. Optional.

  ## Returns

  Returns a list with at most one row per subject reference, or an empty list
  when no records match. Raises `ArgumentError` for an unsupported subject, an
  invalid filter, a missing repository, or an invalid storage schema.
  """
  @spec list_latest_subject_refs(
          Subject.subject_descriptor(),
          [latest_filter()],
          [list_latest_subject_refs_opt()]
        ) :: [EvidenceRecord.t()]
  @spec list_latest_subject_refs(
          Subject.subject_descriptor(),
          [list_latest_subject_refs_opt()]
        ) :: [EvidenceRecord.t()]
  def list_latest_subject_refs(subject, filters \\ [], opts)
      when is_list(filters) and is_list(opts) do
    filters = validate_filters!(filters, @allowed_latest_filter_keys, :latest_subject_refs)
    repo = evidence_repo!(filters, opts)
    normalized_subject = validate_subject!(subject)

    EvidenceRecord
    |> where([record], record.subject == ^normalized_subject)
    |> maybe_filter_from(Keyword.get(filters, :from))
    |> maybe_filter_to(Keyword.get(filters, :to))
    |> distinct([record], record.subject_ref)
    |> order_by([record], asc: record.subject_ref, desc: record.recorded_at, desc: record.id)
    |> maybe_limit(Keyword.get(filters, :limit))
    |> repo.all(StorageSchema.repo_opts(filters ++ opts))
    |> Enum.sort_by(
      fn record -> {DateTime.to_unix(record.recorded_at, :microsecond), record.id} end,
      :desc
    )
  end

  @doc """
  Returns the newest `EvidenceRecord` for each subject reference across all supported subjects, newest first.

  Use `list_latest_subject_refs/3` when the read should cover one subject
  family. Inclusive date bounds apply before each latest row is selected.

  ## Filters

  - `:repo` — Ecto repository module. Optional when supplied in options.
  - `:from` — `DateTime`. Optional; inclusive lower bound on `recorded_at`.
  - `:to` — `DateTime`. Optional; inclusive upper bound on `recorded_at`.
  - `:limit` — positive integer. Optional; caps the combined result list.

  Unknown keys raise `ArgumentError` naming the allowed keys.

  ## Options

  - `:repo` — Ecto repository module. Required in filters or options; the option takes precedence.
  - `:storage_schema` — string storage schema override. Optional.

  ## Returns

  Returns a list with at most one row per subject reference, or an empty list
  when no records match. Raises `ArgumentError` for an invalid filter, a
  missing repository, or an invalid storage schema.
  """
  @spec list_overview([latest_filter()], [list_overview_opt()]) :: [EvidenceRecord.t()]
  def list_overview(filters, opts \\ []) when is_list(filters) and is_list(opts) do
    filters = validate_filters!(filters, @allowed_latest_filter_keys, :overview)
    repo = evidence_repo!(filters, opts)
    limit = Keyword.get(filters, :limit)
    subject_filters = Keyword.delete(filters, :limit)
    subject_opts = Keyword.put(opts, :repo, repo)

    Subject.supported_subjects()
    |> Enum.flat_map(fn subject ->
      list_latest_subject_refs(subject, subject_filters, subject_opts)
    end)
    |> Enum.sort_by(
      fn record -> {DateTime.to_unix(record.recorded_at, :microsecond), record.id} end,
      :desc
    )
    |> maybe_take(limit)
  end

  @doc """
  Returns the newest `EvidenceRecord` for one subject and subject reference, or `nil` when none exists.

  Use `list_subject_ref_history/4` when every snapshot for the reference is
  needed. This lookup uses the full subject reference and does not apply date
  bounds or a result limit.

  ## Options

  - `:repo` — Ecto repository module. Required.
  - `:storage_schema` — string storage schema override. Optional.

  ## Returns

  Returns the newest `%Threadline.Governance.EvidenceRecord{}` or `nil` when no
  row matches. Raises `ArgumentError` for an unsupported subject, an invalid
  subject reference, a missing repository, or an invalid storage schema.
  """
  @spec get_latest_subject_ref(
          Subject.subject_descriptor(),
          subject_ref(),
          [get_latest_subject_ref_opt()]
        ) :: EvidenceRecord.t() | nil
  def get_latest_subject_ref(subject, subject_ref, opts) when is_list(opts) do
    repo = evidence_repo!([], opts)
    normalized_subject = validate_subject!(subject)
    normalized_subject_ref = normalize_subject_ref!(subject_ref)

    EvidenceRecord
    |> where([record], record.subject == ^normalized_subject)
    |> where([record], record.subject_ref == ^normalized_subject_ref)
    |> order_by([record], desc: record.recorded_at, desc: record.id)
    |> limit(1)
    |> repo.one(StorageSchema.repo_opts(opts))
  end

  defp record_subject(subject, subject_ref, attrs, opts) do
    attr_map = normalize_attrs(attrs)
    entrypoint = "record_#{subject}"

    with :ok <- validate_repo(Keyword.get(opts, :repo)),
         :ok <- Subject.validate(subject),
         {:ok, normalized_subject_ref} <- normalize_subject_ref(subject_ref) do
      attrs = build_record_attrs(subject, normalized_subject_ref, attr_map, entrypoint)

      %EvidenceRecord{}
      |> EvidenceRecord.changeset(attrs)
      |> Keyword.fetch!(opts, :repo).insert(StorageSchema.repo_opts(opts))
    end
  end

  defp build_record_attrs(subject, subject_ref, attrs, entrypoint) do
    attrs
    |> Map.put(:subject, subject)
    |> Map.put(:subject_ref, subject_ref)
    |> Map.put_new(:recorded_at, DateTime.utc_now(:microsecond))
    |> Map.put_new(:schema_version, @schema_version)
    |> Map.put(:provenance, provenance(attrs[:provenance], entrypoint))
    |> Map.update(:detail, nil, &normalize_map_values/1)
  end

  defp provenance(extra, entrypoint) do
    %{
      "writer" => "threadline",
      "entrypoint" => entrypoint
    }
    |> Map.merge(normalize_optional_map(extra))
  end

  defp normalize_optional_map(nil), do: %{}
  defp normalize_optional_map(value), do: normalize_map_values(value)

  defp normalize_attrs(attrs) when is_list(attrs),
    do: attrs |> Enum.into(%{}) |> normalize_attrs()

  defp normalize_attrs(attrs) when is_map(attrs), do: Map.new(attrs)

  defp normalize_subject_ref(subject_ref) when is_map(subject_ref) do
    {:ok, normalize_map_values(subject_ref)}
  end

  defp normalize_subject_ref(other), do: {:error, {:invalid_subject_ref, other}}

  defp normalize_subject_ref!(subject_ref) do
    case normalize_subject_ref(subject_ref) do
      {:ok, normalized_subject_ref} ->
        normalized_subject_ref

      {:error, {:invalid_subject_ref, value}} ->
        raise ArgumentError, "subject_ref must be a map, got: #{inspect(value)}"
    end
  end

  defp normalize_map_values(value) when is_map(value) do
    Map.new(value, fn {key, nested_value} ->
      {normalize_map_key(key), normalize_map_values(nested_value)}
    end)
  end

  defp normalize_map_values(value) when is_list(value),
    do: Enum.map(value, &normalize_map_values/1)

  defp normalize_map_values(value) when is_atom(value), do: Atom.to_string(value)
  defp normalize_map_values(value), do: value

  defp maybe_take(records, nil), do: records
  defp maybe_take(records, limit), do: Enum.take(records, limit)

  defp normalize_map_key(key) when is_atom(key), do: Atom.to_string(key)
  defp normalize_map_key(key) when is_binary(key), do: key
  defp normalize_map_key(key), do: to_string(key)

  defp validate_filters!(filters, allowed_keys, label) when is_list(filters) do
    Enum.each(filters, fn {key, value} ->
      cond do
        key not in allowed_keys ->
          allowed = Enum.map_join(allowed_keys, ", ", &inspect/1)

          raise ArgumentError,
                "unknown evidence #{label} filter key #{inspect(key)}. Allowed: #{allowed}"

        key == :subject ->
          validate_subject!(value)

        key == :subject_ref ->
          normalize_subject_ref!(value)

        key == :from ->
          validate_datetime!(value, :from)

        key == :to ->
          validate_datetime!(value, :to)

        key == :limit ->
          validate_limit!(value)

        true ->
          :ok
      end
    end)

    filters
  end

  defp evidence_repo!(filters, opts) when is_list(filters) and is_list(opts) do
    case Keyword.get(opts, :repo) || Keyword.get(filters, :repo) do
      nil ->
        raise ArgumentError,
              "missing :repo for evidence APIs — pass `repo: MyApp.Repo` in filters or opts."

      repo when is_atom(repo) ->
        repo

      other ->
        raise ArgumentError,
              "evidence :repo must be an Ecto.Repo module (atom), got: #{inspect(other)}"
    end
  end

  defp validate_subject!(subject) do
    normalized_subject = normalize_subject!(subject)

    case Subject.validate(normalized_subject) do
      :ok ->
        normalized_subject

      {:error, {:unsupported_subject, value}} ->
        raise ArgumentError, "unsupported evidence subject: #{inspect(value)}"
    end
  end

  # Clause order is the original branch order (first match wins).
  defp normalize_subject!(%{subject: nested_subject}), do: validate_subject!(nested_subject)
  defp normalize_subject!(%{name: nested_subject}), do: validate_subject!(nested_subject)
  defp normalize_subject!(%{"subject" => nested_subject}), do: validate_subject!(nested_subject)
  defp normalize_subject!(%{"name" => nested_subject}), do: validate_subject!(nested_subject)
  defp normalize_subject!(value) when is_atom(value), do: Atom.to_string(value)
  defp normalize_subject!(value) when is_binary(value), do: value
  defp normalize_subject!(value), do: value

  defp validate_datetime!(%DateTime{}, _label), do: :ok

  defp validate_datetime!(value, label) do
    raise ArgumentError, "#{inspect(label)} must be a DateTime, got: #{inspect(value)}"
  end

  defp validate_limit!(value) when is_integer(value) and value > 0, do: :ok

  defp validate_limit!(value) do
    raise ArgumentError, ":limit must be a positive integer, got: #{inspect(value)}"
  end

  defp maybe_filter_subject(query, nil), do: query

  defp maybe_filter_subject(query, subject) do
    normalized_subject = validate_subject!(subject)
    where(query, [record], record.subject == ^normalized_subject)
  end

  defp maybe_filter_subject_ref(query, nil), do: query

  defp maybe_filter_subject_ref(query, subject_ref) do
    normalized_subject_ref = normalize_subject_ref!(subject_ref)
    where(query, [record], record.subject_ref == ^normalized_subject_ref)
  end

  defp maybe_filter_from(query, nil), do: query

  defp maybe_filter_from(query, %DateTime{} = from) do
    where(query, [record], record.recorded_at >= ^from)
  end

  defp maybe_filter_to(query, nil), do: query

  defp maybe_filter_to(query, %DateTime{} = to) do
    where(query, [record], record.recorded_at <= ^to)
  end

  defp maybe_limit(query, nil), do: query
  defp maybe_limit(query, limit), do: limit(query, ^limit)

  defp validate_repo(nil), do: {:error, :missing_repo}
  defp validate_repo(_repo), do: :ok
end
