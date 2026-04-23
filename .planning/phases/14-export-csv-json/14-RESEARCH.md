# Phase 14: Export (CSV & JSON) — Research

**Role:** gsd-phase-researcher  
**Date:** 2026-04-23  
**Question answered:** What do you need to know to **plan** this phase well?

---

## 1. Executive summary

- **EXPO-01 / EXPO-02** are satisfied by a new **public export module** (name TBD; context suggests e.g. `Threadline.Export`) plus **HexDocs/README** cross-links to `Threadline.Query` / `Threadline.timeline/2`, not by UI or raw `Ecto.Query` as the primary input (**D-04**).
- **Single filter pipeline (D-02)** must be extracted or centralized from `Threadline.Query.timeline/2` today: `AuditChange` base query, `filter_by_table/2`, `filter_by_actor/2`, `filter_by_from/2`, `filter_by_to/2`, `order_by(desc: captured_at)` in `lib/threadline/query.ex` (see `timeline/2` at lines 84–96 and privates at 98–130).
- **`repo` resolution (D-01)** should match `timeline/2` exactly: `Keyword.get(opts, :repo) || Keyword.fetch!(filters, :repo)` — same as current `Query.timeline/2`.
- **Strict filter keys (D-03)** are a *new* behavioral contract relative to **current** `timeline/2`, which ignores unknown keys via `Keyword.get/3`. Planning must decide whether validation is **export-only** or **shared** (so `timeline/2` also raises on typos); D-01 implies callers pass the “same” filter list, so **shared validation** is the coherent reading.
- **Dependencies:** `Jason` is already in `mix.exs` (`{:jason, "~> 1.4"}`). **NimbleCSV** is **not** present yet; add it (or document an alternative) for RFC 4180–safe cells when JSON blobs sit in CSV columns (**D-09**).
- **Transaction context (D-07)** requires a **join** to `Threadline.Capture.AuditTransaction` with selected fields (`id`, `occurred_at`, `actor_ref`, `source` per context). Today `filter_by_actor/2` already adds an **inner** `join` to `AuditTransaction` (`query.ex` 112–117). A unified pipeline must avoid **double joins** on the same alias when both actor filter and “always join for export columns” apply — central `from`/`join` design is a planning must.
- **Bounded default + truncation metadata (D-11)** is the primary large-row story: `limit: max_rows + 1` (or count query), surface `truncated?:`, `returned_count`, `max_rows` in return value or wrapper; align error/ok style with **`Threadline.Retention.purge/1`** (returns map or `{:error, :disabled}`) vs **`Threadline.Query`** (exceptions like `Ecto.Repo.all`). Context **D-15** asks the plan to pick **one** convention for export and document it; today **Query raises/fetches** on DB errors, **Retention** uses tagged error for disabled only.
- **Streaming (D-12)** should be **keyset-paginated** `Stream` over short `repo.all/2` (or `repo.stream` *inside* per-page `Repo.transaction` callbacks), not a single unbounded `Repo.stream` without warnings (**D-13**).
- **Mix task (D-16)** should mirror `Mix.Tasks.Threadline.Retention.Purge`: `app.config`, start `ssl` / `postgrex` / `ecto_sql`, `resolve_repo!/0` from `Application.get_env(:threadline, :ecto_repos, [])`, `ensure_repo_started!/1`, argv parsing, **zero** business logic in the task — see `lib/mix/tasks/threadline.retention.purge.ex`.
- **ActorRef in JSON (D-09 / D-10):** `AuditTransaction.actor_ref` uses the custom `Ecto.ParameterizedType` `Threadline.Semantics.ActorRef` — there is **no** `Jason.Encoder` in `actor_ref.ex`; export builders should serialize via **`ActorRef.to_map/1`** (or equivalent) for stable nested maps in JSON/CSV JSON columns.

---

## 2. Current code anchors

