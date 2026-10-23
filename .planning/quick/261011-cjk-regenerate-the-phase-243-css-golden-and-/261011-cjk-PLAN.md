---
phase: quick-261011-cjk
plan: "01"
type: execute
wave: 1
depends_on: []
files_modified:
  - test/fixtures/style/operator_surface.css
  - test/threadline/operator_surface/style_byte_lock_test.exs
  - test/fixtures/style/README.md
  - test/threadline/operator_surface/policy_show_doc_contract_test.exs
  - guides/operator-surface.md
autonomous: true
requirements: [UIV-01, UIV-02]
estimate:
  tokens: 7500
  raw_tokens: 7500
  tasks: 2
  confidence: low
must_haves:
  truths:
    - "The default rendered operator stylesheet equals the committed golden after its embedded font-face prefix, and both SHA-256 pins match the actual bytes."
    - "The golden retains all existing user CSS and incorporates the intentional Phase 243 redaction-refresh and narrow-screen evidence-footer rules."
    - "The Redaction policy page contract and page guide say 'Could not inspect'; the public :could_not_introspect enum and Mix-task label/docs remain intact."
    - "Focused formatter and ExUnit checks pass without skipped tests, new dependencies, or changes to production CSS and LiveView source."
  artifacts:
    - path: test/fixtures/style/operator_surface.css
      provides: "Current exact style-owned renderer bytes"
    - path: test/threadline/operator_surface/style_byte_lock_test.exs
      provides: "Matching golden and full-render SHA-256 pins"
    - path: test/fixtures/style/README.md
      provides: "Specific intentional-change note and existing regeneration procedure"
    - path: test/threadline/operator_surface/policy_show_doc_contract_test.exs
      provides: "Page label assertions aligned to the live UI"
    - path: guides/operator-surface.md
      provides: "Accurate page-specific operator wording"
  key_links:
    - from: lib/threadline/operator_surface/style.ex
      to: test/fixtures/style/operator_surface.css
      via: "Default Phoenix.HTML.Safe render with font-face prefix removed by the documented command"
    - from: test/fixtures/style/operator_surface.css
      to: test/threadline/operator_surface/style_byte_lock_test.exs
      via: "Exact golden and full-render SHA-256 pins"
    - from: lib/threadline/operator_surface/live/policy_redaction_live.ex
      to: test/threadline/operator_surface/policy_show_doc_contract_test.exs
      via: "Literal UI label and section-order assertions"
    - from: lib/threadline/operator_surface/live/policy_redaction_live.ex
      to: guides/operator-surface.md
      via: "Page-specific state description"
---

<objective>
Reconcile the intentional Phase 243 CSS and Redaction policy page copy with their committed byte and documentation contracts.

Purpose: `mix ci.all` currently fails three style byte-lock assertions and two policy show document-contract assertions because their expected artifacts lag behind committed production changes.
Output: A regenerated stylesheet golden with both pins and an intentional-change note, plus two corrected page label assertions and one page guide bullet. This quick task clears local verification blockers; Phase 243 Plan 05 must still rerun the full gates and refresh candidate evidence at the eventual final HEAD.
</objective>

<context>
@AGENTS.md
@.planning/STATE.md
@.planning/phases/243-integrated-verification-and-review-preview/243-UI-SPEC.md
@.planning/phases/243-integrated-verification-and-review-preview/243-05-PLAN.md
@test/fixtures/style/README.md
@test/threadline/operator_surface/style_byte_lock_test.exs
@test/threadline/operator_surface/policy_show_doc_contract_test.exs
@lib/threadline/operator_surface/live/policy_redaction_live.ex
@guides/operator-surface.md

Discovery level 0: the renderer, fixture regeneration command, hash pins, ExUnit contracts, and exact page copy are established in this repository. Completed read-only fan-out found two missing golden blocks: `.tl-policy__refresh` margin in `07_find_detail.css`, and narrow-screen `.tl-evidence__group-footer` spacing with its deep-link target/padding in `09_responsive.css`. The working tree already contains user spacing and backdrop-token edits in `07_find_detail.css` and `08_overlays_motion.css`; their bytes already match the dirty golden. Preserve them. No dependency, architecture, schema, route, authorization, or release decision is needed. The Phase 243 UI spec requires `Could not inspect` for the page while retaining `:could_not_introspect`; the Mix task intentionally retains `Could not introspect`.
</context>

<tasks>

