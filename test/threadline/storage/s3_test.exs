defmodule Threadline.Storage.S3Test do
  use ExUnit.Case, async: true

  defmodule MockExAwsS3 do
    def put_object("test-bucket", file_id, "csv,content") do
      send(self(), {:put_object, file_id, "csv,content"})
      # Simplified return
      %{op: :put_object}
    end

    def get_object("test-bucket", file_id) do
      send(self(), {:get_object, file_id})
      %{op: :get_object}
    end

    def delete_object("test-bucket", file_id) do
      send(self(), {:delete_object, file_id})
      %{op: :delete_object}
    end

    def presigned_url(ExAws.Config, :get, "test-bucket", file_id, opts) do
      send(self(), {:presigned_url, file_id, opts})
      {:ok, "https://s3.example.com/test-bucket/#{file_id}?signed=true"}
    end

    def presigned_url(ExAws.Config, :get, "broken-bucket", _file_id, _opts) do
      {:error, :signature_failure}
    end
  end

  defmodule MockExAws do
    def request(%{op: :put_object}) do
      {:ok, %{status_code: 200}}
    end

    def request(%{op: :get_object}) do
      {:ok, %{body: "csv,content"}}
    end

    def request(%{op: :delete_object}) do
      {:ok, %{status_code: 204}}
    end
  end

  describe "init/1" do
    test "returns :ok when ExAws.S3 is loaded" do
      assert :ok = Threadline.Storage.S3.init(bucket: "test-bucket")
    end

    test "returns an actionable error when bucket config is missing" do
      assert {:error, "S3 adapter requires a non-empty :bucket configuration"} =
               Threadline.Storage.S3.init([])
    end
  end

  describe "put/2" do
    test "pushes content to S3" do
      assert {:ok, file_id} =
               Threadline.Storage.S3.put("csv,content",
                 bucket: "test-bucket",
                 ex_aws_mod: MockExAws,
                 ex_aws_s3_mod: MockExAwsS3,
                 file_id: "test.csv"
               )

      assert file_id == "test.csv"
      assert_received {:put_object, "test.csv", "csv,content"}
    end
  end

  describe "get/1" do
    test "gets content from S3" do
      Application.put_env(:threadline, Threadline.Storage.S3, bucket: "test-bucket")

      assert {:ok, "csv,content"} =
               Threadline.Storage.S3.get("test.csv",
                 ex_aws_mod: MockExAws,
                 ex_aws_s3_mod: MockExAwsS3
               )

      assert_received {:get_object, "test.csv"}
    end
  end

  describe "path/1" do
    test "returns :not_local error" do
      assert Threadline.Storage.S3.path("test.csv") == {:error, :not_local}
    end
  end

  describe "download_url/2" do
    test "returns a presigned URL" do
      assert {:ok, url} =
               Threadline.Storage.S3.download_url("test.csv",
                 bucket: "test-bucket",
                 ex_aws_s3_mod: MockExAwsS3
               )

      assert url == "https://s3.example.com/test-bucket/test.csv?signed=true"
      assert_received {:presigned_url, "test.csv", opts}
      assert Keyword.get(opts, :expires_in) == 900
    end

    test "returns a stable error when presigning fails" do
      assert {:error, "S3 download URL generation failed: :signature_failure"} =
               Threadline.Storage.S3.download_url("test.csv",
                 bucket: "broken-bucket",
                 ex_aws_s3_mod: MockExAwsS3
               )
    end
  end

  describe "delete/1" do
    test "deletes an object from S3" do
      Application.put_env(:threadline, Threadline.Storage.S3, bucket: "test-bucket")

      assert :ok =
               Threadline.Storage.S3.delete("test.csv",
                 ex_aws_mod: MockExAws,
                 ex_aws_s3_mod: MockExAwsS3
               )

      assert_received {:delete_object, "test.csv"}
    end
  end
end
