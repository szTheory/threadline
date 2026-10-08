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

    test "distinguishes present non-map actor refs from a missing key" do
      for actor_ref <- [nil, "not-a-map", 42, false, []] do
        assert {:error, :invalid_actor_ref_map} =
                 Threadline.Job.actor_ref_from_args(%{"actor_ref" => actor_ref})
      end

      for args <- [nil, "not-an-args-map", []] do
        assert {:error, :missing_actor_ref} = Threadline.Job.actor_ref_from_args(args)
      end
    end

    test "preserves specific errors when actor_ref is a malformed map" do
      assert {:error, :invalid_actor_ref_map} =
               Threadline.Job.actor_ref_from_args(%{
                 "actor_ref" => %{:type => "user", "id" => "u-1"}
               })

      assert {:error, :missing_actor_id} =
               Threadline.Job.actor_ref_from_args(%{"actor_ref" => %{"type" => "user"}})

      assert {:error, :unknown_actor_type} =
               Threadline.Job.actor_ref_from_args(%{
                 "actor_ref" => %{"type" => "unknown", "id" => "u-1"}
               })
    end
  end

  describe "context_opts/2" do
    test "extracts correlation_id and job_id from args" do
      args = %{"correlation_id" => "corr-1", "job_id" => "job-42"}
      opts = Threadline.Job.context_opts(args)

      assert opts[:correlation_id] == "corr-1"
      assert opts[:job_id] == "job-42"
    end

    test "normalizes integer job and correlation IDs from Oban args" do
      assert Threadline.Job.context_opts(%{"correlation_id" => 42, "job_id" => 123}) ==
               [correlation_id: "42", job_id: "123"]
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
      opts = Threadline.Job.context_opts(args, job_id: 123, correlation_id: 42)

      assert opts[:job_id] == "123"
      assert opts[:correlation_id] == "42"
    end

    test "preserves nil and string IDs while rejecting malformed IDs and extras" do
      assert Threadline.Job.context_opts(%{"job_id" => nil, "correlation_id" => "corr"}) ==
               [correlation_id: "corr", job_id: nil]

      for bad_id <- [true, 1.5, %{}, []] do
        assert_raise ArgumentError, fn ->
          Threadline.Job.context_opts(%{"job_id" => bad_id})
        end

        assert_raise ArgumentError, fn ->
          Threadline.Job.context_opts(%{}, job_id: bad_id)
        end
      end

      assert_raise ArgumentError, fn -> Threadline.Job.context_opts(%{}, tenant_id: "tenant") end
      assert_raise ArgumentError, fn -> Threadline.Job.context_opts(%{}, [:repo]) end
    end

    test "compiled types describe supported IDs without a generic escape hatch" do
      {:ok, types} = Code.Typespec.fetch_types(Threadline.Job)

      type_text =
        Enum.map_join(types, " ", fn {_, type} ->
          Macro.to_string(Code.Typespec.type_to_quoted(type))
        end)

      {:ok, specs} = Code.Typespec.fetch_specs(Threadline.Job)

      context_spec =
        Enum.find_value(specs, fn
          {{:context_opts, 2}, [spec]} ->
            Code.Typespec.spec_to_quoted(:context_opts, spec) |> Macro.to_string()

          _ ->
            nil
        end)

      assert type_text =~ "context_opt"
      assert type_text =~ "integer()"
      refute type_text =~ "any()"
      refute type_text =~ "term()"
      assert context_spec =~ "context_opts_result"
      refute context_spec =~ "any()"
      refute context_spec =~ "term()"
    end

    test "compiled docs describe conversion, supported extras, and errors" do
      doc = function_doc_text(:context_opts, 2)
      assert doc =~ "integer"
      assert doc =~ "ArgumentError"
      assert doc =~ "Unsupported"
      refute doc =~ "ignored by `record_action/2`"
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
