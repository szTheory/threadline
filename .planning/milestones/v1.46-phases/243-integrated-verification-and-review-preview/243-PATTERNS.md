# Phase 243: Integrated verification and review preview — Pattern Map

**Mapped:** 2026-10-11
**Files analyzed:** 10 likely new or modified files/contracts
**Analogs found:** 9 / 10 (the machine-specific preview receipt has no tracked analog)

The phase should compose the current required browser lane, existing E2E evidence custody, and the Phase 238 local preview into a candidate-level review. These targets are inferred from `243-RESEARCH.md`; the planner should keep the change set minimal and avoid adding a CI job or dependency.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `.github/workflows/ci.yml` | config / CI workflow | batch | `test/threadline/browser_full_projects_contract_test.exs` (workflow contract), existing workflow browser job | role-match |
| `examples/threadline_phoenix/e2e/support/operator-journey-inventory.json` (or equivalent small inventory) | config / test fixture | transform | `test/fixtures/operator_surface/route-inventory.json` | role-match |
| `examples/threadline_phoenix/e2e/support/operator-ci-evidence.ts` (or equivalent receipt helper) | utility | transform | `operator-evidence-manifest.ts` | role-match |
| `examples/threadline_phoenix/e2e/support/operator-ci-evidence.test.ts` (or extend manifest tests) | test | transform | `operator-evidence-manifest.test.ts` | exact |
| `test/threadline/browser_journey_evidence_contract_test.exs` (or extend existing browser project contract) | test | batch | `browser_full_projects_contract_test.exs` | exact |
| `examples/threadline_phoenix/e2e/playwright.config.ts` | config | request-response / browser execution | existing config and `operator-page-capture.spec.ts` project setup | exact |
| `examples/threadline_phoenix/e2e/run-e2e.sh` | utility / process orchestration | batch, file-I/O | existing evidence preflight and guarded preview lifecycle | exact |
| `examples/threadline_phoenix/e2e/support/operator-evidence-manifest.ts` | service / manifest serializer | transform, file-I/O | same manifest implementation; extend `candidateIdentity` and manifest schema | exact |
| `.planning/phases/243-integrated-verification-and-review-preview/243-EVIDENCE-INDEX.md` (plus bounded visual findings/dispositions) | documentation / evidence index | transform | `238-EVIDENCE-INDEX.md`; validation structure in `242-VALIDATION.md` | role-match |
| `.planning/phases/243-integrated-verification-and-review-preview/243-PREVIEW-RECEIPT.json` (local runtime output, if retained) | config / runtime receipt | file-I/O | No tracked analog; Phase 238 receipt is intentionally local/ignored | no tracked analog |

The three CI/evidence helper paths above are illustrative names, not existing files or fixed API decisions. Keep any journey inventory and receipt logic in the existing ExUnit/Node/Playwright stack. The final evidence index is the durable record; raw images and the process-bound preview receipt remain local artifacts.

## Pattern Assignments

### `.github/workflows/ci.yml` and journey-to-test inventory (config, batch/transform)

**Analogs:** `test/threadline/browser_full_projects_contract_test.exs`; `examples/threadline_phoenix/e2e/playwright.config.ts` lines 22–24, 110–132; `.github/workflows/ci.yml` lines 951–979, 1075–1125.

Keep the existing `verify-example-browser` job and stable job IDs. It invokes the named Mix entrypoint with the required desktop and mobile projects:

```yaml
# .github/workflows/ci.yml:1075-1077
- name: Run example Playwright suite
  timeout-minutes: 14
  run: mix verify.example_browser --project=desktop-chromium --project=mobile-chromium
```

The existing ExUnit project contract demonstrates executable reconciliation rather than prose-only expectations: it loads `--list` outputs, checks the configured project set, and verifies CI and Browser-full partition those projects without gaps or overlap.

```elixir
# test/threadline/browser_full_projects_contract_test.exs:122-124
test "--list ci is the projects ci.yml runs, including those behind mix verify.capture" do
  assert list!("ci") == @live_ci
end
```

Add expected journey identities against Playwright's native discovered list and executed JSON report in this style. Validate missing, filtered, skipped, zero-test, absent-report and project-drift cases. Preserve the required CI gate's `if: always()` and complete `needs` result inspection. Treat names as identities, not counts: the project's project list can evolve while required journey coverage remains stable.

### `examples/threadline_phoenix/e2e/support/operator-ci-evidence.ts` and its tests (utility/test, transform)

