# Phase 189: Quality Baseline and Authority-Surface Audit - Pattern Map

**Mapped:** 2026-07-01
**Files analyzed:** 1 implementation artifact
**Analogs found:** 1 / 1 target file

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.planning/phases/189-quality-baseline-and-authority-surface-audit/189-QUALITY-AUDIT.md` | documentation / planning audit artifact | batch, transform | `.planning/milestones/v1.38-phases/181-baseline-audit-and-guard-repair/181-BASELINE-AUDIT.md` | role-match |

Source files should not be modified in Phase 189. The implementation artifact is the audit Markdown file above; this pattern map is the planning input for that file.

## Pattern Assignments

### `.planning/phases/189-quality-baseline-and-authority-surface-audit/189-QUALITY-AUDIT.md` (documentation audit, batch transform)

**Primary analog:** `.planning/milestones/v1.38-phases/181-baseline-audit-and-guard-repair/181-BASELINE-AUDIT.md`

**Secondary analogs:**

- `.planning/milestones/v1.38-MILESTONE-AUDIT.md` - prior milestone audit frontmatter, closeout evidence, and residual table
- `.planning/milestones/v1.38-phases/188-close-gap-v1-38-export-queue-and-motion-validation/188-VERIFICATION.md` - goal-backward verification and proof-limit reporting
- `.planning/milestones/v1.38-phases/188-close-gap-v1-38-export-queue-and-motion-validation/188-VALIDATION.md` - validation-command and per-task verification-map shape
- `.planning/milestones/v1.38-phases/188-close-gap-v1-38-export-queue-and-motion-validation/188-UI-SPEC.md` - UI/design contract structure and scope-boundary language

**Locked Phase 189 artifact contract** (from current `189-UI-SPEC.md` lines 119-145):

```markdown
## Audit Artifact Contract

The executor-facing artifact is `.planning/phases/189-quality-baseline-and-authority-surface-audit/189-QUALITY-AUDIT.md`.

Required structure:

1. YAML frontmatter with phase, artifact type, audited date, requirements, status, and source precedence.
2. Short executive summary: no more than six bullets, weakest risks first.
3. Ranked Evidence Ledger: one table sorted weakest/highest-risk first.
4. QUAL-03 Residuals: one table covering every required residual.
5. Good Enough / N/A Appendix: visible, not hidden or implied.
6. v1.39 Narrowing: which findings route to Phase 190, 191, 192, 193, future, external, or none.
```

**Scoring contract** (from current `189-CONTEXT.md` lines 22-31):

```markdown
- **D-189-01:** Phase 189 should produce one ranked Markdown audit artifact with YAML frontmatter and a weakest-first evidence ledger.
- **D-189-02:** Use score `0-4`, with confidence kept separate:
  - `0` = unknown, unproven, or broken trust boundary
  - `1` = must-fix adoption, operations, release, or maintainer risk
  - `2` = workable with material residual
  - `3` = good enough for current claims
  - `4` = strong/proven
- **D-189-03:** Every scored row must include: quality dimension, evidence refs, confidence, practical consequence, highest-leverage fix, priority, route bucket, and owner phase.
- **D-189-05:** Include a QUAL-03 residual table covering at minimum SEED-005/reconnect, screenshot-regression confidence, external pilot boundaries, host staging ownership, known CI/example-app residuals, Hex/dependency notes, and legacy Nyquist/planning residuals.
```

**Frontmatter pattern** (from `181-BASELINE-AUDIT.md` lines 1-11):

```yaml
---
phase: 181-baseline-audit-and-guard-repair
date: 2026-06-26
status: baseline-packet-verified
requirements: [BASE-01, BASE-02, BASE-03]
evidence_tiers:
  tier_a: source/CI contracts for route, auth, feature-gate, stress, ledger, and fixture truth
  tier_b: rendered CI slices for overflow, navigation, header, and selected responsive cells
  tier_c: local screenshot packet under .planning/phases/181-baseline-audit-and-guard-repair/screenshots
