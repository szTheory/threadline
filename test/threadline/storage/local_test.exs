defmodule Threadline.Storage.LocalTest do
  use ExUnit.Case, async: true
  alias Threadline.Storage.Local

  @test_priv "priv/threadline_exports"

  setup do
    # Ensure test directory is clean
    if File.exists?(@test_priv) do
      File.rm_rf!(@test_priv)
    end
    :ok
  end

  describe "put/2" do
    test "writes raw string content" do
      assert {:ok, file_id} = Local.put("raw,csv,content\n1,2,3")
      assert {:ok, "raw,csv,content\n1,2,3"} = Local.get(file_id)
    end

    test "copies file when content is an existing file path" do
      temp_file = Path.join(System.tmp_dir!(), "temp_export_#{System.unique_integer()}.csv")
      File.write!(temp_file, "file,based,content\n4,5,6")

      assert {:ok, file_id} = Local.put(temp_file)
      assert {:ok, "file,based,content\n4,5,6"} = Local.get(file_id)

      File.rm!(temp_file)
    end
  end

  describe "path/1" do
    test "returns absolute path for existing file_id" do
      assert {:ok, file_id} = Local.put("test")
      assert {:ok, path} = Local.path(file_id)
      assert is_binary(path)
      assert String.ends_with?(path, file_id)
      assert File.exists?(path)
    end
  end
end
