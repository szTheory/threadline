defmodule Threadline.ExportQueue.ObanTest do
  use ExUnit.Case, async: true

  defmodule MockOban do
    def insert(:threadline_oban, %Ecto.Changeset{} = job) do
      send(self(), {:oban_insert, job})
      {:ok, :mocked_job}
    end

    def insert(_oban_name, _job), do: {:error, :queue_paused}
  end

  defmodule BrokenWorker do
    def perform(_job), do: :ok
  end

  describe "init/1" do
    test "returns :ok when Oban is loaded" do
      assert Threadline.ExportQueue.Oban.init(oban_name: Oban, queue: :threadline_exports) == :ok
    end

    test "rejects invalid configured targeting" do
      assert {:error, "Oban adapter expects :oban_name to be an atom"} =
               Threadline.ExportQueue.Oban.init(oban_name: "Oban")

      assert {:error, "Oban adapter expects :queue to be an atom"} =
               Threadline.ExportQueue.Oban.init(queue: "threadline_exports")

      assert {:error, "Oban adapter expects :worker_mod to export new/2"} =
               Threadline.ExportQueue.Oban.init(worker_mod: BrokenWorker)
    end
  end

  describe "enqueue/2" do
    test "enqueues a job via Oban" do
      assert :ok =
               Threadline.ExportQueue.Oban.enqueue("job_123",
                 oban_mod: MockOban,
                 oban_name: :threadline_oban,
                 queue: :exports,
                 storage_schema: "audit"
               )

      assert_received {:oban_insert, %Ecto.Changeset{changes: %{args: args}}}
      assert args.job_id == "job_123"
      assert args.storage_schema == "audit"
    end

    test "normalizes enqueue failures into stable messages" do
      assert {:error, "Oban enqueue failed: queue_paused"} =
               Threadline.ExportQueue.Oban.enqueue("job_123",
                 oban_mod: MockOban,
                 oban_name: :other_oban,
                 queue: :exports,
                 worker_mod: Threadline.ExportQueue.ObanWorker
               )
    end
  end
end
