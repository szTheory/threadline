---
status: diagnosed
trigger: "Diagnose the verify.example_browser failure at examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts:323: the mobile Show Drawer click times out because an open modal intercepts it during Plan 234-20's required mix ci.all gate."
created: 2026-10-06
updated: 2026-10-06
---

## Symptoms

expected: "The canonical mix ci.all gate passes, including the mobile operator-motion browser scenario."
actual: "The browser lane reports 313 passed, 26 skipped, 4 flaky, and 1 failed. The mobile Show Drawer click at operator-motion.spec.ts:323 times out because an open modal intercepts it."
errors: "The same mobile click failure appeared on the initial browser run and its 120-second retry. Other CI lanes passed."
timeline: "Observed during Plan 234-20 execution on 2026-10-06. Plan 234-20 changes documentation/typespec behavior and did not declare this E2E file in scope. A previous Plan 234 gate recorded 318 browser passes and 26 intentional skips."
repro: "Run the canonical mix ci.all / verify.example_browser gate. The failing scenario is examples/threadline_phoenix/e2e/tests/operator-motion.spec.ts:323, on mobile Show Drawer while an open modal intercepts the click."

## Current Focus

hypothesis: "The always-mounted stress toast overlaps the mobile Show Drawer trigger; the motion test leaves the toast visible after measuring it, so Playwright cannot dispatch the click that would trigger click-away dismissal."
test: "Compare the retained failure call logs and screenshot with the stress fixture, toast implementation, CSS, and the same test's history."
expecting: "The toast remains visible over the drawer trigger after the modal finishes closing, and the click retries stay blocked by the toast rather than an application assertion."
bug_class: heisenbug-mandelbug
next_action: "Ask the Phase 234 orchestrator to decide whether to repair this pre-existing browser fixture/test obstruction outside Plan 234-20, then rerun the focused mobile motion case and canonical CI gate."

reasoning_checkpoint:
  goal: find_root_cause_only
  scope: "Diagnosis only. Plan 234-20 is blocked at its canonical CI gate; do not edit E2E files, create a Plan 234-20 SUMMARY, or advance SPEC-02/phase tracking as part of this diagnosis."
  candidate_causes:
    - "code: The test measures the toast and leaves it visible before clicking an overlapped mobile trigger; the toast has manual and click-away dismissal only."
    - "config: Pixel 5 mobile viewport makes the fixed bottom-right toast overlap Show Drawer; desktop viewport has more room."
    - "environment: Browser scheduling may vary when the modal hide transition completes, but the persistent toast blocks after that transition in both retained attempts."
    - "data: No changing backend record is involved in this stress fixture's modal, toast, and drawer controls."
  and_gate: "yes: the failure requires both a visible non-auto-dismissing toast and a viewport/scroll position where its hit box covers the drawer trigger. A brief modal hide transition precedes this but does not sustain the timeout."
  confidence: "high for the immediate click obstruction; moderate for why this attempt differs from prior passing runs, since no controlled current-head reproduction was run."

## Eliminated

- hypothesis: "Plan 234-20's docs/typespec edits changed the stress page interaction."
  evidence: "Its source commits touch only lib/threadline.ex, lib/threadline/job.ex, lib/threadline/capture/audit_transaction.ex and related Elixir tests; the same mobile case was documented as a pre-existing lost-click flake in Phases 204 and 212."
  timestamp: 2026-10-06
- hypothesis: "The modal remained open for the entire 120-second timeout."
  evidence: "Both retained Playwright call logs show the modal intercepting only the first two click probes, then the stress toast intercepting roughly 228/229 later probes for the remaining timeout; the final screenshot shows no modal."
  timestamp: 2026-10-06

## Evidence

- timestamp: 2026-10-06
  checked: "Retained current browser failure and retry error-context.md files under examples/threadline_phoenix/e2e/test-results/operator-motion-...-mobile-chromium{,-retry1}/."
  found: "Both attempts timed out at the Show Drawer locator. The modal wrapper intercepted the first two probes; then #stress-toast intercepted about 228 and 229 retries respectively."
  implication: "The sustained blocker is the toast. The reported modal is only a transient part of the call log."
- timestamp: 2026-10-06
  checked: "Current retry screenshot test-failed-1.png."
  found: "The stress toast covers the visible right-hand Show Drawer button in the Pixel 5 viewport. The modal is absent."
  implication: "The toast hit box geometrically explains Playwright's actionability timeout."
- timestamp: 2026-10-06
  checked: "operator-motion.spec.ts reduced-motion scenario, stress_live/sections.ex, overlay.ex and 08_overlays_motion.css."
  found: "The test measures #stress-toast then opens and confirms the modal and immediately clicks Show Drawer; it never dismisses the toast or waits for the modal to be hidden. The stress fixture always renders the toast; Overlay.toast mounts it with JS.show, offers close/click-away/Escape, and explicitly has no auto-dismiss. CSS fixes the toast at bottom/right with a high z-index."
  implication: "On the mobile overlap, Playwright cannot click Show Drawer, so click-away cannot dismiss the toast; waiting longer cannot resolve the persistent hit-test obstruction."
- timestamp: 2026-10-06
  checked: "Prior phase records 204-12-SUMMARY.md and 212-07-SUMMARY.md; current Playwright config."
  found: "The same mobile test had a prior Show Drawer timeout attributed to a stress toast, and later passed without a code change. Another run marked the exact test flaky because it passed on retry. Playwright uses Pixel 5 for mobile, one worker, 120-second test timeout and one CI retry."
  implication: "This is a pre-existing viewport-sensitive intermittent interaction, not a new Plan 234-20 behavior regression."
- timestamp: 2026-10-06
  checked: "Knowledge base and per-test coverage availability."
  found: "No .planning/debug/knowledge-base.md exists. No per-test coverage for this Playwright interaction was found; fault localization based on flaky spectra would be unreliable."
  implication: "Diagnosis rests on direct retained trace/screenshot and source behavior instead of coverage ranking."

## Resolution

root_cause: "The stress fixture mounts a persistent fixed toast that overlaps Show Drawer on the Pixel 5 mobile viewport; the motion test leaves that toast visible and attempts a pointer click. Playwright correctly refuses to click through it, so the toast's click-away handler never fires. The modal hide transition briefly intercepts first but is not the sustained blocker."
fix: "Not applied in diagnose-only mode. Suggested direction: explicitly dismiss the toast after its motion assertions, wait for the modal to be hidden after confirmation, then click Show Drawer normally. Keep the browser assertion meaningful; do not force-click through the toast."
verification: "Direct current-run call logs, retry screenshot, source, and historical matching failures support the diagnosis. No current-head controlled reproduction or code fix was run in this mode."
files_changed: []