| Asset | Path / symbol | Reuse notes |
|--------|-----------------|-------------|
| Timeline filters + ordering | `Threadline.Query.timeline/2` | `lib/threadline/query.ex:84-96` — base `AuditChange`, four optional filters, `order_by([ac], desc: ac.captured_at)`. |
| Table filter | `filter_by_table/2` | `query.ex:100-108` — atom → string for `table_name`. |
| Actor filter + join | `filter_by_actor/2` | `query.ex:110-118` — `ActorRef.to_map/1`, `join(:inner, ...)`, `@>` JSONB on `at.actor_ref`. |
| Time bounds | `filter_by_from/2`, `filter_by_to/2` | `query.ex:120-130` — inclusive `captured_at` range. |
| Public delegators | `Threadline.timeline/2` | `lib/threadline.ex:87-99` — add sibling delegators after plan names functions. |
| Row shape (CSV/JSON columns) | `Threadline.Capture.AuditChange` | `lib/threadline/capture/audit_change.ex` — `table_schema`, `table_name`, `table_pk`, `op`, `data_after`, `changed_fields`, `changed_from`, `captured_at`, `transaction_id`. |
| Transaction shape | `Threadline.Capture.AuditTransaction` | `lib/threadline/capture/audit_transaction.ex` — `id`, `txid`, `occurred_at`, `source`, `meta`, `actor_ref`, `action_id`; context D-07 names a **slim** subset for nested `transaction`. |
| Retention API pattern | `Threadline.Retention.purge/1` | `lib/threadline/retention.ex` — required `repo:`, keyword opts, structured map return, `Logger` for batch ops. |
| Mix task shell | `Mix.Tasks.Threadline.Retention.Purge` | `lib/mix/tasks/threadline.retention.purge.ex` — `OptionParser.parse/2`, prod gate pattern (`--execute`), delegate to public API. |
| Repo resolution in Mix | `resolve_repo!/0`, `ensure_repo_started!/1` | Same file lines 79–97; duplicated in `threadline.verify_coverage.ex` — consider small shared helper **only if** plan wants DRY (optional; not required by context). |
| Integration test style | `Threadline.QueryTest`, `Threadline.Retention.PurgeTest` | `test/threadline/query_test.exs`, `test/threadline/retention/purge_test.exs` — `use Threadline.DataCase`, insert fixtures via `AuditTransaction` / `AuditChange` changesets. |

**Gap vs D-05:** `timeline/2` returns `%AuditChange{}` without preloaded `transaction`. Export needs joined or selected transaction fields without N+1 — new `select`/`preload` strategy in the shared query or a dedicated export query built on the same filter pipeline.

---

## 3. Elixir ecosystem notes

### NimbleCSV (and CSV safety)

- **Purpose:** Escape quotes, commas, newlines in cells; stable row-oriented output for spreadsheets and `awk` pipelines (**D-05**, **D-09**).
- **Plan impact:** Add dependency; pick **dump**-style API (`NimbleCSV.RFC4180.dump_to_iodata/2` or similar — exact function names per installed version in plan).
- **Alternative:** Manual RFC 4180 escaping is error-prone; not recommended for JSON-in-CSV cells.

### Jason

- Already a direct dependency of `:threadline` (`mix.exs:43`).
- **D-10:** Tests should `Jason.decode!/1` and compare **maps** (or key subsets), not full serialized strings.
- **Encoding:** For JSON wrapper + NDJSON lines, use `Jason.encode!/1` or `encode_to_iodata!/1` per memory/IO strategy; document that NDJSON is **one object per line** (**D-08**).

### `Ecto.Repo.stream` footguns (**D-12**, **D-13**)

- Per Ecto docs, **`Repo.stream/2` requires an outer `Repo.transaction`**; default timeouts may kill long streams — **`timeout: :infinity`** when justified, with explicit warnings for connection pool hold time.
- **Danger:** Holding a connection across slow consumers (HTTP, S3 upload) starves the pool — context correctly defers chunked HTTP to host apps; library should expose **stream of pages** or **enumerable of rows** with **short** DB interactions.
- **Safer default:** `Stream.unfold/2` or `Stream.resource/3` where each step runs `repo.all(from q, limit: page_size)` with keyset `where` on `(captured_at, id)` consistent with **desc** timeline order (see keyset below).

### Keyset pagination (export-stable ordering)

- **Timeline order:** `captured_at` **desc** (`query.ex:94`).
- **Keyset for “next page” in desc order:** cursor `(after_captured_at, after_id)`; next page uses tuple comparison in SQL, e.g. rows “older” than cursor: `(captured_at < ^c) or (captured_at == ^c and id < ^id)` when using **UUID** or comparable `id` (binary_id UUIDs are **not** chronologically sortable as strings — **planning risk**: `id` is `:binary_id` UUID (`audit_change.ex:43`). **Tie-breaker:** For strict stable ordering when `captured_at` ties, `id` comparison is still **total** if compared as UUID byte order or as string consistently — document chosen semantics; alternatively order by `(captured_at desc, id desc)` and use lexicographic comparison consistent with PostgreSQL `ORDER BY id` for `uuid` type).
- **Planner should verify** PostgreSQL `ORDER BY captured_at DESC, id DESC` matches the keyset predicates Ecto emits (integration test with two rows same `captured_at` microsecond).

