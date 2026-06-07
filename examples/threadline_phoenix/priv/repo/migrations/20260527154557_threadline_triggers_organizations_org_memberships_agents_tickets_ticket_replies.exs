defmodule ThreadlineTriggersOrganizationsOrgMembershipsAgentsTicketsTicketReplies do
  use Ecto.Migration

  def up do
    execute "CREATE OR REPLACE FUNCTION threadline.threadline_capture_changes_ticket_replies()\nRETURNS TRIGGER\nLANGUAGE plpgsql\nAS $threadline_trigger$\nDECLARE\n  v_txid           bigint;\n  v_tx_id          uuid;\n  v_data_after     jsonb;\n  v_table_pk       jsonb;\n  v_changed_fields text[];\n  v_changed_from   jsonb;\nBEGIN\n  v_txid := txid_current();\n\n  -- Upsert the audit_transactions row keyed on the PostgreSQL transaction ID.\n  -- ON CONFLICT DO NOTHING is idempotent: multiple writes in the same transaction\n  -- reuse the existing row. This is PgBouncer-safe because txid_current() is\n  -- transaction-scoped, not session-scoped.\n  INSERT INTO threadline.audit_transactions (id, txid, occurred_at, actor_ref)\n  VALUES (\n    gen_random_uuid(),\n    v_txid,\n    clock_timestamp(),\n    NULLIF(current_setting('threadline.actor_ref', true), '')::jsonb\n  )\n  ON CONFLICT (txid) DO NOTHING;\n\n  SELECT id INTO v_tx_id\n  FROM threadline.audit_transactions\n  WHERE txid = v_txid;\n\n\n  IF TG_OP = 'DELETE' THEN\n    v_table_pk       := jsonb_build_object('id', (to_jsonb(OLD) ->> 'id'));\n    v_data_after     := NULL;\n    v_changed_fields := NULL;\n    v_changed_from   := NULL;\n\n  ELSIF TG_OP = 'INSERT' THEN\n    v_table_pk       := jsonb_build_object('id', (to_jsonb(NEW) ->> 'id'));\n    v_data_after     := to_jsonb(NEW);\n        v_data_after := v_data_after || jsonb_build_object('internal_note_body', to_jsonb('[REDACTED]'::text));\n\n    v_changed_fields := NULL;\n    v_changed_from   := NULL;\n\n  ELSE\n    v_table_pk   := jsonb_build_object('id', (to_jsonb(NEW) ->> 'id'));\n    v_data_after := to_jsonb(NEW);\n        v_data_after := v_data_after || jsonb_build_object('internal_note_body', to_jsonb('[REDACTED]'::text));\n\n\n    SELECT array_agg(n.key ORDER BY n.key)\n    INTO   v_changed_fields\n    FROM   jsonb_each(to_jsonb(NEW)) AS n\n    JOIN   jsonb_each(to_jsonb(OLD)) AS o ON n.key = o.key\n    WHERE  n.value IS DISTINCT FROM o.value\n    AND NOT (n.key = ANY(ARRAY[]::text[]));\n\n    IF v_changed_fields IS NULL THEN\n      v_changed_from := NULL::jsonb;\n    ELSE\n      SELECT jsonb_object_agg(\n               u.k,\n               CASE\n                 WHEN u.k = ANY(ARRAY['internal_note_body']::text[]) THEN to_jsonb('[REDACTED]'::text)\n                 ELSE to_jsonb(OLD) -> u.k\n               END\n             )\n      INTO v_changed_from\n      FROM unnest(v_changed_fields) AS u(k);\n\n    END IF;\n\n  END IF;\n\n  INSERT INTO threadline.audit_changes (\n    id, transaction_id, table_schema, table_name,\n    table_pk, op, data_after, changed_fields, changed_from, captured_at\n  ) VALUES (\n    gen_random_uuid(), v_tx_id, TG_TABLE_SCHEMA, TG_TABLE_NAME,\n    v_table_pk, lower(TG_OP), v_data_after, v_changed_fields, v_changed_from, clock_timestamp()\n  );\n\n\n  IF TG_OP = 'DELETE' THEN\n    RETURN OLD;\n  END IF;\n  RETURN NEW;\nEND;\n$threadline_trigger$\n"

    execute "CREATE TRIGGER threadline_audit_organizations\nAFTER INSERT OR UPDATE OR DELETE ON organizations\nFOR EACH ROW EXECUTE FUNCTION threadline.threadline_capture_changes()\n"

    execute "CREATE TRIGGER threadline_audit_org_memberships\nAFTER INSERT OR UPDATE OR DELETE ON org_memberships\nFOR EACH ROW EXECUTE FUNCTION threadline.threadline_capture_changes()\n"

    execute "CREATE TRIGGER threadline_audit_agents\nAFTER INSERT OR UPDATE OR DELETE ON agents\nFOR EACH ROW EXECUTE FUNCTION threadline.threadline_capture_changes()\n"

    execute "CREATE TRIGGER threadline_audit_tickets\nAFTER INSERT OR UPDATE OR DELETE ON tickets\nFOR EACH ROW EXECUTE FUNCTION threadline.threadline_capture_changes()\n"

    execute "CREATE TRIGGER threadline_audit_ticket_replies\nAFTER INSERT OR UPDATE OR DELETE ON ticket_replies\nFOR EACH ROW EXECUTE FUNCTION threadline.threadline_capture_changes_ticket_replies()\n"
  end

  def down do
    execute "DROP TRIGGER IF EXISTS threadline_audit_organizations ON organizations"

    execute "DROP TRIGGER IF EXISTS threadline_audit_org_memberships ON org_memberships"

    execute "DROP TRIGGER IF EXISTS threadline_audit_agents ON agents"

    execute "DROP TRIGGER IF EXISTS threadline_audit_tickets ON tickets"

    execute "DROP TRIGGER IF EXISTS threadline_audit_ticket_replies ON ticket_replies"

    execute "DROP FUNCTION IF EXISTS threadline.threadline_capture_changes_ticket_replies() CASCADE"
  end
end
