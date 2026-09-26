-- Frozen copy of Threadline's 0.10.2 global capture function body (tag
-- v0.10.2, commit ee137e51), from
-- lib/threadline/capture/trigger_sql.ex global_install_function_sql_legacy/1.
-- Renamed to "threadline"."bench_capture_v0_10_2" so it can be installed
-- alongside the current body in the same database for the CAP-06 benchmark.
-- Rendered by Threadline.Test.LegacyTriggerSQL.v0_10_2_install_function/2;
-- see test/threadline/capture/legacy_trigger_pk_fallback_test.exs for the
-- equality test pinning this file against that renderer.
CREATE OR REPLACE FUNCTION "threadline"."bench_capture_v0_10_2"()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $threadline_trigger$
DECLARE
  v_txid           bigint;
  v_tx_id          uuid;
  v_data_after     jsonb;
  v_table_pk       jsonb;
  v_changed_fields text[];
BEGIN
  v_txid := txid_current();

  -- Upsert the audit_transactions row keyed on the PostgreSQL transaction ID.
  -- ON CONFLICT DO NOTHING is idempotent: multiple writes in the same transaction
  -- reuse the existing row. This is PgBouncer-safe because txid_current() is
  -- transaction-scoped, not session-scoped.
  INSERT INTO "threadline"."audit_transactions" (id, txid, occurred_at, actor_ref)
  VALUES (
    gen_random_uuid(),
    v_txid,
    clock_timestamp(),
    NULLIF(current_setting('threadline.actor_ref', true), '')::jsonb
  )
  ON CONFLICT (txid) DO NOTHING;

  SELECT id INTO v_tx_id
  FROM "threadline"."audit_transactions"
  WHERE txid = v_txid;

  IF TG_OP = 'DELETE' THEN
    v_table_pk       := jsonb_build_object('id', (to_jsonb(OLD) ->> 'id'));
    v_data_after     := NULL;
    v_changed_fields := NULL;

  ELSIF TG_OP = 'INSERT' THEN
    v_table_pk       := jsonb_build_object('id', (to_jsonb(NEW) ->> 'id'));
    v_data_after     := to_jsonb(NEW);
    v_changed_fields := NULL;

  ELSE
    -- UPDATE: capture changed field names
    v_table_pk   := jsonb_build_object('id', (to_jsonb(NEW) ->> 'id'));
    v_data_after := to_jsonb(NEW);

    SELECT array_agg(n.key ORDER BY n.key)
    INTO   v_changed_fields
    FROM   jsonb_each(to_jsonb(NEW)) AS n
    JOIN   jsonb_each(to_jsonb(OLD)) AS o ON n.key = o.key
    WHERE  n.value IS DISTINCT FROM o.value;
  END IF;

  INSERT INTO "threadline"."audit_changes" (
    id, transaction_id, table_schema, table_name,
    table_pk, op, data_after, changed_fields, changed_from, captured_at
  ) VALUES (
    gen_random_uuid(), v_tx_id, TG_TABLE_SCHEMA, TG_TABLE_NAME,
    v_table_pk, lower(TG_OP), v_data_after, v_changed_fields, NULL::jsonb, clock_timestamp()
  );

  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  END IF;
  RETURN NEW;
END;
$threadline_trigger$
