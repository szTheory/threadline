defmodule Threadline.Evidence.Proof do
  @moduledoc """
  Reusable proof projection for Threadline evidence viewer surfaces.
  """

  alias Threadline.Evidence

  @format_version 1
  @proof_type "threadline_evidence"
  @semantic_statuses ~w(proven inferred_posture unsupported)
  @error_statuses ~w(invalid_request runtime_failure)
  @posture_subjects ~w(redaction_policy retention_policy support_scope_posture)

  @doc """
  Builds the wrapped proof document for overview, latest, or history reads.
  """
  def proof_document(request, opts) when is_list(request) and is_list(opts) do
    repo = Keyword.fetch!(opts, :repo)
    generated_at = Keyword.get(opts, :generated_at, DateTime.utc_now(:microsecond))

    subject = request_subject(request)
    subject_ref = Keyword.get(request, :subject_ref)
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
  Encodes a proof document as JSON iodata.
  """
  def to_json_iodata(request, opts) when is_list(request) and is_list(opts) do
    {:ok, Jason.encode!(proof_document(request, opts))}
  end

  @doc """
  Prints a proof document as JSON.
  """
  def render_json(document) when is_map(document) do
    IO.puts(Jason.encode!(document))
  end

  @doc """
  Prints a proof document in human-readable form.
  """
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

  def record_claim_assessment(record) when is_map(record) do
    record_verdict(record)
  end

  defp request_subject(request), do: Keyword.get(request, :subject)

  defp request_filters(request) do
    request
    |> Keyword.take([:from, :to, :limit])
  end

  defp subject_label(nil), do: "overview"
  defp subject_label(subject), do: subject

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
  defp actor_ref_to_map(actor_ref), do: Threadline.Semantics.ActorRef.to_map(actor_ref)

  defp rendered_recorded_at(%DateTime{} = datetime), do: iso8601(datetime)
  defp rendered_recorded_at(value) when is_binary(value), do: value
  defp rendered_recorded_at(_value), do: nil

  defp iso8601(nil), do: nil
  defp iso8601(%DateTime{} = datetime), do: DateTime.to_iso8601(datetime)
end