source_decisions: [D-181-01, D-181-02, D-181-03, D-181-07, D-181-08, D-181-09, D-181-10, D-181-11, D-181-12, D-181-13, D-181-14, D-181-15, D-181-16]
---
```

For Phase 189, adapt this to `phase: 189`, `artifact: quality-audit`, `audited: 2026-07-01`, `requirements: [QUAL-01, QUAL-02, QUAL-03]`, and `source_precedence:` entries for runtime, release, public docs, CI, and planning.

**Scope and no-scope-creep pattern** (from `181-BASELINE-AUDIT.md` lines 13-16):

```markdown
# Phase 181 Baseline Audit Packet

This packet records current rendered truth for the mounted `/audit` operator surface before v1.38 page polish starts. It is a planning artifact, not a redesign brief: findings are classified for later phases and guard repair, while page hierarchy, route paths, feature gates, public component APIs, capture/query/auth semantics, root dependencies, and design-system ratchets remain unchanged.
```

Apply this shape directly: `189-QUALITY-AUDIT.md` should say it is a repo-evidence quality baseline and routing artifact, not an implementation phase for schema, docs, CI, UI, compliance, or external pilot fixes.

**Evidence taxonomy pattern** (from `181-BASELINE-AUDIT.md` lines 17-34):

```markdown
## Evidence Contract

- **D-181-01:** Phase 181 evidence is an audit packet, not a screenshot dump.
- **D-181-03:** Every finding uses one of the shared issue taxonomy buckets below.
- **D-181-07:** Evidence is tiered: source/CI contracts, rendered CI slices, and local screenshot packet proof.

## Issue Taxonomy

| Bucket | Meaning | Default Owner |
|---|---|---|
| JTBD/IA drift | The page exists and renders, but task order, hierarchy, or destination framing needs page-polish work. | 183-186 |
| screenshot or ledger drift | Screenshot inventory, stress ledger, projection, or allowlist evidence may not match current rendered truth. | 181-06, 181-07, 181-08 |
| route/auth/feature-gate invariant gap | Route, auth, export, policy, evidence, coverage, stress, or optional-dependency boundaries need source proof. | 181-05 |
| later-phase polish follow-up | Finding is real but intentionally deferred because fixing it would be page IA, copy, layout, or visual polish. | 183-187 |
```

For Phase 189, replace the bucket set with the locked taxonomy from `189-CONTEXT.md`: `Blocker`, `Must fix before publish`, `Prove before claim`, `External-owned`, `Maintenance note`, `Backlog cleanup`, `Future seed`, `Good enough`, and `N/A`.

**Ranked ledger / routing table pattern** (from `181-BASELINE-AUDIT.md` lines 50-75):

```markdown
## Page/JTBD Matrix

| Surface | Route or selector source | Primary JTBD | Current render proof expected from screenshot task | Issue taxonomy bucket | Guard disposition | Later-phase owner |
|---|---|---|---|---|---|---|
| Shell/global nav | `SurfaceHeader.surface_header/1`; `data-testid="operator-header"` and `data-testid="operator-nav-shell"`; nav links ... | Know where I am, what destinations exist, and what is currently active. | All Tier C page screenshots include the shell; Tier B responsive slices cover 375/768/1024 Shell/Home/Timeline/Coverage and Phase 178 320/1440 route sweep. | JTBD/IA drift; accessibility/focus/motion proof gap; route/auth/feature-gate invariant gap | Preserve nav route/test-id contract; audit current active-state, feature-gated visibility, skip link, mobile `details` disclosure, and theme picker proof before Phase 183. | 183 |

## Later-Phase Ownership

| Owner | Surfaces | Current Plan 01 Disposition |
|---|---|---|
| 183 | Shell/global nav, Home `/audit` | Audit route/render evidence and record IA risks; no hierarchy, CTA, or copy rewrite. |
| 187 | Accessibility, motion, docs, adversarial closeout | Consume proof gaps from this packet and close with final verification. |
```

For Phase 189, use one dense `Ranked Evidence Ledger` with exact columns from the UI spec: Rank, Quality dimension, Score, Confidence, Evidence refs, Practical consequence, Highest-leverage fix, Priority, Route bucket, Owner phase.

**Closeout evidence and residual table pattern** (from `v1.38-MILESTONE-AUDIT.md` lines 38-47 and 81-90):

```markdown
## Closeout Evidence

