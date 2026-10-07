defmodule Threadline.DeprecationParityTest do
  @moduledoc """
  Pins the exact deprecated-entry-point inventory for `Threadline`,
  `Threadline.Query` and `Threadline.Investigation` (D-11, API-08).

  Every retired name is reached here only through `apply/3` — never a direct
  call — so this file's own compilation never emits a deprecation warning
  and `mix compile --warnings-as-errors` stays clean while still proving
  each deprecated delegate behaves exactly like its replacement over a
  250-change row (so the unbounded 0.12 behavior the delegates preserve is
  actually exercised, not just type-checked).
  """

  use Threadline.DataCase

  alias Threadline.Capture.{AuditChange, AuditTransaction}
  alias Threadline.Semantics.{ActorRef, AuditAction}

  @repo Threadline.Test.Repo

  # Expected exact deprecation inventories (D-11). Pinned here so an added or
  # dropped deprecation on any of the three modules turns these three
  # assertions red immediately, rather than surfacing as a silent gap in
  # coverage elsewhere.
  @threadline_deprecated [
    {{:history, 3}, "Use Threadline.row_history/3 instead."},
    {{:row_history, 4}, "Use Threadline.row_history/3 instead."},
    {{:row_history_page, 2}, "Use Threadline.row_history/3 instead."},
    {{:row_history_page, 3}, "Use Threadline.row_history/3 instead."},
    {{:row_history_page, 4}, "Use Threadline.row_history/3 instead."},
    {{:actor_window_page, 1}, "Use Threadline.actor_window/3 instead."},
    {{:actor_window_page, 2}, "Use Threadline.actor_window/3 instead."},
    {{:actor_window_page, 3}, "Use Threadline.actor_window/3 instead."},
    {{:correlation_bundle_page, 1}, "Use Threadline.correlation_bundle/3 instead."},
    {{:correlation_bundle_page, 2}, "Use Threadline.correlation_bundle/3 instead."},
    {{:correlation_bundle_page, 3}, "Use Threadline.correlation_bundle/3 instead."}
  ]

  @query_deprecated [
    {{:audit_transaction, 2}, "Use Threadline.audit_transaction/2 instead."},
    {{:history, 3}, "Use Threadline.row_history/3 instead."},
    {{:row_history, 2}, "Use Threadline.row_history/3 instead."},
    {{:row_history, 3}, "Use Threadline.row_history/3 instead."},
    {{:row_history, 4}, "Use Threadline.row_history/3 instead."},
    {{:row_history_page, 2}, "Use Threadline.row_history/3 instead."},
    {{:row_history_page, 3}, "Use Threadline.row_history/3 instead."},
    {{:row_history_page, 4}, "Use Threadline.row_history/3 instead."}
  ]

  @investigation_deprecated [
    {{:row_history, 4}, "Use Threadline.row_history/3 instead."},
    {{:row_history_page, 2}, "Use Threadline.row_history/3 instead."},
    {{:row_history_page, 3}, "Use Threadline.row_history/3 instead."},
    {{:row_history_page, 4}, "Use Threadline.row_history/3 instead."},
    {{:actor_window_page, 1}, "Use Threadline.actor_window/3 instead."},
    {{:actor_window_page, 2}, "Use Threadline.actor_window/3 instead."},
    {{:actor_window_page, 3}, "Use Threadline.actor_window/3 instead."},
    {{:correlation_bundle_page, 1}, "Use Threadline.correlation_bundle/3 instead."},
    {{:correlation_bundle_page, 2}, "Use Threadline.correlation_bundle/3 instead."},
    {{:correlation_bundle_page, 3}, "Use Threadline.correlation_bundle/3 instead."}
  ]

  defmodule FakeUser do
    use Ecto.Schema

    @primary_key {:id, :string, autogenerate: false}
    schema "users" do
      field(:name, :string)
    end
  end

  defp insert_transaction(attrs \\ %{}, storage_schema \\ "threadline") do
    defaults = %{txid: System.unique_integer([:positive]), occurred_at: DateTime.utc_now()}

    @repo.insert!(
      AuditTransaction.changeset(Map.merge(defaults, attrs)),
      repo_opts(storage_schema)
    )
  end

  defp insert_change(transaction, attrs, storage_schema \\ "threadline") do
    defaults = %{
      table_schema: "public",
      table_name: "users",
      table_pk: %{"id" => "user-1"},
      op: "insert",
      data_after: %{"name" => "Alice"},
      changed_fields: ["name"],
      captured_at: DateTime.utc_now(),
      transaction_id: transaction.id
    }

    @repo.insert!(
      AuditChange.changeset(Map.merge(defaults, Map.new(attrs))),
      repo_opts(storage_schema)
    )
  end

  # Inserts `n` changes on `table_pk`, each one microsecond apart (strictly
  # increasing `captured_at`, so eager/paged/limited reads all agree on a
  # single unambiguous newest-first order). Returns the inserted changes in
  # insertion (oldest-first) order.
  defp insert_n_changes(txn, table_pk, n, base_time \\ ~U[2026-01-01 00:00:00.000000Z]) do
    for i <- 1..n do
      insert_change(txn, %{
        table_pk: table_pk,
        captured_at: DateTime.add(base_time, i, :microsecond)
      })
    end
  end

  defp actor!(type, id) do
    {:ok, ref} = ActorRef.new(type, id)
    ref
  end

  defp insert_action(attrs, storage_schema \\ "threadline") do
    actor = actor!(:user, "deprecation-parity-investigator")

    defaults = %{
      name: "deprecation_parity.test",
      actor_ref: ActorRef.to_map(actor),
      status: :ok,
      correlation_id: "corr-default"
    }

    @repo.insert!(
      AuditAction.changeset(%AuditAction{}, Map.merge(defaults, attrs)),
      repo_opts(storage_schema)
    )
  end

  # Inserts `n` changes on one actor's transaction, each one microsecond
  # apart, for actor_window/actor_window_page parity.
  defp insert_n_actor_changes(actor_ref, n, base_time \\ ~U[2026-01-01 00:00:00.000000Z]) do
    txn = insert_transaction(%{actor_ref: ActorRef.to_map(actor_ref)})

    for i <- 1..n do
      insert_change(txn, %{
        table_pk: %{"id" => "actor-row-#{i}"},
        captured_at: DateTime.add(base_time, i, :microsecond)
      })
    end
  end

  # Inserts `n` changes linked to one correlation id, each one microsecond
  # apart, for correlation_bundle/correlation_bundle_page parity.
  defp insert_n_correlated_changes(
         correlation_id,
         n,
         base_time \\ ~U[2026-01-01 00:00:00.000000Z]
       ) do
    action = insert_action(%{correlation_id: correlation_id})
    txn = insert_transaction(%{action_id: action.id})

    for i <- 1..n do
      insert_change(txn, %{
        table_pk: %{"id" => "corr-row-#{i}"},
        captured_at: DateTime.add(base_time, i, :microsecond)
      })
    end
  end

  defp page_ids_lc(%Threadline.Page{entries: entries}),
    do: Enum.map(entries, & &1.audit_change.id)

  defp page_ids_ac(%Threadline.Page{entries: entries}), do: Enum.map(entries, & &1.id)

  defp fetch_specs!(mod) do
    {:ok, specs} = Code.Typespec.fetch_specs(mod)
    specs |> Enum.map(fn {{name, arity}, _spec} -> {name, arity} end) |> MapSet.new()
  end

  describe "history/3 (deprecated, D-02, D-04)" do
    test "apply(Threadline, :history, ...) over 250 changes returns 250 AuditChange, ids equal row_history(limit: :infinity)" do
      txn = insert_transaction()
      table_pk = %{"id" => "history-parity"}
      changes = insert_n_changes(txn, table_pk, 250)

      args = [FakeUser, "history-parity", [repo: @repo]]
      results = apply(Threadline, :history, args)

      assert is_list(results)
      assert length(results) == 250
      assert Enum.all?(results, &match?(%AuditChange{}, &1))

      replacement =
        Threadline.row_history(FakeUser, "history-parity", repo: @repo, limit: :infinity)

      assert Enum.map(results, & &1.id) == Enum.map(replacement, & &1.audit_change.id)
      assert Enum.map(results, & &1.id) == changes |> Enum.reverse() |> Enum.map(& &1.id)
    end

    test "apply(Threadline.Query, :history, ...) returns the same ids as the facade's deprecated history/3" do
      txn = insert_transaction()
      table_pk = %{"id" => "history-query-parity"}
      insert_n_changes(txn, table_pk, 250)

      facade_args = [FakeUser, "history-query-parity", [repo: @repo]]
      query_args = [FakeUser, "history-query-parity", [repo: @repo]]

      facade_results = apply(Threadline, :history, facade_args)
      query_results = apply(Threadline.Query, :history, query_args)

      assert Enum.map(query_results, & &1.id) == Enum.map(facade_results, & &1.id)
    end

    test "limit: nil returns all 250 (nil maps to :infinity, D-04)" do
      txn = insert_transaction()
      table_pk = %{"id" => "history-limit-nil"}
      insert_n_changes(txn, table_pk, 250)

      args = [FakeUser, "history-limit-nil", [repo: @repo, limit: nil]]
      results = apply(Threadline, :history, args)

      assert length(results) == 250
    end

    test "limit: 5 returns the newest 5" do
      txn = insert_transaction()
      table_pk = %{"id" => "history-limit-5"}
      changes = insert_n_changes(txn, table_pk, 250)

      args = [FakeUser, "history-limit-5", [repo: @repo, limit: 5]]
      results = apply(Threadline, :history, args)

      assert length(results) == 5
      expected_ids = changes |> Enum.reverse() |> Enum.take(5) |> Enum.map(& &1.id)
      assert Enum.map(results, & &1.id) == expected_ids
    end

    test "limit: 0 raises ArgumentError" do
      args = [FakeUser, "history-limit-zero", [repo: @repo, limit: 0]]

      assert_raise ArgumentError, fn -> apply(Threadline, :history, args) end
    end

    test "Threadline.__info__(:deprecated) names {:history, 3} with the exact message" do
      assert {{:history, 3}, "Use Threadline.row_history/3 instead."} in Threadline.__info__(
               :deprecated
             )
    end
  end

  describe "row_history_page family (deprecated, D-04, D-11)" do
    test "Threadline.row_history_page/4 with no :cursor key returns the same first page as row_history(cursor: :start)" do
      txn = insert_transaction()
      table_pk = %{"id" => "rhp-nocursor"}
      insert_n_changes(txn, table_pk, 250)

      args = [FakeUser, "rhp-nocursor", [], [repo: @repo]]
      page = apply(Threadline, :row_history_page, args)

      expected =
        Threadline.row_history(FakeUser, "rhp-nocursor", repo: @repo, cursor: :start)

      assert page_ids_lc(page) == page_ids_lc(expected)
      assert page.has_more == expected.has_more
    end

    test "Threadline.row_history_page/4 with cursor: nil maps to :start, same first page as cursor: :start" do
      txn = insert_transaction()
      table_pk = %{"id" => "rhp-nilcursor"}
      insert_n_changes(txn, table_pk, 250)

      args = [FakeUser, "rhp-nilcursor", [], [repo: @repo, cursor: nil]]
      page = apply(Threadline, :row_history_page, args)

      expected =
        Threadline.row_history(FakeUser, "rhp-nilcursor", repo: @repo, cursor: :start)

      assert page_ids_lc(page) == page_ids_lc(expected)
    end

    test "walking Threadline.row_history_page/4 two exact-multiple pages equals row_history(limit: :infinity)" do
      txn = insert_transaction()
      table_pk = %{"id" => "rhp-walk"}
      insert_n_changes(txn, table_pk, 250)

      full_ids =
        Threadline.row_history(FakeUser, "rhp-walk", repo: @repo, limit: :infinity)
        |> Enum.map(& &1.audit_change.id)

      page1_args = [FakeUser, "rhp-walk", [], [repo: @repo, page_size: 125]]
      page1 = apply(Threadline, :row_history_page, page1_args)
      assert page1.has_more == true

      page2_args = [
        FakeUser,
        "rhp-walk",
        [],
        [repo: @repo, page_size: 125, cursor: page1.cursor]
      ]

      page2 = apply(Threadline, :row_history_page, page2_args)
      assert page2.has_more == false

      assert page_ids_lc(page1) ++ page_ids_lc(page2) == full_ids
    end

    test "Threadline.Query.row_history/4 returns the same unbounded ids as RowReads/row_history(limit: :infinity)" do
      txn = insert_transaction()
      table_pk = %{"id" => "query-rh"}
      changes = insert_n_changes(txn, table_pk, 250)

      args = [FakeUser, "query-rh", [], [repo: @repo]]
      results = apply(Threadline.Query, :row_history, args)

      assert length(results) == 250
      assert Enum.all?(results, &match?(%AuditChange{}, &1))
      assert Enum.map(results, & &1.id) == changes |> Enum.reverse() |> Enum.map(& &1.id)
    end

    test "Threadline.Query.row_history_page/4 first page equals row_history(cursor: :start) mapped to AuditChange" do
      txn = insert_transaction()
      table_pk = %{"id" => "query-rhp"}
      insert_n_changes(txn, table_pk, 250)

      args = [FakeUser, "query-rhp", [], [repo: @repo, page_size: 60]]
      page = apply(Threadline.Query, :row_history_page, args)

      expected =
        Threadline.row_history(FakeUser, "query-rhp",
          repo: @repo,
          cursor: :start,
          page_size: 60
        )

      assert page_ids_ac(page) == page_ids_lc(expected)
      assert page.has_more == expected.has_more
    end

    test "Threadline.Investigation.row_history_page/4 equals Threadline.row_history_page/4" do
      txn = insert_transaction()
      table_pk = %{"id" => "inv-rhp"}
      insert_n_changes(txn, table_pk, 250)

      facade_args = [FakeUser, "inv-rhp", [], [repo: @repo, page_size: 60]]
      inv_args = [FakeUser, "inv-rhp", [], [repo: @repo, page_size: 60]]

      facade_page = apply(Threadline, :row_history_page, facade_args)
      inv_page = apply(Threadline.Investigation, :row_history_page, inv_args)

      assert page_ids_lc(inv_page) == page_ids_lc(facade_page)
    end
  end

  describe "actor_window_page family (deprecated, D-04, D-11)" do
    test "Threadline.actor_window_page/3 with no :cursor key returns the same first page as actor_window(cursor: :start)" do
      actor = actor!(:user, "dep-actor-nocursor")
      insert_n_actor_changes(actor, 250)

      args = [actor, [], [repo: @repo]]
      page = apply(Threadline, :actor_window_page, args)

      expected = Threadline.actor_window(actor, [], repo: @repo, cursor: :start)

      assert page_ids_lc(page) == page_ids_lc(expected)
      assert page.has_more == expected.has_more
    end

    test "Threadline.actor_window_page/3 with cursor: nil maps to :start" do
      actor = actor!(:user, "dep-actor-nilcursor")
      insert_n_actor_changes(actor, 250)

      args = [actor, [], [repo: @repo, cursor: nil]]
      page = apply(Threadline, :actor_window_page, args)

      expected = Threadline.actor_window(actor, [], repo: @repo, cursor: :start)

      assert page_ids_lc(page) == page_ids_lc(expected)
    end

    test "walking Threadline.actor_window_page/3 two exact-multiple pages equals actor_window with cursor: :start" do
      actor = actor!(:user, "dep-actor-walk")
      insert_n_actor_changes(actor, 250)

      full_ids =
        Threadline.actor_window(actor, [], repo: @repo) |> Enum.map(& &1.audit_change.id)

      page1_args = [actor, [], [repo: @repo, page_size: 125]]
      page1 = apply(Threadline, :actor_window_page, page1_args)
      assert page1.has_more == true

      page2_args = [actor, [], [repo: @repo, page_size: 125, cursor: page1.cursor]]
      page2 = apply(Threadline, :actor_window_page, page2_args)
      assert page2.has_more == false

      assert page_ids_lc(page1) ++ page_ids_lc(page2) == full_ids
    end

    test "Threadline.Investigation.actor_window_page/3 equals Threadline.actor_window_page/3" do
      actor = actor!(:user, "dep-actor-inv")
      insert_n_actor_changes(actor, 250)

      facade_args = [actor, [], [repo: @repo, page_size: 60]]
      inv_args = [actor, [], [repo: @repo, page_size: 60]]

      facade_page = apply(Threadline, :actor_window_page, facade_args)
      inv_page = apply(Threadline.Investigation, :actor_window_page, inv_args)

      assert page_ids_lc(inv_page) == page_ids_lc(facade_page)
    end
  end

  describe "correlation_bundle_page family (deprecated, D-04, D-11)" do
    test "Threadline.correlation_bundle_page/3 with no :cursor key returns the same first page as correlation_bundle(cursor: :start)" do
      insert_n_correlated_changes("dep-corr-nocursor", 250)

      args = ["dep-corr-nocursor", [], [repo: @repo]]
      page = apply(Threadline, :correlation_bundle_page, args)

      expected =
        Threadline.correlation_bundle("dep-corr-nocursor", [], repo: @repo, cursor: :start)

      assert page_ids_lc(page) == page_ids_lc(expected)
      assert page.has_more == expected.has_more
    end

    test "Threadline.correlation_bundle_page/3 with cursor: nil maps to :start" do
      insert_n_correlated_changes("dep-corr-nilcursor", 250)

      args = ["dep-corr-nilcursor", [], [repo: @repo, cursor: nil]]
      page = apply(Threadline, :correlation_bundle_page, args)

      expected =
        Threadline.correlation_bundle("dep-corr-nilcursor", [], repo: @repo, cursor: :start)

      assert page_ids_lc(page) == page_ids_lc(expected)
    end

    test "walking Threadline.correlation_bundle_page/3 two exact-multiple pages equals correlation_bundle with cursor: :start" do
      insert_n_correlated_changes("dep-corr-walk", 250)

      full_ids =
        Threadline.correlation_bundle("dep-corr-walk", [], repo: @repo)
        |> Enum.map(& &1.audit_change.id)

      page1_args = ["dep-corr-walk", [], [repo: @repo, page_size: 125]]
      page1 = apply(Threadline, :correlation_bundle_page, page1_args)
      assert page1.has_more == true

      page2_args = ["dep-corr-walk", [], [repo: @repo, page_size: 125, cursor: page1.cursor]]
      page2 = apply(Threadline, :correlation_bundle_page, page2_args)
      assert page2.has_more == false

      assert page_ids_lc(page1) ++ page_ids_lc(page2) == full_ids
    end

    test "Threadline.Investigation.correlation_bundle_page/3 equals Threadline.correlation_bundle_page/3" do
      insert_n_correlated_changes("dep-corr-inv", 250)

      facade_args = ["dep-corr-inv", [], [repo: @repo, page_size: 60]]
      inv_args = ["dep-corr-inv", [], [repo: @repo, page_size: 60]]

      facade_page = apply(Threadline, :correlation_bundle_page, facade_args)
      inv_page = apply(Threadline.Investigation, :correlation_bundle_page, inv_args)

      assert page_ids_lc(inv_page) == page_ids_lc(facade_page)
    end
  end

  describe "Threadline.Query.audit_transaction/2 parity (D-06)" do
    import ExUnit.CaptureIO

    test "a missing id: apply(Threadline.Query, :audit_transaction, ...) is nil, Threadline.audit_transaction/2 is {:error, :not_found}" do
      missing_uuid = Ecto.UUID.generate()
      args = [missing_uuid, [repo: @repo]]

      assert apply(Threadline.Query, :audit_transaction, args) == nil
      assert Threadline.audit_transaction(missing_uuid, repo: @repo) == {:error, :not_found}
    end

    test "an existing transaction: the deprecated call returns the bare struct, the facade returns {:ok, struct}, same id" do
      txn = insert_transaction()
      args = [txn.id, [repo: @repo]]

      deprecated_result = apply(Threadline.Query, :audit_transaction, args)

      assert %AuditTransaction{id: id} = deprecated_result
      assert id == txn.id

      assert Threadline.audit_transaction(txn.id, repo: @repo) == {:ok, deprecated_result}
    end

    test "preload: :action: deprecated call's .action.id equals the facade's .action.id, exactly one deprecation warning on stderr" do
      action = insert_action(%{name: "parity.preload", correlation_id: "corr-parity-preload"})
      txn = insert_transaction(%{action_id: action.id})
      args = [txn.id, [repo: @repo, preload: :action]]

      {deprecated_result, stderr} =
        capture_io(:stderr, fn ->
          send(self(), {:deprecated_result, apply(Threadline.Query, :audit_transaction, args)})
        end)
        |> then(fn stderr ->
          receive do
            {:deprecated_result, result} -> {result, stderr}
          end
        end)

      {:ok, facade_result} = Threadline.audit_transaction(txn.id, repo: @repo)

      assert deprecated_result.action.id == facade_result.action.id

      warning_lines =
        stderr
        |> String.split("\n")
        |> Enum.count(&String.contains?(&1, "preloading :action is deprecated"))

      assert warning_lines == 1
    end

    test "a malformed binary id still raises ArgumentError (0.12 behavior kept)" do
      args = ["garbage", [repo: @repo]]

      assert_raise ArgumentError, fn ->
        apply(Threadline.Query, :audit_transaction, args)
      end
    end
  end

  describe "exact deprecated inventories (D-11, API-08)" do
    test "Threadline.__info__(:deprecated) equals the exact expected inventory" do
      assert Enum.sort(Threadline.__info__(:deprecated)) == Enum.sort(@threadline_deprecated)
    end

    test "Threadline.Query.__info__(:deprecated) equals the exact expected inventory" do
      assert Enum.sort(Threadline.Query.__info__(:deprecated)) == Enum.sort(@query_deprecated)
    end

    test "Threadline.Investigation.__info__(:deprecated) equals the exact expected inventory" do
      assert Enum.sort(Threadline.Investigation.__info__(:deprecated)) ==
               Enum.sort(@investigation_deprecated)
    end
  end

  describe "spec and doc presence on every deprecated entry point (D-11)" do
    test "every deprecated {name, arity} on Threadline has a @spec" do
      spec_keys = fetch_specs!(Threadline)

      for {{name, arity}, _message} <- @threadline_deprecated do
        assert {name, arity} in spec_keys,
               "expected a @spec for Threadline.#{name}/#{arity}"
      end
    end

    test "every deprecated {name, arity} on Threadline.Query has a @spec" do
      spec_keys = fetch_specs!(Threadline.Query)

      for {{name, arity}, _message} <- @query_deprecated do
        assert {name, arity} in spec_keys,
               "expected a @spec for Threadline.Query.#{name}/#{arity}"
      end
    end

    test "every deprecated {name, arity} on Threadline.Investigation has a @spec" do
      spec_keys = fetch_specs!(Threadline.Investigation)

      for {{name, arity}, _message} <- @investigation_deprecated do
        assert {name, arity} in spec_keys,
               "expected a @spec for Threadline.Investigation.#{name}/#{arity}"
      end
    end

    test "every deprecated Threadline function has a visible @doc with deprecated metadata (not @doc false)" do
      {:docs_v1, _anno, _lang, _fmt, _moduledoc, _meta, docs} = Code.fetch_docs(Threadline)

      for {{name, arity}, _message} <- @threadline_deprecated do
        assert_deprecated_doc_entry!(docs, "Threadline", name, arity)
      end
    end
  end

  # A function defined with `\\` defaults gets exactly ONE docs_v1 entry, keyed
  # at its highest arity, whose `defaults` metadata count says how many lower
  # arities it also covers (Code.fetch_docs/1 never emits a separate entry per
  # arity) — so a lookup for a lower arity must search entries at or above it,
  # not an exact-arity match.
  defp assert_deprecated_doc_entry!(docs, mod_label, name, arity) do
    entry =
      Enum.find(docs, fn
        {{:function, ^name, entry_arity}, _anno, _sig, _doc, meta} ->
          entry_arity >= arity and entry_arity - Map.get(meta, :defaults, 0) <= arity

        _ ->
          false
      end)

    assert entry, "expected a docs_v1 entry covering #{mod_label}.#{name}/#{arity}"
    {_, _anno, _sig, doc, meta} = entry

    assert doc != :hidden,
           "#{mod_label}.#{name}/#{arity}'s @doc must be visible (not @doc false) so " <>
             "ExDoc shows the deprecation badge"

    assert Map.has_key?(meta, :deprecated),
           "#{mod_label}.#{name}/#{arity}'s docs metadata is missing :deprecated"
  end
end
