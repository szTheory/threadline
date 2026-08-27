# Phase 197: Coverage Growth, Adversarial Closeout & Design-Debt Register - Pattern Map

**Mapped:** 2026-08-26
**Files analyzed:** 9 new/modified files
**Analogs found:** 8 / 9 (the 9th — tamper probes — is ephemeral, not a file)

No CONTEXT.md exists; file list extracted from 197-RESEARCH.md (PROOF-02/03/04 lanes + OQ-3 Wave-1 hardening recommendation). Phase 196's locked decisions D1–D9 bind everything below.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `.planning/phases/197-*/197-ADVERSARIAL-REVIEW.md` (new) | planning artifact (closeout review) | batch (evidence roll-up) | `.planning/milestones/v1.37-phases/180-accessibility-verification-guardrails-adversarial-closeout/180-ADVERSARIAL-REVIEW.md` | exact — the requirement literally says "v1.37-style" |
| `.planning/phases/197-*/197-DESIGN-DEBT-REGISTER.md` (new) | planning artifact (risk register) | batch (ranked ledger) | `.planning/milestones/v1.39-phases/193-quality-closeout-and-next-step-decision/193-RISK-REGISTER.md` | exact — "v1.39 risk-register shape" is the literal requirement |
| `lib/threadline/operator_surface/live/actor_live.ex` (edit) | LiveView page (operator surface) | request-response (render) | `retention_history_live.ex` edit in commit `c6f9355e` | exact — same role, same "signal-to-chrome" density-edit shape, gate-ACCEPTED precedent |
| `lib/threadline/operator_surface/live/evidence_live.ex` and/or `timeline_live.ex` (edit, pivot candidates) | LiveView page | request-response | same commit `c6f9355e` | exact (evidence caveat: needs an IA pass, not chrome removal — 196-06-SUMMARY:89) |
| `test/threadline/operator_surface/live/<page>_live_test.exs` (edit, one per touched page) | LiveView test | request-response | `retention_history_live_test.exs` edit in commit `c6f9355e` | exact — assert→refute flip pattern with rationale comments |
| `.planning/design-system-ledger.json` (append `ratchet.signoffs` entry per ACCEPT) | config/ledger | append-only event record | existing `ratchet.signoffs[0]` (landed in `f1610d87`) | exact — replicate the entry shape verbatim |
| `test/threadline/operator_surface/critic_trust_test.exs` (append `@known_signoffs` pin per ACCEPT) | test (guard-the-guards) | append-only | its own lines 172–200 (existing pin) + 464–468 (enforcement loop) | exact — append a sibling map, never edit existing entries |
| `examples/threadline_phoenix/e2e/critic/cache.ts` (OQ-3 fix: screenshot-keyed cache) | utility (TS, cache) | file-I/O (fs JSON cache) | itself — `cacheKey`/`lookupCache`/`writeCache` (lines 43–90) | exact (self-modification; pattern is extending the existing key tuple) |
| `examples/threadline_phoenix/e2e/critic/gate.ts` (OQ-3 fix: before-pole protection) | utility (TS, gate pipeline) | file-I/O + request-response (LLM) | itself — `beforeLensScore` (lines 307–329) + the existing missing-before VOID path (lines 388–397) | exact (self-modification; pattern is the VOID-with-instruction error style) |

## Pattern Assignments

### `197-ADVERSARIAL-REVIEW.md` (planning artifact, closeout)

**Analog:** `.planning/milestones/v1.37-phases/180-accessibility-verification-guardrails-adversarial-closeout/180-ADVERSARIAL-REVIEW.md`

**Frontmatter pattern** (lines 1–7):
```markdown
---
phase: 180-accessibility-verification-guardrails-adversarial-closeout
artifact: adversarial-review
created: 2026-06-20
status: passed
requirement: MOTION-02
---
```
For 197: `phase: 197-coverage-growth-adversarial-closeout-design-debt-register`, `requirement: PROOF-03`, `status: passed` only after every lens row is Pass.

