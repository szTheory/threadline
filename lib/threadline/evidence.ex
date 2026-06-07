defmodule Threadline.Evidence do
  @moduledoc """
  Public create/read boundary for Threadline-owned evidence records.

  Evidence helpers stay Phoenix-optional, require explicit `repo:` handling, and
  keep the closed subject inventory enforced through subject-focused entrypoints.
  """

  import Ecto.Query

  alias Threadline.Evidence.Subject
  alias Threadline.Governance.EvidenceRecord
  alias Threadline.StorageSchema

  @schema_version 1
  @allowed_history_filter_keys ~w(repo subject subject_ref from to limit)a
  @allowed_subject_ref_history_filter_keys ~w(repo from to limit)a
  @allowed_latest_filter_keys ~w(repo from to limit)a

  @doc """
  Records redaction policy posture evidence.
  """
  def record_redaction_policy(subject_ref, attrs, opts \\ []) do
    record_subject("redaction_policy", subject_ref, attrs, opts)
  end

  @doc """
  Records trigger coverage posture evidence.
  """
  def record_trigger_coverage(subject_ref, attrs, opts \\ []) do
    record_subject("trigger_coverage", subject_ref, attrs, opts)
  end

  @doc """
  Records retention-run evidence.
  """
  def record_retention_run(subject_ref, attrs, opts \\ []) do
    record_subject("retention_run", subject_ref, attrs, opts)
  end

  @doc """
  Records retention-policy posture evidence.
  """
  def record_retention_policy(subject_ref, attrs, opts \\ []) do
    record_subject("retention_policy", subject_ref, attrs, opts)
  end

  @doc """
  Records export-delivery evidence.
  """
  def record_export_delivery(subject_ref, attrs, opts \\ []) do
    record_subject("export_delivery", subject_ref, attrs, opts)
  end

  @doc """
  Records support-scope posture evidence.
  """
  def record_support_scope_posture(subject_ref, attrs, opts \\ []) do
    record_subject("support_scope_posture", subject_ref, attrs, opts)
  end

  @doc """
  Returns append-only evidence history ordered by newest first.
  """
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
  Returns append-only history for one subject and one subject reference.
  """
  def list_subject_ref_history(subject, subject_ref, filters, opts)
      when is_list(filters) and is_list(opts) do
    filters =
      filters
      |> validate_filters!(@allowed_subject_ref_history_filter_keys, :subject_ref_history)
      |> Keyword.put(:subject, subject)
      |> Keyword.put(:subject_ref, subject_ref)

    list_history(filters, opts)
  end

  def list_subject_ref_history(subject, subject_ref, opts)
      when is_list(opts) do
    list_subject_ref_history(subject, subject_ref, [], opts)
  end

  @doc """
  Returns the newest row for each subject reference for one subject family.
  """
  def list_latest_subject_refs(subject, filters, opts)
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

  def list_latest_subject_refs(subject, opts) when is_list(opts) do
    list_latest_subject_refs(subject, [], opts)
  end

  @doc """
  Returns the newest row per subject reference across the closed subject
  inventory, newest first.
  """
  def list_overview(filters, opts \\ []) when is_list(filters) and is_list(opts) do
    filters = validate_filters!(filters, @allowed_latest_filter_keys, :overview)
    repo = evidence_repo!(filters, opts)
    limit = Keyword.get(filters, :limit)
    subject_filters = Keyword.delete(filters, :limit)

    Subject.supported_subjects()
    |> Enum.flat_map(fn subject ->
      list_latest_subject_refs(subject, subject_filters, repo: repo)
    end)
    |> Enum.sort_by(
      fn record -> {DateTime.to_unix(record.recorded_at, :microsecond), record.id} end,
      :desc
    )
    |> maybe_take(limit)
  end

  @doc """
  Returns the newest row for one subject and one subject reference, or `nil`.
  """
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
    normalized_subject =
      case subject do
        %{subject: nested_subject} -> validate_subject!(nested_subject)
        %{name: nested_subject} -> validate_subject!(nested_subject)
        %{"subject" => nested_subject} -> validate_subject!(nested_subject)
        %{"name" => nested_subject} -> validate_subject!(nested_subject)
        value when is_atom(value) -> Atom.to_string(value)
        value when is_binary(value) -> value
        value -> value
      end

    case Subject.validate(normalized_subject) do
      :ok ->
        normalized_subject

      {:error, {:unsupported_subject, value}} ->
        raise ArgumentError, "unsupported evidence subject: #{inspect(value)}"
    end
  end

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