| Evidence | Result |
|---|---|
| `188-VERIFICATION.md` | Records exact Phase 188 command evidence, requirement closure table, proof limits, and residual classifications. |
| Targeted Phase 188 bundle | `mix test ...` passed: 92 tests, 0 failures. |
| Full project test alias | `mix verify.test` passed: 1197 tests, 0 failures, 1 excluded. |

## Residual Tech Debt

| Area | Residual | Owner / Scope | Impact | Next Action |
|---|---|---|---|---|
| Broad CI | Earlier v1.38 artifacts recorded non-green `mix ci.all` / example-app residuals. | Broad CI/example-app maintenance, outside Phase 188. | Phase 188 targeted and `mix verify.test` proof is green; release readiness still needs the chosen release gate. | Address in a dedicated CI/example-app maintenance phase if release policy requires it. |
| Screenshots | Phase 187 standalone screenshot regression command failed before comparison while waiting for login form. | Screenshot/local browser baseline lane, outside Phase 188. | No broad visual stability claim is made from that command. | Re-run or fix screenshot login setup if broad screenshot stability is required. |
```

For Phase 189, the QUAL-03 residual table should copy this residual shape but use required residual rows: SEED-005/reconnect, screenshots, external pilot, host staging, CI/example-app, Hex/dependency, and legacy Nyquist/planning residuals.

**Verification evidence pattern** (from `188-VERIFICATION.md` lines 28-49 and 87-95):

```markdown
## Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | TIME-01: A queued Timeline export with persisted string-keyed `from`/`to` params completes with rows bounded by the operator's current-view date window. | VERIFIED | `test/threadline/export/orchestrator_test.exs:45` inserts inside/outside rows, runs `Orchestrator.run/2`, and asserts the stored CSV includes only inside-window rows. Targeted bundle passed. |
| 16 | D-188-18..D-188-21: Closeout uses focused verification, browser proof only if actually modified, GOV-02 metadata cleanup, and explicit audit classification. | VERIFIED | Targeted ExUnit and `mix verify.test` passed; `mix verify.example_browser` was not required because no browser proof changed; metadata and audit artifacts are present. |

**Score:** 16/16 truths verified, 0 present-but-behavior-unverified.

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Phase 188 targeted worker/LiveView/parser/style bundle passes. | `mix test ...` | 92 tests, 0 failures. Seed `541003`. | PASS |
```

For Phase 189, do not claim command evidence unless the executor reruns or records the command output. If a row cites only static repo evidence, make that explicit in Evidence refs and Confidence.

**Validation command pattern** (from current `189-VALIDATION.md` lines 17-24 and 40-44):

```markdown
| Property | Value |
|----------|-------|
| **Framework** | Static Markdown validation with `rg`, plus targeted Mix/ExUnit proof only when the audit cites fresh command evidence. |
| **Quick run command** | `test -f .../189-QUALITY-AUDIT.md && rg -n "Ranked Evidence Ledger|Score|Confidence|Practical consequence|Highest-leverage fix|Owner phase|QUAL-03|Good Enough|N/A|v1.39" .../189-QUALITY-AUDIT.md` |
| **Full suite command** | `git diff --check && rg -n "Blocker|Must fix before publish|Prove before claim|External-owned|Maintenance note|Backlog cleanup|Future seed|Good enough|N/A|SEED-005|reconnect|screenshot|external pilot|host staging|CI/example|Hex|dependency|Nyquist|planning residual" .../189-QUALITY-AUDIT.md` |

| 189-01-04 | 01 | 1 | QUAL-01/02/03 | T-189-01 / T-189-02 / T-189-03 | Any fresh command evidence cited in the audit is reproducible from named commands, not implied by prose. | targeted proof | `mix verify.doc_contract && mix test test/threadline/ci_topology_contract_test.exs test/threadline/adoption_pilot_doc_contract_test.exs test/threadline/release_artifact_contract_test.exs` when those surfaces are cited as current proof | existing | pending |
```

**UI/design artifact pattern** (from current `189-UI-SPEC.md` lines 190-214):

```markdown
## Visual Hierarchy For `189-QUALITY-AUDIT.md`

