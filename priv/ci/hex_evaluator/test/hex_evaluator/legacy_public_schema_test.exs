defmodule HexEvaluator.LegacyPublicSchemaTest do
  @moduledoc """
  Proves a 0.9.x-shaped install — audit tables in `public`, no `storage_schema`
  key configured anywhere — still reads green on this tree (202 D-03).

  This is the regression this fixture exists to catch. `Threadline.StorageSchema`
  cannot detect the schema an adopter installed into. If its default ever
  resolves to anything other than `public` for a host that sets no key, the
  already-deployed unqualified triggers keep writing to `public` while every
  read path queries `threadline.*` — capture continues, exploration goes blank,
  and nothing raises. An empty timeline is not an error anyone gets paged for.

  Assertions here deliberately measure the ARTIFACT (what schema the objects are
  actually in, via `information_schema`) rather than the configuration that
  produced it. Three vacuous gates have been found in this repo by measuring
  configuration instead of outcome.

  Run via root `mix verify.hex_evaluator` (CI job `verify-hex-evaluator`).
  """
  use HexEvaluator.DataCase, async: false

  alias HexEvaluator.{Post, Repo}
  alias Threadline.Capture.AuditChange

  @audit_tables ~w(audit_changes audit_transactions)

  setup do
    slug = "legacy-public-#{System.unique_integer([:positive])}"

    {:ok, post} = Repo.insert(%Post{title: "Legacy public schema", slug: slug})

    on_exit(fn -> Repo.delete(post) end)

    {:ok, post: post}
  end

  test "this fixture is still legacy-shaped: no storage_schema is configured" do
    assert Application.get_env(:threadline, :storage_schema) == nil, """
    The hex evaluator fixture has acquired a :storage_schema config key.

    That silently stops this file from proving anything: it would then exercise
    a CONFIGURED install, not the 0.9.x-shaped install (no key at all) that the
    entire existing adopter population actually runs. If a dedicated-schema
    fixture is wanted, add it as a SECOND fixture — do not configure this one.
    """
  end

  test "an unconfigured host resolves to the public schema" do
    assert Threadline.StorageSchema.get([]) == "public", """
    Threadline.StorageSchema resolved to something other than "public" for a
    host that configures no :storage_schema.

    That is the split brain: the triggers this fixture's migrations installed
    are unqualified and write to public, while every read path would now be
    prefixed with the resolved schema and query tables that do not exist.
    """
  end

  test "the audit tables are physically in public, and no threadline schema exists" do
    %{rows: rows} =
      Ecto.Adapters.SQL.query!(
        Repo,
        """
        SELECT table_schema, table_name
        FROM information_schema.tables
        WHERE table_name = ANY($1)
        """,
        [@audit_tables]
      )

    found = Enum.map(rows, fn [schema, table] -> {schema, table} end)

    for table <- @audit_tables do
      assert {"public", table} in found, """
      #{table} was not found in the public schema.

      Found instead: #{inspect(found)}

      This fixture's migrations create the audit tables unqualified, which is
      exactly what a pre-0.10 install looks like. If they are not in public,
      the fixture has stopped modelling the population this test protects.
      """

      refute {"threadline", table} in found, """
      #{table} exists in a "threadline" schema inside this fixture.

      The legacy-public proof is only meaningful while no dedicated schema is
      present — otherwise a threadline.-prefixed read path could pass here and
      still break every real 0.9.x adopter.
      """
    end
  end

  test "a trigger-written change row reads back with no schema prefix", %{post: post} do
    query =
      from(ac in AuditChange,
        where: ac.table_name == "posts",
        where: fragment("?->>'id' = ?", ac.table_pk, ^to_string(post.id))
      )

    assert Repo.aggregate(query, :count) >= 1, """
    No audit_changes row was readable for the inserted post.

    The trigger wrote to the unqualified (public) audit_changes table. If the
    read came back empty, Threadline.Capture.AuditChange is resolving against a
    different schema than the triggers write to — the 0.9.x split brain, in the
    exact shape an adopter would experience it: a silent, empty timeline.
    """

    change = Repo.one!(query |> limit(1))

    assert change.table_schema == "public",
           "the captured row reports table_schema #{inspect(change.table_schema)}, not public"
  end
end
