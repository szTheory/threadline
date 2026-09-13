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

  describe "file-id validation" do
    test "all filesystem operations reject traversal, absolute, separator, control, and extension escapes" do
      outside = Path.join(System.tmp_dir!(), "threadline-outside-#{System.unique_integer()}.csv")
      File.write!(outside, "outside")
      on_exit(fn -> File.rm(outside) end)

      invalid_ids = [
        "../../#{Path.basename(outside)}",
        outside,
        "nested/export.csv",
        "nested\\export.csv",
        "bad\nname.csv",
        ".",
        "..",
        "export.txt"
      ]

      for file_id <- invalid_ids do
        assert {:error, :invalid_file_id} = Local.put("malicious", file_id: file_id)
        assert {:error, :invalid_file_id} = Local.get(file_id)
        assert {:error, :invalid_file_id} = Local.path(file_id)
        assert {:error, :invalid_file_id} = Local.delete(file_id)
      end

      assert File.read!(outside) == "outside"
    end

    test "rejects an existing symlink without reading or deleting its target" do
      assert {:ok, safe_id} = Local.put("safe")
      assert {:ok, safe_path} = Local.path(safe_id)

      target =
        Path.join(System.tmp_dir!(), "threadline-symlink-target-#{System.unique_integer()}.csv")

      File.write!(target, "secret")
      link = Path.join(Path.dirname(safe_path), "escaped.csv")
      File.ln_s!(target, link)

      on_exit(fn ->
        File.rm(link)
        File.rm(target)
      end)

      assert {:error, :unsafe_path} = Local.put("overwrite", file_id: "escaped.csv")
      assert {:error, :unsafe_path} = Local.get("escaped.csv")
      assert {:error, :unsafe_path} = Local.path("escaped.csv")
      assert {:error, :unsafe_path} = Local.delete("escaped.csv")
      assert File.read!(target) == "secret"
    end
  end
end