- First screen: title, scope sentence, and weakest-three summary. No hero, marketing copy, or decorative visuals.
- Ledger: single dense table with exact columns from this spec. Use Markdown links/paths, not paragraphs of narrative.
- Residuals: separate table so seeds and proof limits do not pollute the ranked ledger.
- Appendix: good-enough and N/A rows must be scan-friendly and short.
- Screenshots: not part of Phase 189 output. If future proof is routed, record it as `Future seed` or the owner phase, not as work done now.

## Validation Contract

Static checks should prove the audit artifact contains the required contract, not that UI work happened.
```

## Shared Patterns

### Authority Hierarchy

**Source:** current `189-CONTEXT.md` lines 35-41  
**Apply to:** every ledger row and every residual row

```markdown
- **D-189-06:** Use an evidence-first, scope-aware hierarchy. Planning defines what must be audited, but current-tree proof decides what is true.
- **D-189-07:** For runtime/source behavior claims, executable proof wins: source code, focused tests, named `mix verify.*` / `mix ci.*` bundles, current CI job behavior, and clean-tree verification evidence outrank prose and stale planning metadata.
- **D-189-08:** For release/version/package claims, `mix.exs`, `.release-please-manifest.json`, CHANGELOG/release metadata, Hex package truth, Release Please wiring, and doc-contract-guarded public docs must be reconciled.
- **D-189-12:** Prefer named rerun bundles and `VERIFICATION.md`/`VALIDATION.md` evidence over audit prose when closing requirements.
```

### Route Buckets And Narrowing

**Source:** current `189-CONTEXT.md` lines 45-64  
**Apply to:** `Priority`, `Route bucket`, `Owner phase`, `QUAL-03 Residuals`, and `v1.39 Narrowing`

```markdown
- **D-189-13:** Use this trust-boundary taxonomy: `Blocker`, `Must fix before publish`, `Prove before claim`, `External-owned`, `Maintenance note`, `Backlog cleanup`, `Future seed`, `Good enough`, and `N/A`.
- **D-189-23:** Use the authority-surface gate as the Phase 189 narrowing rule: a finding may constrain phases 190-193 only if it is backed by repo evidence and affects a current adoption, production, support, release, or maintainer authority surface already promised by v1.39.
- **D-189-24:** Route findings as:
  - `Must-fix now` if a current public claim, release gate, storage-schema contract, CI trust claim, or security/correctness invariant is false and cannot be honestly narrowed.
  - `Phase-owned` if it maps cleanly to SCHEMA in Phase 190, ADOPT in Phase 191, CI in Phase 192, or CLOSE in Phase 193.
  - `Future seed` if it is real but scope-expanding.
  - `N/A` / `Good enough` if the dimension is out of category, already proven for current claims, or intentionally unclaimed.
```

### Named Mix Proof Bundles

**Source:** `mix.exs` lines 77-110 and 124-133  
**Apply to:** runtime/source, docs, example-app, release, and CI ledger rows

```elixir
"verify.format": ["format --check-formatted"],
"verify.credo": ["credo --strict"],
"verify.test": ["test"],
"verify.threadline": ["threadline.verify_coverage"],
"verify.doc_contract": [
  "test test/threadline/readme_doc_contract_test.exs ... test/threadline/production_checklist_doc_contract_test.exs"
],
"verify.release": &verify_release/1,
"verify.example": &verify_example/1,
"verify.example_browser": &verify_example_browser/1,
"verify.compile_no_optional": ["compile --no-optional-deps --warnings-as-errors"],
"ci.all": [
  "verify.format",
  "verify.credo",
  "compile --warnings-as-errors",
  "verify.compile_no_optional",
  "verify.test",
  "verify.threadline",
  "verify.example",
  "verify.doc_contract",
  "verify.example_browser"
]

defp verify_release(_args) do
  ensure_clean_tree!()

  [
    "bin/verify-release-shape",
    "mix test test/threadline/release_artifact_contract_test.exs test/threadline/ci_topology_contract_test.exs",
    "MIX_ENV=dev mix docs",
    "mix hex.build"
  ]
  |> Enum.each(&run_release_step!/1)
