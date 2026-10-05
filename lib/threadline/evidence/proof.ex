defmodule Threadline.Evidence.Proof do
  @moduledoc """
  A proof document summarizes evidence snapshots and the claims they support.

  Use `proof_document/2` to work with the JSON-ready map,
  `to_json_iodata/2` to encode it, and `render_json/1` or `render_human/1` to
  print it from a command-line task.
  """

  alias Threadline.Evidence
  alias Threadline.Evidence.Subject
  alias Threadline.Governance.EvidenceRecord
  alias Threadline.Semantics.ActorRef

  @format_version 1
  @proof_type "threadline_evidence"
  @semantic_statuses ~w(proven inferred_posture unsupported)
  @error_statuses ~w(invalid_request runtime_failure)
  @posture_subjects ~w(redaction_policy retention_policy support_scope_posture)

  @typedoc "A key accepted in a proof request. Unrecognized keys are ignored."
  @type proof_request_opt ::
          {:subject, Subject.subject_descriptor() | nil}
          | {:subject_ref, Evidence.subject_ref() | nil}
          | {:mode, :latest | :history}
          | {:from, DateTime.t()}
          | {:to, DateTime.t()}
          | {:limit, pos_integer()}

  @typedoc "A keyword list selecting the evidence included in a proof document."
  @type proof_request :: [proof_request_opt()]

  @typedoc "A supported proof read mode."
  @type proof_mode :: :latest | :history

  @typedoc "A filter accepted by a proof read."
  @type proof_filter :: {:from, DateTime.t()} | {:to, DateTime.t()} | {:limit, pos_integer()}

  @typedoc "An option accepted by proof document reads."
  @type proof_opt :: Threadline.repo_opt() | {:generated_at, DateTime.t()}

  @typedoc "A proof status string: `proven`, `inferred_posture`, or `unsupported`."
  @type claim_status :: String.t()

  @typedoc "A proof category string: `direct_fact`, `posture_snapshot`, or `unsupported_claim`."
  @type claim_kind :: String.t()

  @typedoc "A JSON-ready proof document with guaranteed keys `format_version`, `generated_at`, `proof_type`, `subject`, `mode`, `filters`, `summary`, `claim_assessment`, and `records`; new JSON keys may be added."
  @type proof_document :: Threadline.json_map()

  @typedoc "An evidence row supplied to a proof projection."
  @type evidence_record_input :: EvidenceRecord.t() | Threadline.json_map()

  @typedoc "A row formatted for the evidence viewer."
  @type presented_record :: %{
          subject: Threadline.json_value(),
          subject_ref: Threadline.json_value(),
          summary_status: Threadline.json_value(),
          recorded_at: String.t() | nil,
          verdict_status: claim_status(),
          verdict_kind: claim_kind(),
          verdict_reason: Threadline.json_value()
        }

  @doc """
  Builds a JSON-ready proof document from matching evidence snapshots and their claim assessment.

  Use `to_json_iodata/2` when the encoded JSON is the desired output. The
  request selects an overview or one subject, a latest or history read, and
  optional date bounds and limit. Unrecognized request keys are ignored.

  ## Request

  - `:subject` — supported subject name or descriptor. Optional; omission selects the overview.
  - `:subject_ref` — subject reference map. Optional.
  - `:mode` — `:latest` or `:history`. Optional; defaults to `:latest`.
  - `:from` — `DateTime`. Optional; inclusive lower bound on the record time.
  - `:to` — `DateTime`. Optional; inclusive upper bound on the record time.
  - `:limit` — positive integer. Optional; caps the matching records.

  ## Options

  - `:repo` — Ecto repository module. Required.
  - `:generated_at` — `DateTime`. Optional; defaults to the current UTC time.

  ## Returns

  Returns a string-keyed JSON map containing the format version, generation
  time, selected subject and mode, filters, record counts, claim assessment,
  and matching records. Raises `KeyError` when `:repo` is omitted and
  `ArgumentError` for an unsupported subject, invalid subject reference, or
  invalid Evidence filter.
  """
  @spec proof_document(proof_request(), [proof_opt()]) :: proof_document()
  def proof_document(request, opts) when is_list(request) and is_list(opts) do
    repo = repo_option(opts)
    generated_at = Keyword.get(opts, :generated_at, DateTime.utc_now(:microsecond))

    subject = request_subject(request)
    subject_ref = request_subject_ref(request)
    mode = Keyword.get(request, :mode, :latest)
    filters = request_filters(request)
    records = fetch_records(subject, subject_ref, mode, filters, repo)

    %{
      "format_version" => @format_version,
      "generated_at" => iso8601(generated_at),
      "proof_type" => @proof_type,
      "subject" => subject_label(subject),
      "mode" => Atom.to_string(mode),
      "filters" => json_filters(subject_ref, filters),
      "summary" => %{
        "record_count" => length(records),
        "subject_count" => records |> Enum.map(& &1.subject) |> Enum.uniq() |> length()
      },
      "claim_assessment" => claim_assessment(records),
      "records" => Enum.map(records, &record_to_map/1)
    }
  end

  @doc """
  Encodes matching evidence snapshots and their claim assessment as `{:ok, iodata}`.

  Use `proof_document/2` when the JSON-ready map is needed instead of encoded
  output. The request and options have the same meaning as that function;
  unrecognized request keys are ignored.

  ## Request

  - `:subject` — supported subject name or descriptor. Optional; omission selects the overview.
  - `:subject_ref` — subject reference map. Optional.
  - `:mode` — `:latest` or `:history`. Optional; defaults to `:latest`.
  - `:from` — `DateTime`. Optional; inclusive lower bound on the record time.
  - `:to` — `DateTime`. Optional; inclusive upper bound on the record time.
  - `:limit` — positive integer. Optional; caps the matching records.

  ## Options

  - `:repo` — Ecto repository module. Required.
  - `:generated_at` — `DateTime`. Optional; defaults to the current UTC time.

  ## Returns

  Returns `{:ok, iodata()}` containing the encoded proof document. Raises
  `KeyError` when `:repo` is omitted and `ArgumentError` for an unsupported
  subject, invalid subject reference, or invalid Evidence filter.
  """
  @spec to_json_iodata(proof_request(), [proof_opt()]) :: {:ok, iodata()}
  def to_json_iodata(request, opts) when is_list(request) and is_list(opts) do
    {:ok, Jason.encode!(proof_document(request, opts))}
  end

  @doc """
  Prints a JSON-ready proof document to standard output and returns `:ok`.
  """
  @spec render_json(proof_document()) :: :ok
  def render_json(document) when is_map(document) do
    IO.puts(Jason.encode!(document))
  end

  @doc """
  Prints a JSON-ready proof document in human-readable form through the Mix shell and returns `:ok`.
  """
  @spec render_human(proof_document()) :: :ok
  def render_human(document) when is_map(document) do
    Mix.shell().info("Evidence proof #{document["subject"]}")
    Mix.shell().info("Mode: #{document["mode"]}")
    Mix.shell().info("Claim assessment: #{document["claim_assessment"]["status"]}")
    Mix.shell().info("Records: #{document["summary"]["record_count"]}")

    Enum.each(document["records"], fn record ->
      presented = present_record(record)

      Mix.shell().info(
        "* #{presented.subject} #{inspect(presented.subject_ref)} #{presented.verdict_status} #{presented.recorded_at}"
      )
    end)
  end

  @doc false
  @spec present_record(evidence_record_input()) :: presented_record()
  def present_record(record) when is_map(record) do
    verdict = record_claim_assessment(record)

    %{
      subject: Map.get(record, "subject") || Map.get(record, :subject),
      subject_ref: Map.get(record, "subject_ref") || Map.get(record, :subject_ref),
      summary_status: Map.get(record, "summary_status") || Map.get(record, :summary_status),
      recorded_at:
        rendered_recorded_at(Map.get(record, "recorded_at") || Map.get(record, :recorded_at)),
      verdict_status: verdict["status"],
      verdict_kind: verdict["kind"],
      verdict_reason: verdict["reason"]
    }
  end

  @doc false
  @spec record_claim_assessment(evidence_record_input()) :: Threadline.json_map()
  def record_claim_assessment(record) when is_map(record) do
    record_verdict(record)
  end

  @spec request_subject(proof_request()) :: Subject.subject_descriptor() | nil
  defp request_subject([]), do: nil
  defp request_subject([{:subject, subject} | _rest]), do: subject
  defp request_subject([_entry | rest]), do: request_subject(rest)

  @spec request_subject_ref(proof_request()) ::
          Evidence.subject_ref() | Evidence.subject_ref_value() | nil
  defp request_subject_ref([]), do: nil
  defp request_subject_ref([{:subject_ref, subject_ref} | _rest]), do: subject_ref
  defp request_subject_ref([_entry | rest]), do: request_subject_ref(rest)

  @spec request_filters(proof_request()) :: [proof_filter()]
  defp request_filters(request) do
    request
    |> Keyword.take([:from, :to, :limit])
  end

  @spec repo_option([proof_opt()]) :: module()
  defp repo_option(opts) do
    case Keyword.fetch!(opts, :repo) do
      repo when is_atom(repo) -> repo
      other -> raise ArgumentError, "expected :repo to be a module, got: #{inspect(other)}"
    end
  end

  @spec subject_label(Subject.subject_descriptor() | nil) :: Threadline.json_value()
  defp subject_label(nil), do: "overview"
  defp subject_label(subject), do: subject

  @spec fetch_records(
          Subject.subject_descriptor() | nil,
          Evidence.subject_ref() | nil,
          proof_mode(),
          [proof_filter()],
          module()
        ) :: [EvidenceRecord.t()]
  defp fetch_records(nil, nil, :latest, filters, repo),
    do: Evidence.list_overview(filters, repo: repo)

  defp fetch_records(subject, nil, :latest, filters, repo) do
    Evidence.list_latest_subject_refs(subject, filters, repo: repo)
  end

  defp fetch_records(subject, subject_ref, :latest, _filters, repo) do
    case Evidence.get_latest_subject_ref(subject, subject_ref, repo: repo) do
      nil -> []
      record -> [record]
    end
  end

  defp fetch_records(subject, subject_ref, :history, filters, repo)
       when not is_nil(subject_ref) do
    Evidence.list_subject_ref_history(subject, subject_ref, filters, repo: repo)
  end

  defp fetch_records(subject, _subject_ref, :history, filters, repo) when not is_nil(subject) do
    Evidence.list_history(Keyword.put(filters, :subject, subject), repo: repo)
  end

  defp fetch_records(nil, _subject_ref, :history, filters, repo) do
    Evidence.list_history(filters, repo: repo)
  end

  defp claim_assessment([]) do
    %{
      "status" => "unsupported",
      "kind" => "unsupported_claim",
      "reason" => "no_records",
      "error_statuses" => @error_statuses
    }
  end

  defp claim_assessment(records) do
    verdicts = Enum.map(records, &record_claim_assessment/1)
    statuses = Enum.uniq(Enum.map(records, & &1.summary_status))
    winning_verdict = choose_verdict(verdicts)

    %{
      "status" => winning_verdict["status"],
      "kind" => winning_verdict["kind"],
      "reason" => winning_verdict["reason"],
      "record_statuses" => statuses,
      "error_statuses" => @error_statuses
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp record_verdict(record) do
    detail = Map.get(record, :detail) || Map.get(record, "detail")
    subject = Map.get(record, :subject) || Map.get(record, "subject")

    case explicit_claim_assessment(detail) do
      %{"status" => status} = verdict when status in @semantic_statuses ->
        verdict

      _other ->
        subject_verdict(subject)
    end
  end

  defp explicit_claim_assessment(detail) when is_map(detail) do
    case get_in(detail, ["claim_assessment", "status"]) do
      "unsupported" ->
        %{
          "status" => "unsupported",
          "kind" => "unsupported_claim",
          "reason" => get_in(detail, ["claim_assessment", "reason"])
        }

      "inferred_posture" ->
        %{
          "status" => "inferred_posture",
          "kind" => "posture_snapshot",
          "reason" => get_in(detail, ["claim_assessment", "reason"])
        }

      "proven" ->
        %{
          "status" => "proven",
          "kind" => "direct_fact",
          "reason" => get_in(detail, ["claim_assessment", "reason"])
        }

      _other ->
        nil
    end
  end

  defp explicit_claim_assessment(_detail), do: nil

  defp subject_verdict(subject) when subject in @posture_subjects do
    %{
      "status" => "inferred_posture",
      "kind" => "posture_snapshot"
    }
  end

  defp subject_verdict(_subject) do
    %{
      "status" => "proven",
      "kind" => "direct_fact"
    }
  end

  defp choose_verdict(verdicts) do
    Enum.find(verdicts, &(&1["status"] == "unsupported")) ||
      Enum.find(verdicts, &(&1["status"] == "inferred_posture")) ||
      hd(verdicts)
  end

  @spec json_filters(Evidence.subject_ref() | nil, [proof_filter()]) :: Threadline.json_map()
  defp json_filters(subject_ref, filters) do
    filters
    |> Enum.into(%{}, fn {key, value} -> {Atom.to_string(key), filter_value(value)} end)
    |> maybe_put_subject_ref(subject_ref)
  end

  defp maybe_put_subject_ref(filters, nil), do: filters

  defp maybe_put_subject_ref(filters, subject_ref),
    do: Map.put(filters, "subject_ref", subject_ref)

  defp filter_value(%DateTime{} = value), do: iso8601(value)
  defp filter_value(value), do: value

  defp record_to_map(record) do
    %{
      "id" => record.id,
      "subject" => record.subject,
      "subject_ref" => record.subject_ref,
      "summary_status" => record.summary_status,
      "recorded_at" => iso8601(record.recorded_at),
      "actor_ref" => actor_ref_to_map(record.actor_ref),
      "provenance" => record.provenance,
      "detail" => record.detail,
      "schema_version" => record.schema_version,
      "inserted_at" => iso8601(record.inserted_at)
    }
  end

  defp actor_ref_to_map(nil), do: nil
  defp actor_ref_to_map(actor_ref), do: ActorRef.to_map(actor_ref)

  defp rendered_recorded_at(%DateTime{} = datetime), do: iso8601(datetime)
  defp rendered_recorded_at(value) when is_binary(value), do: value
  defp rendered_recorded_at(_value), do: nil

  defp iso8601(nil), do: nil
  defp iso8601(%DateTime{} = datetime), do: DateTime.to_iso8601(datetime)
end