### Memory (**D-14**)

- Full `data_after` JSONB maps can be large; optional **profile** omitting heavy columns for CSV (**D-14** discretion) should be spelled out in the plan if shipped.

---

## 4. API design implications vs CONTEXT decisions (D-01–D-18)

| ID | Implication for PLAN |
|----|----------------------|
| **D-01** | Export functions take `(filters, opts)` mirroring `timeline/2`; document in `@doc` with copy-pasteable examples showing identical keywords. |
| **D-02** | Refactor `Query` to call e.g. `timeline_query(filters)` returning `%Ecto.Query{}` **before** `repo.all/2`; export uses same function + optional `join`/`select` for transaction fields. |
| **D-03** | Implement `validate_timeline_filters!/1` (or similar): allowed keys set e.g. `[:repo, :table, :actor_ref, :from, :to]` — raise `ArgumentError` listing allowed keys. Apply to **both** export and `timeline/2` if D-01 “same filters” is strict. |
| **D-04** | No public `export_from_query/2` in v1.3; internal `%Ecto.Query{}` is fine. |
| **D-05** | CSV column list fixed; JSON in cells for maps/arrays; datetimes as **ISO 8601 UTC** strings (`DateTime.to_iso8601/1` with UTC). |
| **D-06** | JSON document wrapper keys: `format_version`, `generated_at`, `changes`. |
| **D-07** | One query: extend pipeline with join to `audit_transactions` (see §2 double-join risk). Nested `transaction: %{...}` (or fixed key per plan). |
| **D-08** | Separate code path or option `:format | :ndjson` — newline after each per-change JSON object. |
| **D-09** | NimbleCSV + Jason; document encoding. |
| **D-10** | Test helpers decode JSON; avoid golden file byte equality. |
| **D-11** | Constants like `@default_max_rows 10_000` (planner picks); `truncated?` when `count > max_rows` or `limit+1` probe; return metadata struct/map. |
| **D-12** | Public `stream_*` (name TBD) with page size 500–2000; document ordering and cursor arguments. |
| **D-13** | Doc-only or optional helper for `Repo.stream` under `Repo.transaction`, `timeout: :infinity`, warnings — not the default happy path. |
| **D-14** | Optional CSV “metadata-only” mode in plan if it reduces scope risk. |
| **D-15** | Choose `{:ok, result}` vs raw map vs exceptions — **align** with one family; if export returns `{:ok, %{data: ..., truncated: ...}}`, document DB errors (still likely exceptions from Ecto unless wrapped). |
| **D-16** | `mix threadline.export` (final name): argv for `--output`, format, `--limit` / `--max-rows`, filter flags mirroring timeline (`--table`, time bounds if represented as ISO strings, actor as opaque string TBD — **open**: CLI encoding of `ActorRef`). |
| **D-17** | `--dry-run` or banner with row count before streaming bytes; read-only. |
| **D-18** | Update `README.md`, `guides/domain-reference.md`, `mix.exs` `groups_for_modules` for new modules (see current `Threadline`, `Mix.Tasks.*` groups `mix.exs:104-128`), and `@doc` links from `Threadline.Query` to export. |

---

## 5. Testing strategy

- **Harness:** Reuse `use Threadline.DataCase` and fixture patterns from `test/threadline/query_test.exs` (`insert_transaction/1`, `insert_change/2`, `actor!/2`).
- **Postgres integration (required):**
  - **Happy path CSV:** Known rows → decode CSV (NimbleCSV or fixture parser) → assert column count and cell values / JSON-decoded maps for JSON columns.
  - **Happy path JSON:** `Jason.decode!/1` → assert `format_version`, `generated_at` structure, `changes` length, nested `transaction` keys.
  - **NDJSON (if shipped):** Per-line `Jason.decode!/1`; assert same keys as array mode.
- **Filter parity:** For each filter in `QueryTest` (table string/atom, from, to, actor), assert export row set **matches** `Threadline.timeline(filters, opts)` row ids (order may be same desc — assert order equality for deterministic inserts).
- **Empty set:** No rows → empty `changes` / CSV header-only or zero data rows per chosen contract; document behavior.
- **Truncation:** Insert `max_rows + 2` matching rows with **distinct** `captured_at` / ids; `max_rows: n` → `truncated?: true`, `returned_count == n` (or n and metadata per plan).
- **Encoding edge cases:** Cell containing `","`, newline, UTF-8; JSON round-trip.
- **Strict filters:** `assert_raise ArgumentError`, message mentions allowed keys.
- **Doc contract:** If repo uses `readme_doc_contract_test.exs`, extend assertions for export mentions / timeline cross-links (**D-18**).