end
```

### CI Job Id And Gate Pattern

**Source:** `.github/workflows/ci.yml` lines 1-21, 99-121, 270-307, and 345-352  
**Apply to:** CI gate trust, release readiness, branch protection, and maintainer trust rows

```yaml
# Job id contract — stable YAML `jobs:` keys are relied on by docs and `act`:
# verify-format, verify-credo, verify-compile-no-optional, verify-test, verify-pgbouncer-topology, verify-hex-evaluator, verify-example-browser, verify-docs, verify-hex-package, verify-release-shape

jobs:
  verify-format:
    name: Check formatting

      - name: Run tests
        run: mix verify.test
      - name: Verify Threadline trigger coverage
        run: mix verify.threadline
      - name: Verify Threadline Phoenix example
        run: mix verify.example
      - name: Doc contract tests
        run: mix verify.doc_contract

  verify-docs:
    name: Build ExDoc (dev)
      - name: Build docs
        run: mix docs

  verify-hex-package:
    name: Hex package tarball
      - name: Build and inspect Hex tarball
        run: |
          set -euo pipefail
          mix hex.build

  verify-release-shape:
    name: Release metadata (version / changelog)
      - name: Verify CHANGELOG and @version alignment
        run: bin/verify-release-shape
```

### CI Topology Contract Tests

**Source:** `test/threadline/ci_topology_contract_test.exs` lines 11-21, 70-109, and 112-125  
**Apply to:** CI topology, `ci.all`, support-lane proof, branch-protection, and host STG rows

```elixir
test "ci.yml defines PgBouncer topology job with transaction pool and mix verify.topology" do
  yaml = read_rel!([".github", "workflows", "ci.yml"])

  assert String.contains?(yaml, "verify-pgbouncer-topology:")
  assert String.contains?(yaml, "POOL_MODE: transaction")
  assert String.contains?(yaml, "THREADLINE_PGBOUNCER_TOPOLOGY: \"1\"")
  assert String.contains?(yaml, "mix verify.topology")
end

test "ci.all keeps capture-only and phoenix-surface proof steps in order" do
  mix_exs = read_rel!(["mix.exs"])
  assert pos_compile_strict < pos_compile_no_optional
  assert pos_compile_no_optional < pos_verify_test
  assert pos_verify_test < pos_verify_threadline
  assert pos_verify_threadline < pos_verify_example
  assert pos_verify_example < pos_verify_doc_contract
end

test "verify-test job runs the phoenix-surface and sigra-reference proof path" do
  yaml = read_rel!([".github", "workflows", "ci.yml"])
  assert String.contains?(yaml, "run: mix verify.test")
  assert String.contains?(yaml, "run: mix verify.threadline")
  assert String.contains?(yaml, "run: mix verify.example")
  assert String.contains?(yaml, "run: mix verify.doc_contract")
end
```

### Release And Package Truth

**Sources:** `mix.exs` lines 4 and 124-133; `.release-please-manifest.json` lines 1-3; `release-please-config.json` lines 13-20; `test/threadline/adoption_pilot_doc_contract_test.exs` lines 19-45; `test/threadline/release_artifact_contract_test.exs` lines 83-99  
**Apply to:** release/version/package drift, Phase 191 routing, and `Must fix before publish` rows

```elixir
@version "0.9.0"

test "release-please is wired to auto-bump the SSOT preflight line (no manual prep)" do
  ssot_line =
    @guide
    |> File.read!()
    |> String.split("\n")
    |> Enum.find(&String.starts_with?(&1, "Distribution preflight below reflects the "))

  assert String.contains?(ssot_line, "x-release-please-version")
  config = File.read!(@release_please_config)
  assert String.contains?(config, "extra-files") and String.contains?(config, @guide)
end

test "README carries only the release-scoped installer and routing literals" do
  readme = File.read!("README.md")
  assert String.contains?(readme, "{:threadline, \"~> 0.6\"}")
end

test "CONTRIBUTING carries the release pre-flight and release workflow literals" do
  doc = File.read!("CONTRIBUTING.md")
  assert String.contains?(doc, "mix verify.release")
  assert String.contains?(doc, ".github/workflows/release.yml")
  assert String.contains?(doc, "workflow_dispatch")
  assert String.contains?(doc, "v0.6.0")
