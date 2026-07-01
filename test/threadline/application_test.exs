defmodule Threadline.ApplicationTest do
  use ExUnit.Case, async: false

  defmodule StorageInitStub do
    @behaviour Threadline.Storage

    @impl true
    def init(opts) do
      if pid = Keyword.get(opts, :notify_pid) do
        send(pid, {:storage_init, opts})
      end

      Keyword.get(opts, :result, :ok)
    end

    @impl true
    def put(_content, _opts), do: {:error, :unsupported}

    @impl true
    def get(_file_id), do: {:error, :unsupported}

    @impl true
    def path(_file_id), do: {:error, :not_local}

    @impl true
    def download_url(_file_id, _opts), do: {:error, :unsupported}

    @impl true
    def delete(_file_id), do: :ok
  end

  defmodule QueueInitStub do
    @behaviour Threadline.ExportQueue

    @impl true
    def init(opts) do
      if pid = Keyword.get(opts, :notify_pid) do
        send(pid, {:queue_init, opts})
      end

      Keyword.get(opts, :result, :ok)
    end

    @impl true
    def enqueue(_job_id, _opts \\ []), do: :ok
  end

  setup do
    previous_storage_adapter = Application.get_env(:threadline, :storage_adapter)
    previous_queue_adapter = Application.get_env(:threadline, :export_queue_adapter)
    previous_storage_opts = Application.get_env(:threadline, StorageInitStub)
    previous_queue_opts = Application.get_env(:threadline, QueueInitStub)

    on_exit(fn ->
      restore_env(:storage_adapter, previous_storage_adapter)
      restore_env(:export_queue_adapter, previous_queue_adapter)
      restore_module_env(StorageInitStub, previous_storage_opts)
      restore_module_env(QueueInitStub, previous_queue_opts)
    end)

    :ok
  end

  test "validates configured adapters at startup when a repo exists" do
    Application.put_env(:threadline, :storage_adapter, StorageInitStub)
    Application.put_env(:threadline, :export_queue_adapter, QueueInitStub)
    Application.put_env(:threadline, StorageInitStub, notify_pid: self())
    Application.put_env(:threadline, QueueInitStub, notify_pid: self())

    parent = self()

    spawn(fn ->
      Process.flag(:trap_exit, true)

      send(
        parent,
        {:start_result,
         Threadline.Application.start(
           :normal,
           name: :"threadline-app-test-#{System.unique_integer()}"
         )}
      )
    end)

    assert_receive {:storage_init, storage_opts}
    assert_receive {:queue_init, queue_opts}
    assert_receive {:start_result, result}
    assert match?({:ok, _}, result) or match?({:error, _}, result)
    assert storage_opts[:notify_pid] == self()
    assert queue_opts[:notify_pid] == self()
  end

  test "surfaces actionable startup errors for adapter init failures" do
    Application.put_env(:threadline, :storage_adapter, StorageInitStub)

    Application.put_env(:threadline, StorageInitStub,
      notify_pid: self(),
      result: {:error, "S3 adapter requires a non-empty :bucket configuration"}
    )

    assert {:error, {:storage_adapter, "S3 adapter requires a non-empty :bucket configuration"}} =
             Threadline.Application.start(
               :normal,
               name: :"threadline-app-failure-#{System.unique_integer()}"
             )
  end

  defp restore_env(key, nil), do: Application.delete_env(:threadline, key)
  defp restore_env(key, value), do: Application.put_env(:threadline, key, value)

  defp restore_module_env(module, nil), do: Application.delete_env(:threadline, module)
  defp restore_module_env(module, value), do: Application.put_env(:threadline, module, value)
end
