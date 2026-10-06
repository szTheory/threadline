defmodule Threadline.JobTest do
  use ExUnit.Case, async: true

  alias Threadline.Semantics.ActorRef

  describe "actor_ref_from_args/1" do
    test "extracts ActorRef from valid args map" do
      {:ok, ref} = ActorRef.new(:user, "u-1")
      args = %{"actor_ref" => ActorRef.to_map(ref)}

      assert {:ok, ^ref} = Threadline.Job.actor_ref_from_args(args)
    end

    test "extracts anonymous ActorRef" do
      {:ok, anon} = ActorRef.new(:anonymous)
      args = %{"actor_ref" => ActorRef.to_map(anon)}

      assert {:ok, ^anon} = Threadline.Job.actor_ref_from_args(args)
    end

    test "returns error when actor_ref key is absent" do
      assert {:error, :missing_actor_ref} =
               Threadline.Job.actor_ref_from_args(%{"resource_id" => "123"})
    end

    test "returns error for empty args map" do
      assert {:error, :missing_actor_ref} = Threadline.Job.actor_ref_from_args(%{})
    end
  end

  describe "context_opts/2" do
    test "extracts correlation_id and job_id from args" do
      args = %{"correlation_id" => "corr-1", "job_id" => "job-42"}
      opts = Threadline.Job.context_opts(args)

      assert opts[:correlation_id] == "corr-1"
      assert opts[:job_id] == "job-42"
    end

    test "returns nil values when keys are absent" do
      opts = Threadline.Job.context_opts(%{})

      assert opts[:correlation_id] == nil
      assert opts[:job_id] == nil
    end

    test "merges extra opts" do
      opts = Threadline.Job.context_opts(%{}, request_id: "req-xyz")

      assert opts[:request_id] == "req-xyz"
    end

    test "extra opts override base opts" do
      args = %{"job_id" => "from-args"}
      opts = Threadline.Job.context_opts(args, job_id: "override", tenant_id: "tenant-1")

      assert opts[:job_id] == "override"
      assert opts[:tenant_id] == "tenant-1"
    end

    test "compiled docs describe pass-through and ignored unknown keys" do
      assert function_doc_text(:context_opts, 2) =~ "retained"
      assert function_doc_text(:context_opts, 2) =~ "ignored"
      refute function_doc_text(:context_opts, 2) =~ "validated by `record_action/2`"
    end
  end

  defp function_doc_text(name, arity) do
    {:docs_v1, _, _, _, _, _, docs} = Code.fetch_docs(Threadline.Job)

    Enum.find_value(docs, "", fn
      {{:function, ^name, ^arity}, _, _, %{"en" => text}, _} -> text
      _ -> false
    end)
  end

  describe "CTX-05: no process state" do
    test "actor_ref_from_args/1 is a pure function (no side effects)" do
      {:ok, ref} = ActorRef.new(:admin, "a-1")
      args = %{"actor_ref" => ActorRef.to_map(ref)}

      assert {:ok, ^ref} = Threadline.Job.actor_ref_from_args(args)
      assert {:ok, ^ref} = Threadline.Job.actor_ref_from_args(args)
    end
  end
end
