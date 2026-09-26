defmodule HexEvaluator.Repo.Migrations.CreateShapeFixtures do
  use Ecto.Migration

  # TWIN-01 table-shape contract fixtures for the hex evaluator adopter twin
  # (Phase 212). These are the evaluator's OWN local fixtures — an independent
  # file, never a symlink or shared include with the example app's fixtures
  # (D-19) — because the evaluator is a separate project that resolves
  # `:threadline` from the rehearsal registry, not the working tree.
  #
  # These are not domain tables. They exist only so the hex evaluator can
  # prove that every table shape `mix threadline.gen.triggers` supports
  # (a non-`id` text primary key, a composite primary key, a primary-key-less
  # table addressed by a `primary_key:` override, a table name duplicated
  # across two schemas, and a table name at the long end of PostgreSQL's
  # 63-byte identifier limit) works end to end through a packaged install.

  def up do
    execute "CREATE TABLE shape_code_keyed (code text PRIMARY KEY, label text)"

    execute """
    CREATE TABLE shape_composite (
      tenant_id bigint NOT NULL,
      line_no integer NOT NULL,
      qty integer,
      PRIMARY KEY (tenant_id, line_no)
    )
    """

    execute """
    CREATE TABLE shape_join (
      left_id bigint NOT NULL,
      right_id bigint NOT NULL,
      note text
    )
    """

    execute "CREATE UNIQUE INDEX shape_join_pair ON shape_join (left_id, right_id)"

    execute "CREATE TABLE shape_twin (id bigint PRIMARY KEY, note text)"

    execute "CREATE SCHEMA IF NOT EXISTS shapes"
    execute "CREATE TABLE shapes.shape_twin (id bigint PRIMARY KEY, note text)"

    execute """
    CREATE TABLE shape_long_name_padded_to_prove_sixty_byte_identifiers_work_ok (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      label text
    )
    """
  end

  def down do
    execute "DROP TABLE IF EXISTS shape_long_name_padded_to_prove_sixty_byte_identifiers_work_ok"
    execute "DROP TABLE IF EXISTS shapes.shape_twin"
    execute "DROP SCHEMA IF EXISTS shapes"
    execute "DROP TABLE IF EXISTS shape_twin"
    execute "DROP INDEX IF EXISTS shape_join_pair"
    execute "DROP TABLE IF EXISTS shape_join"
    execute "DROP TABLE IF EXISTS shape_composite"
    execute "DROP TABLE IF EXISTS shape_code_keyed"
  end
end