**Lens-review table pattern** (lines 11–22) — one row per lens, each Review cell citing concrete evidence, Result = `Pass` / `Pass with bounded caveat`:
```markdown
## D-12 Lens Review

| Lens | Review | Result |
|------|--------|--------|
| Aesthetics vs usability | Motion, focus, screenshots, ... favor operator task clarity over decorative churn. | Pass |
| Dependency/architecture weight | No accessibility, axe, animation, or screenshot dependency was added. Evidence stays in existing ExUnit and Playwright harnesses. | Pass |
| Residual CI ownership | Current non-green `mix ci.all` failures are inherited Phase 179 doc/demo-seed failures. Phase 180-owned retention test failures were fixed and verified. | Pass |
```
For 197 replace the 180 D-12 lenses with the loop invariants (RESEARCH §PROOF-03): no root runtime dep, no public component API, dev/test-only, LLM out of CI, capture/query/auth untouched, loop cannot regress the deterministic floor. Each row's Review cell must cite a tamper-probe demonstration or a pinned test (e.g. `verify.critic_trust` FAIL under probe / PASS after revert; `forward_only_gate_doc_contract_test.exs` for CI posture), not bare assertion.

**Findings + Follow-Through pattern** (lines 24–34):
```markdown
## Findings

No blocking Phase 180-owned issue remains.

The main proof boundary is accessibility: Playwright's browser accessibility tree ... is not equivalent to NVDA, VoiceOver, ...

## Follow-Through

- Keep `operator-accessibility.spec.ts` as the rendered accessibility ... evidence harness.
- Keep the inherited demo seed failures in the residual bucket until a demo-seed phase owns them.
```
Findings names blocking issues or explicitly says none, plus honest proof-boundary caveats; Follow-Through is imperative "Keep ..." bullets. For 197, the residual-CI row should carry the pre-existing 3-module doc-contract baseline (V123Charter/FormlessPages/Phase06Nyquist, tracked since 195-10) exactly the way 180 carried its inherited Phase-179 failures.

---

### `197-DESIGN-DEBT-REGISTER.md` (planning artifact, register)

**Analog:** `.planning/milestones/v1.39-phases/193-quality-closeout-and-next-step-decision/193-RISK-REGISTER.md`

**Frontmatter pattern** (lines 1–16):
```markdown
---
phase: 193-quality-closeout-and-next-step-decision
artifact: 193-RISK-REGISTER.md
milestone: v1.39
clause: CLOSE-01 clause 3 (ranked remaining software-quality risks, each with owner + follow-up, no vague polish-later bucket)
generated: 2026-07-02
ranking_lens: adoption / operations / maintainer-risk (D-12) — NOT severity×likelihood
source_precedence:
  - runtime/source proof (phase VERIFICATION artifacts)
  - release/package truth
  - CI/gates
  - planning/residual history (189 ledger seed)
seed: .planning/phases/189-quality-baseline-and-authority-surface-audit/189-QUALITY-AUDIT.md
status: complete
---
```
For 197: `clause: PROOF-04`, `seed: .planning/phases/196-.../196-06-SUMMARY.md "Deferred to Phase 197"`, keep `ranking_lens` verbatim.

**Ranked-row pattern** (line 95–100, header + one full row) — every row carries Owner + concrete reopen-trigger; severity is secondary color only:
```markdown
| Rank | ID | Residual | Layer / Area | Owner | Adoption/Ops/Maintainer classification | Severity note (secondary) | Reopen trigger (concrete) |
|-----:|----|----------|--------------|-------|----------------------------------------|---------------------------|---------------------------|
| 4 | **R-D** | **~81 local `mix test` failures** — `(undefined_table) relation "audit_changes" ... does not exist` under a local storage_schema/search_path env gap (...) | Maintainer environment / Phase-190 storage-schema territory ... | maintainer env (Phase-190 territory) | **Maintainer-friction ONLY — explicitly NOT a v1.39 quality regression.** Evidence inline: the failure count is **identical at the pre-192 commit and at HEAD** ... | Not a severity item — it is friction, not a defect. | A **CI** (not local) test failure with the same `(undefined_table)` signature — i.e. the env issue reaches the provisioned pipeline. Local-only reproduction does not reopen it. |
```
Seed rows from RESEARCH's verified debt table (#1–#9: cache key, before-pole, Tier-A drift, evidence IA, GATE-02 auto-write, color_contrast ρ0.698, hierarchy ρ0.42, 3-module doc-contract baseline, search_path friction). GATE-02 auto-write gets a reopen-trigger like "≥N accepted iterations where the surfaced diff was applied verbatim with zero human modification" (OQ-1). Verify debt #9's count with one `mix test` run before writing the row (Assumption A1).

