defmodule ThreadlinePhoenix.Workers.PostTouchWorker do
  @moduledoc false

  use Oban.Worker, queue: :threadline_audit

  @impl Oban.Worker
  def perform(%Oban.Job{} = job) do
    args = Map.put(job.args, "job_id", to_string(job.id))

    attrs = %{
      "post_id" => Map.fetch!(job.args, "post_id"),
      "title" => Map.fetch!(job.args, "title")
    }

    case ThreadlinePhoenix.Blog.touch_post_for_job(args, attrs) do
      {:ok, _post} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
end
