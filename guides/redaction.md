# Redaction scope and rollout

Threadline redaction is applied by the generated per-table capture function.
The evidence below describes the paths each test exercises; it does not
establish that every copy of a value is redacted.

## What the evidence covers

| Claim | Evidence and scope |
| --- | --- |
| A generated per-table trigger omits excluded values and masks configured values in persisted audit changes, diffs, and CSV, JSON, and NDJSON exports. | [`Threadline.Capture.RedactionLeakPropertyTest`](https://github.com/szTheory/threadline/blob/main/test/threadline/capture/redaction_leak_property_test.exs) runs against a real generated per-table trigger and checks stored `audit_changes` and `audit_transactions`, `ChangeDiff`, and export output. |
| Redaction policy shape is validated, including overlap rules. | [`Threadline.Capture.RedactionPolicyPropertyTest`](https://github.com/szTheory/threadline/blob/main/test/threadline/capture/redaction_policy_property_test.exs) checks the policy value contract. |
| A generated host migration rejects an absent configured `mask:` or `exclude:` column before trigger installation and rolls back. | [`Threadline.Capture.TriggerMigrateTimeErrorsTest`](https://github.com/szTheory/threadline/blob/main/test/threadline/capture/trigger_migrate_time_errors_test.exs) runs the migration against PostgreSQL and checks trigger, table function, migration row, and host-write behavior. |
| The configured/deployed policy view compares policy descriptions. | [`Threadline.Policy.RedactionPresenterTest`](https://github.com/szTheory/threadline/blob/main/test/threadline/policy/redaction_presenter_test.exs) and `mix threadline.policy.show` compare configured policy with deployed trigger SQL; they do not validate column existence and do not create a column-existence health finding. |

The generated-migration check uses the selected table's PostgreSQL catalog and
checks `pg_attribute.attname`, `attnum > 0`, and `NOT attisdropped`. A value
change to a masked column can still appear as that column's name in
`changed_fields`; that reveals that a value changed, not the masked value.

## Rollout timing

Generated trigger migrations are owned by the host application. After changing
redaction for a table, correct its configuration, regenerate the trigger
migration for that table, and apply the migration with the host's normal
migration process. Threadline package or configuration changes do not rewrite
an already-installed trigger. The migration check does not redact or repair
`audit_changes` rows captured before the corrected trigger was applied; review
those rows under the host's retention and incident procedures.

## Where plaintext may remain

Redaction of generated per-table audit output does not remove the source value
or control every copy around PostgreSQL and the host application. Plaintext may
remain in:

- host source tables;
- PostgreSQL WAL, logical decoding output, and replication slots;
- backups;
- access available to PostgreSQL superusers;
- audit rows captured before a redaction rule was corrected or introduced;
- host application logs; and
- downstream copies made from exported data.

Threadline cannot control copies made after an export leaves the process that
produced it. Plan access, logging, backup, replication, and retention controls
for those systems separately.

## Boundaries not covered by this proof

The checks above cover generated per-table migrations and their per-table
capture functions. They do not establish equivalent behavior for the global
redacted `TriggerSQL.install_function/1` path, which generated migrations do
not emit, or for a direct `TriggerSQL.create_trigger/3` call that omits the
redaction options. Treat both as separate follow-up gaps.

## Next steps

- [Return to the canonical first-hour adoption path](getting-started-saas.md).
- [Review production operations](production-checklist.md).
