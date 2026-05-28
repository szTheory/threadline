---
status: issues
phase: 121-adopter-doc-neutrality
reviewed: 2026-05-28
depth: standard
files_reviewed: 9
findings_critical: 0
findings_warning: 0
findings_info: 2
total: 2
---

# Phase 121 Code Review

Adopter doc neutrality — auth-agnostic getting-started §5/§6 hero wiring, four-lane README/evaluator discovery, scoped Sigra reference fences, and ADOPT-AUTH-03 phx-gen-auth doc-contract gate.

## Scope Reviewed

**121-01 (getting-started + upgrade-path neutrality)**

- `guides/getting-started-saas.md` — generic `MyApp.Audit` plug fence, lane pointers, optional sigra-reference subsection, collapsed §6 curl
- `guides/upgrade-path.md` — four-lane Who-this-guide-is-for bullet
- `test/threadline/getting_started_saas_doc_contract_test.exs` — neutrality asserts, scoped sigra fence test

**121-02 (README/evaluator discovery + phx contract)**

- `README.md` — four-lane Start here, grouped Phoenix auth reference bullet, Documentation section ordering
- `guides/evaluating-threadline.md` — phx-gen-auth link, host vs maintainer auth proof split, sigra-reference Track A label
- `test/threadline/readme_doc_contract_test.exs` — four-lane and grouped auth asserts; refute `Using Sigra:`
- `test/threadline/evaluating_threadline_doc_contract_test.exs` — ADOPT-AUTH-02 neutrality test
- `test/threadline/integrations/phx_gen_auth_doc_contract_test.exs` — ADOPT-AUTH-03 guide locks (17 asserts)
- `mix.exs` — `phx_gen_auth_doc_contract_test.exs` registered in `verify.doc_contract`

## Verification

```bash
mix test test/threadline/getting_started_saas_doc_contract_test.exs \
         test/threadline/readme_doc_contract_test.exs \
         test/threadline/evaluating_threadline_doc_contract_test.exs \
         test/threadline/integrations/phx_gen_auth_doc_contract_test.exs
# 31 tests, 0 failures
```

## Factual Accuracy & Security

| Area | Assessment |
|------|------------|
| Auth neutrality posture | §5 opens with host-owned `MyApp.Audit` callbacks; explicit refute of required Sigra before optional subsection; lane table in §6 precedes runnable steps |
| Security teaching | Auth-before-plug contract, `401`/`403` vs `500`/`missing actor` distinction preserved; no real credentials; curl uses `PASTE_FROM_BROWSER` placeholder |
| Four-lane discovery | README Start here, evaluating guide, and upgrade-path Who section consistently name `capture-only`, `phoenix-surface`, `phx-gen-auth-reference`, `sigra-reference` |
| phx contract gate | `phx_gen_auth_doc_contract_test.exs` locks guide markers, host-owned literals, proof paths, and refutes `Threadline.Integrations.Sigra` drift |
| Links | Relative links in changed docs resolve to existing files (`phx-gen-auth.md`, `sigra.md`, `examples/threadline_phoenix/README.md`, etc.) |

No security vulnerabilities or incorrect API claims identified. Documentation-only phase; no executable logic changed.

## Contract Test Correctness

- **Scoped sigra fence test** (`getting_started_saas_doc_contract_test.exs:101-123`): Correctly splits on `getting-started-sigra-reference-fence`, asserts `router_block/0` only in tail, and verifies index ordering (`MyApp.Audit` → marker → Sigra callbacks). Matches D-121-20 intent.
- **README neutrality** (`readme_doc_contract_test.exs:45-66`): Four-lane matrix string, grouped auth bullet, and `refute "Using Sigra:"` are appropriate ADOPT-AUTH-02 locks.
- **Evaluator neutrality** (`evaluating_threadline_doc_contract_test.exs:45-54`): Covers phx guide link, lane literals, and host-vs-maintainer proof split.
- **mix.exs wiring**: `phx_gen_auth_doc_contract_test.exs` appended to `verify.doc_contract`; consistent with existing alias pattern.

## Findings

### INFO-1 — Getting-started contract omits several ADOPT-AUTH-01 literals

**Severity:** Info  
**File:** `test/threadline/getting_started_saas_doc_contract_test.exs`

The main walkthrough test locks `MyApp.Audit` hero wiring and refutes `"The Phoenix example keeps"`, but does not assert other neutrality strings present in the guide and called out in plan acceptance criteria:

- `Threadline does not require Sigra`
- `sigra-reference example app only`
- `phx-gen-auth-reference` lane pointer in §5
- `<details>` / `Runnable curl — sigra-reference example app only` collapse label

The scoped sigra fence test covers ordering and router excerpt placement, but a partial revert of §5/§6 neutrality prose could slip through CI. **Fix (optional):** add 3–4 `String.contains?/2` asserts to the main test or a dedicated `"getting-started auth neutrality literals"` test.

### INFO-2 — §6 cookie staging visible outside collapsed sigra block

**Severity:** Info  
**File:** `guides/getting-started-saas.md` (lines 169–173)

The runnable curl is correctly collapsed in `<details>`, but the paragraph immediately below still exposes `_threadline_phoenix_key`, `/users/log_in`, and DevTools copy steps in open §6 prose. It is labeled "reference app" and links the example README as SSOT (per D-121-11), so this is intentional — not a correctness bug. phx-lane adopters routed via the §6 lane table may still skim sigra-specific cookie steps before reaching their guide. **Fix (optional):** move cookie staging prose inside `<details>` or reduce to a one-line README link for stricter D-121-12 adherence.

## Positive Notes

- Two-tier §5 model (universal contract → lane pointers → optional sigra fence) executes phase intent cleanly.
- HTML `<details>` de-emphasis for sigra curl is a reasonable hexdocs-friendly choice.
- README grouped bullet `"Phoenix auth (reference lanes, pick one)"` replaces isolated Sigra-first discovery without hiding reference lanes.
- Evaluating guide correctly splits host-owned staging proof from maintainer CI-class proof paths.
- All phase 121 doc-contract tests pass; no regressions in neutrality wiring or discovery links.