**Analogs:** `examples/threadline_phoenix/e2e/support/operator-evidence-manifest.ts` and `operator-evidence-manifest.test.ts`.

The manifest schema is explicit and typed. It keeps candidate, fixture, rendering conditions and captures separate:

```typescript
// operator-evidence-manifest.ts:30-58
export interface OperatorEvidenceManifest {
  readonly schemaVersion: 1;
  readonly baseSha: string;
  readonly candidateHead: string;
  readonly candidatePaths: readonly string[];
  readonly candidateChanges: readonly { readonly path: string; readonly mode: string; readonly sha256: string }[];
  readonly candidateDiffDigest: string;
  readonly custody: {
    readonly receiptSha256: string;
    readonly acceptedReceiptSha256: string;
    readonly acceptedEvidenceIndexSha256: string;
    readonly acceptedHead: string;
    readonly forwardTaskCommits: readonly string[];
  };
  readonly fixture: {
    readonly scenario: string;
    readonly version: string;
    readonly seedManifestSha256: string;
    readonly semanticId: string;
  };
  readonly route: string;
  readonly state: string;
  readonly actor: { readonly role: string; readonly scope: string };
  readonly appearance: { readonly effectiveTheme: string; readonly preference: string };
  readonly browser: { readonly playwright: string; readonly browser: string };
  readonly viewport: { readonly width: number; readonly height: number; readonly deviceScaleFactor: number };
  readonly input: { readonly motion: string; readonly zoom: number };
  readonly captures: readonly OperatorCapture[];
}
```

`candidateIdentity()` gathers committed, staged, unstaged and untracked paths, filters inputs, hashes file bytes, and hashes the resulting entries. Extend its allowlist to include the evidence-producing CI workflow, `bin/` helpers and relevant CI contract tests, as research identifies; otherwise those changes can escape the candidate digest.

```typescript
// operator-evidence-manifest.ts:160-164
const committed = git(["diff", "--name-only", "-z", baseSha, "HEAD"]).split("\0");
const staged = git(["diff", "--cached", "--name-only", "-z"]).split("\0");
const unstaged = git(["diff", "--name-only", "-z"]).split("\0");
const untracked = git(["ls-files", "--others", "--exclude-standard", "-z"]).split("\0");
const paths = [...new Set([...committed, ...staged, ...unstaged, ...untracked]
  .filter((path) => path && relevant(path)))].sort();
```

Preserve strict receipt metadata controls: allowlisted scalar keys, bounded strings, rejection of secret-looking field names, and synthetic canary scanning. Tests should use table-driven invalid cases and assert that invalid receipts fail closed.

```typescript
// operator-evidence-manifest.test.ts:88-103
test("metadata proof rejects credential fields and unknown metadata", () => {
  for (const key of ["password", "cookie", "authorization", "accessToken", "secret", "credentials", "api_key", "notes"]) {
    assert.throws(() => serializeManifest({ ...valid(), [key]: "must not be persisted" }), /secret|field|metadata/i, key);
  }
});
```

For CI evidence, retain expected/discovered/executed identities, statuses, intentional skips and counts, with job/run/source identity. Do not serialize browser cookies, storage state, credentials, unfiltered environment data or arbitrary reporter payloads.

### `test/threadline/browser_journey_evidence_contract_test.exs` (test, batch)

**Analog:** `test/threadline/browser_full_projects_contract_test.exs`.

Follow its live-repository contract style: obtain the canonical Playwright list through the repo script/helper, compare it to the workflow's declared projects, and emit a concrete assertion message explaining what contract drifted. Keep the new test independent and side-effect-light; use `async: true` where the tested process/filesystem isolation allows. Existing `test/threadline/e2e_preflight_contract_test.exs` is also a strong adversarial example: it creates isolated fixtures, uses a sentinel to prove rejected input does not start Playwright, and covers hostile redirects, missing/multiple headers and shell-marker failures (lines 35–105, 108–125). Use that negative-control approach for forged/missing coverage receipts rather than only testing a valid sample.

### `examples/threadline_phoenix/e2e/playwright.config.ts` and capture specs (config/test, browser request-response)

**Analogs:** `playwright.config.ts` lines 22–24 and 134–161; `examples/threadline_phoenix/e2e/tests/operator-page-capture.spec.ts` (route-capture lane); `examples/threadline_phoenix/e2e/support/operator-browser-evidence.ts`.