end
```

```json
{
  ".": "0.9.0"
}
```

```json
"packages": {
  ".": {
    "changelog-path": "CHANGELOG.md",
    "include-v-in-tag": true,
    "extra-files": [
      {"type": "generic", "path": "guides/adoption-pilot-backlog.md"}
    ]
  }
}
```

### Contributor Gate, Branch Protection, And Release Runbook

**Source:** `CONTRIBUTING.md` lines 53-69, 116-131, 164-183, and 189-199  
**Apply to:** gate readiness, branch-protection, host staging, and release-owner rows

```markdown
4. Run the full local gate (same steps CI runs, modulo Postgres). The project sets **`preferred_envs: ["ci.all": :test]`** in `mix.exs`.

Command: `MIX_ENV=test mix ci.all`

GitHub Actions workflow: `.github/workflows/ci.yml`. Stable job keys do not rename; used by docs, `act`, and branch protection:

| Job key | Purpose |
|---------|---------|
| `verify-format` | `mix verify.format` |
| `verify-credo` | `mix verify.credo` |
| `verify-compile-no-optional` | `mix verify.compile_no_optional` |
| `verify-test` | compile `--warnings-as-errors` + `mix verify.test` |
| `verify-pgbouncer-topology` | Postgres + **PgBouncer (`POOL_MODE=transaction`)** |
| `verify-docs` | `MIX_ENV=dev` - `mix docs` |
| `verify-hex-package` | `mix hex.build` + assert tarball contains `lib/` |
| `verify-release-shape` | `bin/verify-release-shape` |
```

Host STG is integrator-owned; cite `CONTRIBUTING.md:164` for the explicit rule that long-form evidence stays in integrator-controlled artifacts.

### Screenshot Regression Boundary

**Source:** `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts` lines 76-97 and `v1.38-MILESTONE-AUDIT.md` lines 87-90  
**Apply to:** screenshot-regression confidence row and QUAL-03 residual row

```typescript
test.describe("operator screenshot regression guard", () => {
  test.skip(
    !!process.env.CI,
    "visual screenshot baselines are platform-sensitive; run this guard locally before updating PNG snapshots",
  );

  test.beforeEach(async ({ page }, testInfo) => {
    test.skip(testInfo.project.name === "chromium", "fixed guard runs on desktop/mobile projects");
    // desktop-chromium-light ... CI-skip above keeps it local-only.
  });
});
```

```markdown
| Screenshots | Phase 187 standalone screenshot regression command failed before comparison while waiting for login form. | Screenshot/local browser baseline lane, outside Phase 188. | No broad visual stability claim is made from that command. | Re-run or fix screenshot login setup if broad screenshot stability is required. |
```

Default classification should be `Prove before claim` unless the executor records a passing, intentionally bounded local screenshot run.

### SEED-005 Reconnect / Offline Proof

**Sources:** `lib/threadline/operator_surface/ui.ex` lines 1081-1108 and 1111-1179; `examples/threadline_phoenix/e2e/tests/operator-phase-178-uat.spec.ts` lines 263-320 and 564-575  
**Apply to:** SEED-005/reconnect row, operator trust row, and good-enough/future-seed decision

```elixir
# Reconnect / offline banner ... hidden by default and revealed PURELY in CSS while the `[data-phx-main]`
# container carries LiveView lifecycle classes ...
def reconnect_banner(assigns) do
  ~H"""
  <div class={["tl-reconnect-banner", @class]} role="status" {@rest}>
    <Icon.icon name={:refresh} class="tl-alert__icon" />
    <span>Reconnecting…</span>
  </div>
  """
end

# SEED-005 / D-10: the single shared shell/chrome for ALL 11 operator LiveViews.
def shell(assigns) do
  ~H"""
  <div class="threadline-ui" data-tl-theme={@theme}>
    ...
    <.reconnect_banner />
    <main id="tl-main" class={@main_class} tabindex="-1" {@main_rest}>
  """