---

## 6. Risks and open questions for the planner

1. **Double `join` on `audit_transactions`:** Actor filter and “always join for D-07” must compose into **one** join binding (refactor `filter_by_actor/2` or use `binding`/`as:` once Ecto min version supports it — project is Elixir `~> 1.15`; check Ecto 3.10 `named_binding` availability).
2. **`timeline/2` strict keys:** Behavioral change for any caller passing extra keywords today; semver / changelog note for **0.1.0** vs patch — product decision.
3. **CLI `ActorRef`:** Mix argv may need `--actor-type` + `--actor-id` or documented JSON string; align with **D-16** and security (shell history).
4. **UUID keyset semantics:** Document total ordering for `(captured_at, id)` pagination; add tests with identical `captured_at`.
5. **`occurred_at` vs `captured_at`:** D-07 lists transaction `occurred_at` — timeline filters **`captured_at`** on changes; document that transaction timestamps can differ from change capture time (operator confusion).
6. **`txid` / `meta` / `action_id`:** Context slim map excludes them; confirm no EXPO requirement to expose `action_id` for semantic joins — if needed, add as optional fields in plan.
7. **Return type vs streaming:** D-11 metadata (`truncated?`) couples naturally to **finite** `iodata`/`binary` returns; streaming API may need **separate** metadata callback or first-line header for NDJSON — plan should spell this out.
8. **Oban/cron:** Retention doc patterns in README apply; export should reference pool sizing similarly (**D-13**).

---

## Validation Architecture

Concrete dimensions for Nyquist / downstream validation of Phase 14:

| Dimension | What “good” looks like | Evidence |
|-----------|----------------------|----------|
| **Export correctness** | Exported row sets match DB truth for inserted fixtures; CSV and JSON row counts align. | Integration tests with known inserts; manual spot-check optional. |
| **Filter parity with timeline** | Same `filters` + `opts` as `Threadline.Query.timeline/2` yields the same `audit_changes.id` multiset (and ordering if specified). | Parametrized tests mirroring `describe "timeline/1 — QUERY-03"` cases in `query_test.exs`. |
| **Encoding safety** | CSV survives RFC 4180 edge cases; JSON parses; NDJSON lines are independent decodable objects. | Property or table-driven tests with malicious-looking strings; UTF-8. |
| **Truncation metadata** | When rows exceed cap, operators see **`truncated?: true`** (or equivalent) and accurate **`returned_count`** / **`max_rows`** — never silent partial export. | Test with `max_rows + 1` inserts; assert metadata fields. |
| **JSON stability (D-10)** | Semantic equality after `Jason.decode`; required keys present; `format_version` present. | Decode-map assertions, not string equality. |
| **Transaction embed (D-07)** | Each exported change includes nested transaction map with at least `id`, `occurred_at`, `actor_ref`, `source`; no N+1 (single query plan). | Ecto SQL sandbox or `Ecto.Adapters.SQL.explain` optional; assert query count / or code inspection + functional test. |
| **Strict filter boundary (D-03)** | Unknown key → `ArgumentError` with allowed-key list. | `assert_raise` tests. |
| **Docs links (D-18)** | README + domain guide + Hex module docs cross-link **timeline** and **export** workflows. | `readme_doc_contract_test.exs` (or grep-based doc test) and human README review. |
| **Mix task delegation (D-16)** | `mix threadline.export` contains no filter/query logic — only argv + repo bootstrap + public API call. | Code review / grep task file for `Ecto.Query`. |
| **Read-only guarantee** | Export code paths perform no `INSERT`/`UPDATE`/`DELETE` on audit tables. | Code review; optional `DataCase` with repo log stub (lightweight: assert no `Repo.delete` in module). |

---

*Research sources: `14-CONTEXT.md`, `REQUIREMENTS.md` (EXPO-01, EXPO-02), `STATE.md`, `lib/threadline/query.ex`, `lib/threadline.ex`, capture schemas, `lib/threadline/retention.ex`, `lib/mix/tasks/threadline.retention.purge.ex`, `mix.exs`, `test/threadline/query_test.exs`, `test/threadline/retention/purge_test.exs`.*