Existing browser projects are named explicitly, use deterministic viewport and reduced-motion setup, and select capture specs through `testMatch`. Keep those settings local to a project when possible; do not perturb the existing broad suite or accepted snapshots. Research calls for fresh candidate captures of the full shell; the current route-capture project documents clipping to `#tl-main`, so create/use a dedicated full-shell path or adjust only the candidate evidence lane rather than relabeling content crops as shell evidence. Store outputs under a fresh ignored run directory; do not enable snapshot update mode or write the Phase 238 baseline.

### `examples/threadline_phoenix/e2e/run-e2e.sh` (utility, batch and file-I/O)

**Analog:** `examples/threadline_phoenix/e2e/run-e2e.sh` lines 77–100, 141–168, 181–218, 270–292.

The evidence runner validates before destructive actions: fresh partition syntax, loopback DB and HTTP host, valid ports, absence of `DATABASE_URL`/reset overrides, exact test DB derivation, unused DB, and unused output path. It creates partition-specific caches and artifact directories. The stop helper verifies the state-file schema, PID, URL, process cwd, loopback listener and connected DB before signaling; on any mismatch it retains state and sends no signal. Add candidate preview lifecycle only by extending these guards. Verify direct unauthenticated redirect and authenticated deep-link/shell content through existing preflight logic; never follow redirects blindly.

### `243-EVIDENCE-INDEX.md` and validation/evidence ledger (documentation, transform)

**Analogs:** `.planning/phases/238-current-main-preview-and-acceptance-baseline/238-EVIDENCE-INDEX.md` lines 25–45 and 82–100; `.planning/phases/242-export-and-retention-operations/242-VALIDATION.md` lines 16–45, 49–70.

Phase 238's tracked index separates accepted evidence from historical/superseded evidence, records candidate and fixture identity, gives a manifest/output hash table, and states browser limits plainly. Reuse that custody discipline without copying stale values or historical bulk. Phase 242's validation artifact maps each task/requirement to behavior, test type, named command, existence and result; it records measured full-suite results and intentional skips. For Phase 243, the compact index should join CI expected/discovered/executed coverage, baseline and fresh full-shell capture paths/hashes, bounded findings and dispositions, candidate preview receipt pointer, browser/device limitations, and the release-ready recommendation. Distinguish observed evidence from unsupported claims.

The Phase 238 `238-PREVIEW-RECEIPT.json` is a local machine/process artifact and is not git-tracked. Do not use it as a planner source path or copy its machine-specific PID/port/database values. Keep a candidate receipt similarly local/ignored if needed; put reproducible schema/validation logic in tracked source and the durable pointer in the Markdown index.

## Shared Patterns

### Candidate and artifact custody

**Sources:** `operator-evidence-manifest.ts` lines 148–173; `run-e2e.sh` lines 77–100 and 152–168; Phase 238 `238-EVIDENCE-INDEX.md` lines 29–45.

Hash effective staged, unstaged, committed and untracked inputs relevant to product and evidence production. Hash served JS/CSS and capture outputs; include fixture semantic identity and actual browser/Playwright versions. Use unique ignored output directories. A SHA-256 detects changes but is not a signed/tamper-proof attestation.

### Fail-closed handling and privacy

**Sources:** `operator-evidence-manifest.ts` lines 95–138; `run-e2e.sh` lines 181–218; `test/threadline/e2e_preflight_contract_test.exs` lines 35–105.

Allowlist receipt fields, reject secrets and unknown metadata, scan synthetic canaries, and use synthetic data only. Reject stale or mismatched process/database ownership without signaling or deleting state. Negative tests should prove rejected inputs do not start browser work or affect unrelated processes.

### CI and verification contracts

**Sources:** `test/threadline/browser_full_projects_contract_test.exs` lines 116–178; `.github/workflows/ci.yml` lines 1075–1125; `242-VALIDATION.md` lines 28–45.

Use named `mix verify.*` entrypoints, preserve CI job IDs, and test discovered project/test identity against live repo configuration. Treat discovery and execution as separate facts. Keep the required aggregate check's always-run semantics and report intentional skips/unsupported browser capabilities explicitly.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| Local `243-PREVIEW-RECEIPT.json` runtime output | runtime receipt | file-I/O | Phase 238's comparable receipt is machine-specific and ignored; there is no tracked receipt file to copy. Reuse the tracked runner/schema validation patterns instead. |

## Metadata

**Analog search scope:** `examples/threadline_phoenix/e2e/`, `test/threadline/`, `.github/workflows/`, `.planning/phases/238-*`, `.planning/phases/242-*`.
**Files scanned:** 10 focused analogs/contracts.
**Pattern extraction date:** 2026-10-11.