**Closing rules pattern** (lines 102–110):
```markdown
**No polish-later bucket exists.** Every residual above and every preserved
189 row carries an explicit owner and a concrete reopen-trigger.

## Boundary Check

- Output is `.planning/phases/193-*` only; no product code, schema, UI, workflow, `mix.exs`, version, or git tag changed (D-02).
```
Also copy the register's Verdict-section honesty stance (lines 88–93): rank by leverage, and explicitly refuse to over-claim friction as regression.

---

### `lib/threadline/operator_surface/live/{actor,evidence,timeline}_live.ex` (LiveView page edits, PROOF-02)

**Analog:** `git show c6f9355e` — the gate-ACCEPTED retention density edit (`retention_history_live.ex`). All candidate files exist in `/Users/jon/projects/threadline/lib/threadline/operator_surface/live/`.

**Core edit pattern** (from the c6f9355e diff) — remove chrome that restates signal owned elsewhere, and leave a rationale comment naming the phase, the lens, and where each removed duty now lives:
```heex
-              <%= if @retention_summary.healthy? do %>
-                <div class="tl-alert tl-alert--success" role="status">
-                  Latest run succeeded... — the retention window is healthy. Pruning permanently deletes older audit records by policy...
-                </div>
-              <% else %>
-                <div class="tl-alert tl-alert--warning" role="status">...</div>
-              <% end %>
-
+              <%!-- Density (196-06, signal-to-chrome): no status alert and no
+              "destructive action" self-label here. The stat cards above already carry
+              latest status + failure count (with a danger state and a deep link), and
+              the type-to-confirm prune modal delivers the destructive warning at the
+              point of action — restating either as banner prose is chrome. --%>
               <div class="tl-page__actions">
-                <span class="tl-hint">Retention window destructive action</span>
```
Notes that carry over: the whole template sits inside `if Code.ensure_loaded?(Phoenix.LiveView) do` (do not disturb); use `<%!-- ... --%>` HEEx comments for the rationale; for 197 the comment prefix becomes e.g. `Density (197-0X, signal-to-chrome):`. Evidence page specifically requires an IA restructure (merging six one-row sections' scaffolding), not this chrome-removal shape.

**Commit-message pattern** (c6f9355e):
```
feat(197-0X): <what signal-to-chrome/IA change> — <what was removed/merged and why>

Forward-only gate: ACCEPT (<lens> delta +N > noise floor M, no blocking
regression, page.<x>.happy floor green, held-out oracle stable).
```

---

### `test/threadline/operator_surface/live/<page>_live_test.exs` (LiveView test edits)

**Analog:** same commit `c6f9355e`, `retention_history_live_test.exs` hunk.

**Assert→refute flip pattern** — rename tests to describe where the signal now lives, flip removed copy to `refute`, assert the surviving carrier (including data attributes), and comment the rationale:
```elixir
-      test "shows a success alert when latest run succeeded with no failures", %{conn: conn} do
+      # Density (196-06): the success/warning status alerts and the "Retention window
+      # destructive action" self-label were removed — the stat cards carry the health
+      # signal (status + failure count with danger state) and the type-to-confirm modal
+      # carries the destructive warning at the point of action.
+      test "carries run health in the stat cards, not a status alert (healthy)", %{conn: conn} do
         ...
-        assert html =~ "Latest run succeeded"
+        assert html =~ "Retention window health"
+        assert html =~ "Failures"
+        refute html =~ "Latest run succeeded"
+        refute html =~ "Retention window destructive action"
```
Failed-state twin asserts the semantic attribute, not prose: `assert html =~ ~s(data-status="danger")`.

---

### `.planning/design-system-ledger.json` (append `ratchet.signoffs`)

**Analog:** existing `ratchet.signoffs[0]` (landed in commit `f1610d87`). Append a sibling object per ACCEPT — never modify existing entries, floors, targets, or panel in the same change:
```json
{ "kind": "forward_only_accept", "target": "route.retention__dark-1280", "lens": "density",
  "delta": 7, "noise_floor": 4.5,
  "before": { "signal_to_chrome": 32, "task_primary_prominence": 67,
              "panel": { "brand_fidelity": 80, "density": 32, "typography": 67, "rhythm": 68 } },
  "verdict": "ACCEPT", "date": "2026-08-26",
  "ratified_by": "maintainer (in-session PROOF-01 ratification, phase 196-06)",
  "commit": "c6f9355e", "notes": "..." }
```
For 197: `target` = `route.<page>__dark-1280`, `ratified_by` cites the 197 plan/checkpoint, `commit` = the source-edit commit sha. `before.panel` carries all four blocking lenses from the cache-busted before pole.

### `test/threadline/operator_surface/critic_trust_test.exs` (append `@known_signoffs` pin)

**Analog:** the file's own lines 172–200 (pin as an Elixir map with string keys mirroring the JSON exactly, including the `<>`-concatenated notes) enforced by lines 464–468:
```elixir
    @known_signoffs [
      %{
        "kind" => "forward_only_accept",
        "target" => "route.retention__dark-1280",
        "lens" => "density",
        "delta" => 7,
        "noise_floor" => 4.5,
        "before" => %{ "signal_to_chrome" => 32, ... },
        "verdict" => "ACCEPT",
        "date" => "2026-08-26",
        "ratified_by" => "maintainer (in-session PROOF-01 ratification, phase 196-06)",
        "commit" => "c6f9355e",
        "notes" => "Removed the status banner ..." <> "..."
      }
    ]
```
```elixir
      for pinned <- @known_signoffs do
        assert pinned in signoffs,
               "a previously-committed ratchet.signoffs entry disappeared: ... (GATE-04)."
      end
```
The pinned map must be `==`-equal to the JSON entry (the enforcement is `pinned in signoffs`), so keep field types identical (integers stay integers, floats stay floats). Ledger append + pin land in the same commit (`chore: forward-only gate — ...` per f1610d87).

---

### `examples/threadline_phoenix/e2e/critic/cache.ts` (OQ-3 debt #1: screenshot-keyed cache)

**Analog:** itself. The current key (lines 43–52) omits any screenshot input — this is the stale-verdict bug:
```typescript
function cacheKey(
  cellId: string,
  dimension: string,
  rubricHash: string,
  modelId: string,
): string {
  // Sanitize key components to prevent path traversal
  const safe = (s: string) => s.replace(/[^a-zA-Z0-9._-]/g, "_");
  return `${safe(cellId)}__${safe(dimension)}__${safe(rubricHash)}__${safe(modelId)}`;
}
```
**Pattern to copy for the fix:** extend the tuple the same way `rubric_hash` already works — the file header (lines 4–8) documents the auto-invalidation idiom to replicate: "The rubric_hash is the sha8 component of the rubric version string, so a rubric edit auto-invalidates the cache for affected cells." Add a `screenshotHash` (sha8 of the PNG) component to `cacheKey`, the `CachedVerdict` interface (lines 22–37), and both `lookupCache`/`writeCache` call sites; corrupt/missing entries already degrade to a miss (lines 70–75), so old-format entries simply miss — no migration needed.

### `examples/threadline_phoenix/e2e/critic/gate.ts` (OQ-3 debt #2: before-pole protection)

**Analog:** itself. `beforeLensScore` (lines 307–329) reads the before pole from `.planning/critic-scores/<cell>/<lens>/*.json`; the only current protection is the missing-pole VOID (lines 388–397). **Copy this VOID-with-exact-instruction error style** for the new overwrite guard (e.g. a pole-stamp file that `critic:score` refuses to clobber):
```typescript
      if (before === null) {
        return {
          ...base,
          ran: true,
          void: true,
          note:
            `No before-snapshot for ${cell}/${lens}. Run \`npm run critic:score -- --page ${page}\` ` +
            `BEFORE editing to record the pre-edit poles, then re-run the gate.`,
        };
      }
