defmodule Threadline.ExportQueue.ObanTest do
  use ExUnit.Case, async: true

  defmodule MockOban do
    def insert(Oban, %Ecto.Changeset{changes: %{args: %{job_id: "job_123"}, worker: "Threadline.ExportQueue.ObanWorker"}}) do
      {:ok, :mocked_job}
    end
  end

  describe "init/1" do
    test "returns :ok when Oban is loaded" do
      assert Threadline.ExportQueue.Oban.init([]) == :ok
    end
  end

  describe "enqueue/2" do
    test "enqueues a job via Oban" do
      assert :ok = Threadline.ExportQueue.Oban.enqueue("job_123", oban_mod: MockOban)
    end
  end
end