<task type="tracer">
  <name>Task 1: Regenerate and pin the live stylesheet bytes</name>
  <files>test/fixtures/style/operator_surface.css, test/threadline/operator_surface/style_byte_lock_test.exs, test/fixtures/style/README.md</files>
  <read_first>test/fixtures/style/README.md; test/threadline/operator_surface/style_byte_lock_test.exs; lib/threadline/operator_surface/style.ex; lib/threadline/operator_surface/style/07_find_detail.css; lib/threadline/operator_surface/style/08_overlays_motion.css; lib/threadline/operator_surface/style/09_responsive.css</read_first>
  <action>Inspect the named working-tree diffs before editing and preserve all existing user changes, including the dirty golden, the prior Phase 242 README note, and both current hash-pin edits. From the repository root, run the exact renderer regeneration command in the fixture README; do not hand-edit CSS output or alter production CSS. Confirm the resulting golden adds the committed `.tl-policy__refresh` margin and the narrow-screen evidence-footer/deep-link rules, while retaining existing user CSS and containing no unrelated renderer drift. Compute SHA-256 of the regenerated fixture and of the full default render using the two commands in the README; replace only `@golden_sha256` and `@rendered_sha256` with those computed values. Append a concise Phase 243 note to the README naming the refresh-to-posture gap and the reachable 320px evidence footer links as the user-visible reasons, without changing the update procedure or earlier notes. Run the focused checks. Stage only these three files, inspect their staged diff, run the staged whitespace check in verify, then commit them with an intentional CSS-change message. Do not stage or touch screenshots, baseline files, source CSS, route guards, schemas, dependency manifests, or unrelated dirty files.</action>
  <verify>
    <automated>MIX_ENV=test mix run --no-start -e 'full = Threadline.OperatorSurface.Style.css(%{__changed__: nil}) |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary(); prefix = "<style>" <> Threadline.OperatorSurface.Fonts.face_css() <> "</style>"; true = String.starts_with?(full, prefix); suffix = binary_part(full, byte_size(prefix), byte_size(full) - byte_size(prefix)); true = File.read!("test/fixtures/style/operator_surface.css") == suffix'</automated>
    <automated>mix test test/threadline/operator_surface/style_byte_lock_test.exs</automated>
    <automated>mix format --check-formatted test/threadline/operator_surface/style_byte_lock_test.exs</automated>
    <automated>git diff --cached --check -- test/fixtures/style/operator_surface.css test/threadline/operator_surface/style_byte_lock_test.exs test/fixtures/style/README.md</automated>
  </verify>
  <done>The golden equals the renderer suffix, both exact SHA-256 pins pass, the README records the user-visible reason, and the three named paths alone form the first task commit.</done>
</task>

<task type="auto">
  <name>Task 2: Align Redaction page assertions and guide with the live heading</name>
  <files>test/threadline/operator_surface/policy_show_doc_contract_test.exs, guides/operator-surface.md</files>
  <read_first>test/threadline/operator_surface/policy_show_doc_contract_test.exs; guides/operator-surface.md; lib/threadline/operator_surface/live/policy_redaction_live.ex; lib/mix/tasks/threadline.policy.show.ex; .planning/phases/243-integrated-verification-and-review-preview/243-UI-SPEC.md</read_first>
  <action>In the policy show document contract, change only the two LiveView source label literals for the `:could_not_introspect` section from the stale page wording to `Could not inspect`; leave the Mix-task label assertion, section order, JSON enum, and all other assertions unchanged. In `guides/operator-surface.md`, change only the Redaction policy page's three-state bullet to `Could not inspect`; retain the later Mix-task output sentence and machine enum text. Preserve any concurrent user edits. Run focused format and ExUnit checks, stage only these two files, inspect their staged diff, run the staged whitespace check in verify, then commit them. Add no dependency or production-code change.</action>
  <verify>
    <automated>mix format --check-formatted test/threadline/operator_surface/policy_show_doc_contract_test.exs</automated>
    <automated>mix test test/threadline/operator_surface/policy_show_doc_contract_test.exs</automated>
    <automated>git diff --cached --check -- test/threadline/operator_surface/policy_show_doc_contract_test.exs guides/operator-surface.md</automated>
  </verify>
  <done>The two LiveView literal assertions and page-specific guide state match `Could not inspect`, the Mix-task copy and public enum remain unchanged, and only the two named paths form the second task commit.</done>
</task>

</tasks>

<threat_model>
ASVS level 1; high-severity integrity failures block completion.

## Trust boundaries

| Boundary | Description |
|---|---|
| Production CSS render to tracked golden | A stale or manually edited fixture can claim byte fidelity without matching the served stylesheet. |
| LiveView page text to tests and guide | A broad wording change could misstate the public status enum or Mix-task output. |

## STRIDE threat register

| Threat ID | Category | Component | Severity | Disposition | Mitigation |
|---|---|---|---|---|---|
| T-q261011cjk-01 | Tampering | Stylesheet golden and hash pins | high | mitigate | Regenerate through the documented renderer, compute both hashes from actual bytes, run the byte-lock suite, and inspect the named diff. |
| T-q261011cjk-02 | Repudiation | Intentional CSS change record | medium | mitigate | Retain earlier README notes and add the exact Phase 243 user-visible reasons in the same commit as fixture and pins. |
| T-q261011cjk-03 | Information disclosure | Redaction status wording | medium | mitigate | Change only the page label literals; retain stable public enum, Mix-task copy, and existing no-secret-leak assertions. |
| T-q261011cjk-SC | Tampering | Package installation | high | accept | This task installs no package and changes no dependency manifest. |
</threat_model>

<verification>
After the two task commits, run `mix format --check-formatted test/threadline/operator_surface/style_byte_lock_test.exs test/threadline/operator_surface/policy_show_doc_contract_test.exs`, `mix test test/threadline/operator_surface/style_byte_lock_test.exs test/threadline/operator_surface/policy_show_doc_contract_test.exs`, and `git diff --check HEAD~2 HEAD -- test/fixtures/style/operator_surface.css test/threadline/operator_surface/style_byte_lock_test.exs test/fixtures/style/README.md test/threadline/operator_surface/policy_show_doc_contract_test.exs guides/operator-surface.md` to inspect the committed changes. Phase 243 Plan 05 separately owns the required `mix ci.all`, desktop/mobile browser suite, baseline hash check, and fresh candidate/preview receipts after this checkout reaches its final tracked HEAD.
</verification>

<success_criteria>
The five named files form two atomic commits. Both focused ExUnit contracts pass with the full rendered CSS pinned and the page wording consistent with the live UI, while production CSS, Mix-task wording, and public status values are preserved.
</success_criteria>

<output>
Create `.planning/quick/261011-cjk-regenerate-the-phase-243-css-golden-and-/261011-cjk-SUMMARY.md` after execution; the orchestrator records the completed quick task in `.planning/STATE.md`.
</output>
