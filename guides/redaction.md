# Redaction scope and rollout

Threadline redaction applies to the generated per-table capture function and the
audit data it writes. The current migration proof rejects a configured `mask:`
or `exclude:` column that is absent from the selected table before it installs
that table's trigger. The regression is exercised by
`Threadline.Capture.TriggerMigrateTimeErrorsTest` in
`test/threadline/capture/trigger_migrate_time_errors_test.exs`.

After changing a table's redaction policy, regenerate and apply the host-owned
trigger migration for each affected table before relying on the new policy.
An installed trigger does not change when application configuration or the
Threadline package changes. Previously captured audit rows are not repaired by
regeneration; review and handle those rows under your retention and incident
procedures.

This guide describes the generated per-table migration path only. See the
[first-hour adoption path](getting-started-saas.md) for the rest of the host
setup and the [production checklist](production-checklist.md) for deployment
review.

## Next steps

- [Return to the canonical first-hour adoption path](getting-started-saas.md).
- [Review production operations](production-checklist.md).