```
Median-of-score-files aggregation (lines 313–328) and the prose `ACCEPT_REJECT_RULE` constant (lines 294–298) are the house style for any new gate-adjacent logic: compose existing primitives (`scoreCellLens`, `runNSamples`), never reimplement scoring, and print self-documenting rules under `--dry-run` / missing `ANTHROPIC_API_KEY` (lines 360–372).

---

## Shared Patterns

### Paid-step checkpointing (applies to every PROOF-02 plan)
**Source:** RESEARCH Pitfall 3 + gate.ts lines 360–372 (`if (dryRun || !process.env.ANTHROPIC_API_KEY)`)
`ANTHROPIC_API_KEY` is unset in the executor env by design (196-D9). Every `capture:pages` / `critic:score` / `critic:gate` step is a `checkpoint:human-action` with the exact paste-ready commands, including the cache-bust:
```bash
rm .planning/critic-verdict-cache/<cell>__*.json   # before EVERY re-score after a re-capture
npm run critic:score -- --page route.<x>            # BEFORE pole only — never re-run after the edit
npm run critic:gate -- --page route.<x> --lens <lens>   # the ONLY post-edit scoring command
```
Deterministic steps (`mix verify.mechanical`, `mix verify.critic_trust`, LiveView tests, source edits) stay executor-run.

### Append-only signoff + pin pairing
**Source:** commit `f1610d87` (ledger + `critic_trust_test.exs` in one commit)
**Apply to:** every ACCEPT. Ledger entry and `@known_signoffs` pin are one atomic commit; `route.*` scorecards and `.planning/CRITIQUE.md` stay uncommitted; no floor/target/panel change rides along (each needs its own signoff or `verify.critic_trust` fails).

### Doc-contract lockstep
**Source:** `test/threadline/forward_only_gate_doc_contract_test.exs` (lines 12–49) + `mix.exs` line 88–89 (`verify.doc_contract` alias lists every doc-contract test file explicitly)
**Apply to:** any task touching CONTRIBUTING.md's runbook, the twin table, or the 5-route lane — and to the optional new 197-artifact doc-contract test. Pattern: `use ExUnit.Case, async: true`, `@contributing File.read!("CONTRIBUTING.md")` at module scope, `String.contains?` assertions on literal headings/commands/twin names with a per-item failure message. If a new test file is added it MUST also be appended to the `verify.doc_contract` alias string in `mix.exs` (line 89).

### Verification cadence
**Source:** RESEARCH §Sampling Rate. Per task: `mix verify.critic_trust && mix verify.mechanical` + touched page's LiveView test file. Per wave: `mix compile --warnings-as-errors && mix format --check-formatted && mix verify.doc_contract`. Phase gate: `mix ci.all` green except the pre-existing 3-module baseline.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| PROOF-03 tamper probes | ephemeral local edits (probe → observe FAIL → revert) | n/a | Not files — transcript/output evidence captured into 197-ADVERSARIAL-REVIEW.md review cells. Probe list is fully specified in RESEARCH (drop a floor without signoff, remove an oracle fixture, delete the pinned signoff, add to the empty `structural_whitelist`), each expected to fail `mix verify.critic_trust`. |

## Metadata

**Analog search scope:** `.planning/milestones/v1.37-phases/180-*`, `.planning/milestones/v1.39-phases/193-*`, `lib/threadline/operator_surface/live/`, `test/threadline/operator_surface/`, `test/threadline/`, `examples/threadline_phoenix/e2e/critic/`, git history (`c6f9355e`, `f1610d87`)
**Files scanned:** ~15 (2 precedent artifacts read in full, 2 commits diffed, cache.ts/gate.ts/critic_trust_test/forward_only_gate_doc_contract_test excerpted, live/test dirs listed)
**Pattern extraction date:** 2026-08-26
