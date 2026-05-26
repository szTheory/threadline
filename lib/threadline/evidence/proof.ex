defmodule Threadline.Evidence.Proof do
  @moduledoc """
  Reusable proof projection for Threadline evidence viewer surfaces.
  """

  alias Threadline.Evidence

  @format_version 1
  @proof_type "threadline_evidence"

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
    Mix.shell().info("Evidence proof overview")
    Mix.shell().info("Mode: #{document["mode"]}")
    Mix.shell().info("Claim assessment: #{document["claim_assessment"]["status"]}")
    Mix.shell().info("Records: #{document["summary"]["record_count"]}")

    Enum.each(document["records"], fn record ->
      Mix.shell().info(
        "* #{record["subject"]} #{inspect(record["subject_ref"])} #{record["summary_status"]} #{record["recorded_at"]}"
      )
    end)
  end

  defp request_subject(request), do: Keyword.get(request, :subject)

  defp request_filters(request) do
    request
    |> Keyword.take([:from, :to, :limit])
  end

  defp subject_label(nil), do: "overview"
  defp subject_label(subject), do: subject

  defp fetch_records(nil, nil, :latest, filters, repo), do: Evidence.list_overview(filters, repo: repo)

  defp fetch_records(subject, nil, :latest, filters, repo) do
    Evidence.list_latest_subject_refs(subject, filters, repo: repo)
  end

  defp fetch_records(subject, subject_ref, :latest, _filters, repo) do
    case Evidence.get_latest_subject_ref(subject, subject_ref, repo: repo) do
      nil -> []
      record -> [record]
    end
  end

  defp fetch_records(subject, subject_ref, :history, filters, repo) when not is_nil(subject_ref) do
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
      "reason" => "no_records"
    }
  end

  defp claim_assessment(records) do
    statuses =
      records
      |> Enum.map(& &1.summary_status)
      |> Enum.uniq()

    status =
      cond do
        "unsupported" in statuses -> "unsupported"
        "inferred_posture" in statuses -> "inferred_posture"
        true -> "proven"
      end

    %{
      "status" => status,
      "record_statuses" => statuses
    }
  end

  defp json_filters(subject_ref, filters) do
    filters
    |> Enum.into(%{}, fn {key, value} -> {Atom.to_string(key), filter_value(value)} end)
    |> maybe_put_subject_ref(subject_ref)
  end

  defp maybe_put_subject_ref(filters, nil), do: filters
  defp maybe_put_subject_ref(filters, subject_ref), do: Map.put(filters, "subject_ref", subject_ref)

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

  defp iso8601(nil), do: nil
  defp iso8601(%DateTime{} = datetime), do: DateTime.to_iso8601(datetime)
end