end
```

```typescript
// SEED-005 / D-13: prove a REAL socket drop is detected client-side ...
test("a real dropped live socket reveals the banner and dims mutating controls (D-13)", async ({ page }) => {
  await page.routeWebSocket(/\/live\/websocket/, (ws) => {
    if (blockSocket) {
      ws.close();
    } else {
      ws.connectToServer();
    }
  });

  await page.goto("/audit/policy/retention");
  await openPruneModal(page);

  const banner = page.locator(".tl-reconnect-banner").first();
  const mutating = page.locator(`${PRUNE_CONTENT} [data-tl-mutating]`).first();
  await expect(banner).toBeHidden();
  await expect(mutating).toBeVisible();

  blockSocket = true;
  await page.evaluate(() => (window as any).liveSocket.disconnect());
  await expect(lvRoot).toHaveClass(/phx-(loading|error|client-error)/);
  await expect(banner).toBeVisible();
  await expect(mutating).toHaveCSS("opacity", "0.55");
  await expect(mutating).toHaveCSS("pointer-events", "none");
});
```

Do not label SEED-005 unimplemented by default. It becomes must-fix only if current real socket-drop proof fails, mutating affordances are unsafe, or the audit proves a trust-impacting operator failure mode.

### Public Docs / Doc Contract Pattern

**Source:** `test/threadline/release_artifact_contract_test.exs` lines 22-37 and 67-99; `test/threadline/adoption_pilot_doc_contract_test.exs` lines 80-98  
**Apply to:** public adopter guidance, docs drift, HexDocs/package surfaces, and Phase 191 rows

```elixir
test "guides on disk match the ExDoc guide extras allowlist" do
  assert guide_extras() == guides_on_disk()
end

test "release package includes the shipped documentation surfaces" do
  files = package_files()
  extras = docs_config()[:extras]

  assert "guides" in files
  assert "README.md" in files
  assert "CHANGELOG.md" in files
  assert "CONTRIBUTING.md" in files
  assert "README.md" in extras
  assert "CONTRIBUTING.md" in extras
  assert "CHANGELOG.md" in extras
end

test "adoption-pilot evidence pass cites canonical verify entrypoints (PILOT-01)" do
  guide = File.read!(@guide)

  assert String.contains?(guide, "mix ci.all")
  assert String.contains?(guide, "mix verify.doc_contract")
  assert String.contains?(guide, "CONTRIBUTING.md")
end
```

### UI Copy And Registry Safety

**Source:** current `189-UI-SPEC.md` lines 88-115  
**Apply to:** artifact prose, appendix wording, and any UI-adjacent row

```markdown
- Say what failed, why it matters, and the next action.
- Name the affected user: adopter, operator, maintainer, release owner, or host integrator.
- Use direct consequence language: "Evaluators see mixed version truth" instead of "documentation risk".
- Avoid vague severity theater and marketing terms such as "enterprise-grade", "robust", "seamless", "powerful", and "next-generation".

Registry contract: Phase 189 must not install UI packages, run `shadcn init`, or introduce third-party UI blocks.
```

## No Analog Found

No target implementation file lacks an analog.

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| None | n/a | n/a | The single target artifact has strong planning-audit and milestone-audit analogs. |

## Metadata

**Analog search scope:** `.planning/**`, `.planning/milestones/**`, `test/threadline/**`, `examples/threadline_phoenix/e2e/**`, `lib/threadline/operator_surface/**`, `.github/workflows/**`, `mix.exs`, release metadata, and contributor docs.

**Files read/excerpted:** 20 primary files:

- Phase inputs: `189-CONTEXT.md`, `189-RESEARCH.md`, `189-VALIDATION.md`, `189-UI-SPEC.md`
- Audit analogs: `v1.38-MILESTONE-AUDIT.md`, `181-BASELINE-AUDIT.md`, `188-VERIFICATION.md`, `188-VALIDATION.md`, `188-UI-SPEC.md`
- Authority surfaces: `mix.exs`, `.github/workflows/ci.yml`, `CONTRIBUTING.md`, `.release-please-manifest.json`, `release-please-config.json`, `ci_topology_contract_test.exs`, `adoption_pilot_doc_contract_test.exs`, `release_artifact_contract_test.exs`, `operator-screenshot-regression.spec.ts`, `operator-phase-178-uat.spec.ts`, `ui.ex`

**Project instructions:** no root `AGENTS.md` found; no project-local `.codex/skills` or `.agents/skills` instructions found.

**Pattern extraction date:** 2026-07-01
