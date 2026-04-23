---
status: passed
phase: "14"
verified_at: 2026-04-23
---

# Phase 14 verification (EXPO-01 / EXPO-02)

## Must-haves

| Requirement | Evidence |
|-------------|----------|
| EXPO-01 — CSV export | `lib/threadline/export.ex` `to_csv_iodata/2`, NimbleCSV RFC4180, `test/threadline/export_test.exs` (happy path, empty, truncation, encoding, strict keys). |
| EXPO-02 — JSON export | `to_json_document/2` with `format_version`, NDJSON opt, same tests + filter parity vs `Threadline.timeline/2`. |
| Shared filter pipeline | `Threadline.Query.validate_timeline_filters!/1`, `timeline_query/1`, single `audit_transactions` join; `export_changes_query/1`. |
| Operator surfaces | `mix threadline.export`, `Threadline.export_csv/2`, `Threadline.export_json/2`, README + `guides/domain-reference.md` **Export (Phase 14)**, ExDoc groups in `mix.exs`. |

## Automated checks

- `DB_PORT=5433 MIX_ENV=test mix ci.all` — pass (2026-04-23).

## Gaps

None identified for Phase 14 scope.
