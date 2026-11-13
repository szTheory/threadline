# Research, verification and delivery defaults

Standing maintainer direction, restated 2026-11-10. Applies to milestone scoping,
phase discussion/planning, execution verification, CI and release/CD work.
This policy refines the existing PROJECT constraints and milestone guide; it does
not remove a safety stop, approve new scope or authorize publication.

## Research before recommendations

- Reuse current project context and prior research before opening new questions.
  Identify decision clusters, then fan out independent subagents with explicit
  ownership and the configured model/effort. For lightweight Codex research,
  prefer GPT-6 Luna with xhigh effort. Return evidence, tradeoffs and a recommendation.
- Cover breadth and depth through the roles relevant to the actual decision:
  product/user jobs, UX/accessibility, architecture, Elixir/Phoenix/Ecto/PostgreSQL,
  host integration, security/privacy, compatibility, SRE and maintainer/release DX.
  Add another specialty only when it can affect this project's outcome.
- Consider pros/cons, examples, conventions and least surprise, patterns,
  anti-patterns, footguns, ecosystem precedent and recorded lessons. Prefer source
  code and reputable primary documentation; browse when freshness or uncertainty
  requires it, and separate observed facts from inference and proposals.
- Give one reviewer an adversarial pass over the coherent proposal. Follow up
  only on material gaps, contradictions or new evidence. Stop when another pass
  is unlikely to change a decision; a fixed agent count or checklist is not a goal.
- Synthesize one recommendation set whose decisions cohere. Apply clear routine
  choices within authorized scope. Ask only about a real product/public-contract,
  security, cost, irreversible-action or phase/milestone boundary decision. Preserve
  the rationale so future phases do not reopen settled choices without evidence.

Accrue and Fablebook are comparison inputs. Their unfinished work and local
constraints do not become Threadline authority. Threadline's signed-off brand,
actual product behavior and explicit host/compatibility policy remain decisive.

## Keep dependencies small and flat

Prefer a small, straightforward local implementation or an appropriately licensed
copy over a new dependency for a narrow job. Account for the copied code's source,
license, security updates and maintenance ownership. Add a dependency when it
materially improves correctness, security or maintainability; explain its transitive
footprint and why existing code or a small local solution is insufficient. This is
a preference for simplicity, not a requirement to reimplement complex security or
protocol machinery.

## Automate useful verification early

- Begin with the acceptance claim and the smallest reliable existing proof.
  Use unit, integration, end-to-end, smoke, seam or bounded property tests at the
  boundary that can actually observe the claim. Reuse meaningful existing checks.
- Goal: no routine human verification or UAT. Run supported checks, investigate
  failures, fix in-scope causes and perform bounded retests. Use independent agent
  review for bounded judgments such as copy clarity and visual consistency.
- Separate static rendering, live route/lifecycle behavior, database results,
  browser accessibility and visual evidence. Synthetic fixtures and automated
  judgments do not establish real adopter demand or observed human comprehension.
- Add a recurring CI check only when it protects a recurring failure class at a
  reasonable cost. Throwaway local verification is valid; record its result and
  limitations rather than turning every probe into permanent infrastructure.
- Bind evidence to the actual source, assets, fixture/clock, scope and browser
  conditions. Reuse passing proof only when that identity and freshness support
  the claim. A fresh digest alone does not remeasure an old finding. Rerun after
  relevant edits/failures or when the workflow requires current-source proof.
- Record completed verification, unresolved findings and the reason for any gap
  in the owning phase/milestone artifacts. Do not ask the maintainer to repeat
  an automated check, or reopen covered work without a relevant change or defect.
- Hand off only an actual capability/authority boundary: secrets, approved spend,
  live external state, publication or a consequential scope/strategy decision.
  Finish safe setup first; explain the choice and who acts next in plain language.

## Evaluate CI/CD efficiency during the work

Whenever a CI or release/CD run is active or completes, inspect the measured
critical path, setup and dependency work, duplicate checks, artifact/cache reuse,
polling/waits and slow tests. Apply low-risk improvements within the approved
scope when the evidence supports them; preserve coverage, required checks,
authorization boundaries and failure visibility. Record before/after timings
when a follow-up run can establish the saving.

Prefer removing duplicate work and reducing the critical path over adding caches,
concurrency, dependencies or retries by default. Runtime alone is not another
approval gate. Do not dispatch extra CI merely to satisfy this policy when no
useful measurement or regression proof is expected. Keep release/secret/spend
authority and explicit resource/no-retry limits intact.


## Local verification preflight and one-shot limits

Record the actual Elixir, OTP and PostgreSQL versions against the declared support policy before long local gates. A passing run on an older local database remains diagnostic evidence; it does not establish the supported database floor or a complete CI toolchain tuple. Check task-owned database capacity before combined root/example/browser gates. Prefer an already installed supported PostgreSQL instance in a unique temporary loopback directory, routed through existing host/port controls, to changing shared limits or terminating another project's clients. Bound it, record its identity and stop it before a user pause after owned clients finish.

Inspect first-attempt browser outcomes as well as the command exit: configured retries can return zero while a case remains flaky. Preserve failure context before another runner invocation overwrites it. Fix the actual proof boundary, retain assertions and attribution limits, and use retries-disabled affected checks where they establish the claim. Source-identical unaffected stages may be reused honestly; a scoped rerun is not a fresh full canonical result.

A one-invocation grant is consumed by the invocation even if it stops before all planned iterations finish. Corrections and routine bounded local checks remain in the approved phase scope, but an explicit no-further-full-repeat stop requires a new actual user grant. Do not reuse a consumed grant, silently reset a token or treat elapsed time as permission. Preserve the stop without asking for confirmation merely to keep it stopped.


## Avoid repeated inventory work inside contract checks

When a contract checks many subjects against one source or ownership inventory, build that inventory once per check invocation and reuse it inside the subject loop. Recompute for a new test invocation or deliberately changed input; preserve negative controls and duplicate-owner semantics. Measure the attributable before/after work before broadening an optimization. Phase248 exposed repeated whole-source AST parsing and recursive ownership expansion; both were corrected without caches, concurrency, dependency additions, assertion cuts or longer timeouts. Smaller unmeasured duplication is not a reason to expand scope. Run tests that create temporary Git worktrees with narrowly scoped local Git metadata access; a sandbox-denied fixture remains a failed invocation until separately diagnosed, and its focused pass does not become a fresh full-suite pass.

## Fixture helper refactors and diagnostic repeats

When moving setup from a fixture helper to its callers, account for every positive,
negative and deliberately untagged control. Preserve the premises required to reach
the detector branch; assert that premise in benign controls when its absence would
make a passing result vacuous. A helper refactor can pass the suite while weakening
coverage. If review misses that defect, explicitly supersede the clean review and
label the affected run's coverage and timing limitations before comparing results.

Static request reductions do not establish latency improvement. Compare only valid,
source-bound observations and keep an unknown cause unknown. A private formatter can
capture file-server state during a bounded repeat, but may affect scheduling; its
pass is diagnostic and does not silently replace an uninstrumented acceptance gate.
QA the actual installed CLI flags, alias lifecycle and output/exit preservation in
a tiny offline fixture first. Preserve fresh seed policy; a pinned seed changes it.

## Bound synthetic mutations and continuation work

When a control needs only one known representative to have a second owner, mutate
that exact valid path rather than recursively enumerating dependency/build trees.
Preserve production globs, baseline representatives and exact negative outcomes.
Prove the control still fails when its mutation is omitted or misdirected; do not
convert a smaller fixture match set or one-off timing into a flake-fix claim.

For bounded executor continuations, give exact current manifest paths, key names,
expected source and the one-file responsibility. The parent owns full identity and
public-evidence reconciliation; the executor owns its source edit, focused checks,
commit and one compact receipt. Do not make it rediscover historical temporary
receipts or repeat the parent's cross-source hash work. This continuation spent
about 298 seconds before a focused check that itself took about one second; narrow
handoff inputs and single ownership reduce that avoidable critical path without
adding caches, concurrency or dependencies. Preserve required independent review.

## Keep current proof records internally consistent

When a new accepted receipt changes status, update the existing authoritative
ledger row and current/latest status text in place. Label superseded checkpoints
as historical; prepending a correct success paragraph does not repair a stale
blocked row below it. Inventory validators that check only row presence must say
so explicitly and must not imply that they validated semantic acceptance status.
Use the independent goal verifier to judge receipt/claim consistency and retain
local-versus-hosted, visual-capture and automation limits. Documentation-judgment
criteria should be explicit before verification; do not invent human attestation
or a new routine approval checkpoint for an automated prose review.

## Prepare the environment once and measure real worker receipts

Use a concrete environment handoff with checkout/source identity, lock identities,
owned database/partition, capacity, raw version strings and prepared dependency/build
locations. Reuse that verified setup while checking current identity; do not rediscover
it through unsupported command variants. Create and migrate a dedicated example test
database before its first Mix test, even when the selected tests are pure contracts:
the example application still boots. A packaged version may include a suffix such as
`15.17 (Homebrew)`; preserve the raw value and compare the intended version component.
Keep per-invocation failures and explicit retry/window limits visible.

Do not substitute a character-count estimate for model token usage, or measure worker
runtime only from its first task commit to summary authoring. The managed launch and
terminal receipt provide actual elapsed time and usage after the worker returns.
Leave unavailable metrics unknown until reconciliation. Requirement completion in a
plan summary must distinguish full satisfaction from a partial contribution; phase
verification remains authoritative. These corrections avoid repeated metadata repair
without changing proof scope, adding caches/concurrency/dependencies, or claiming an
unmeasured speedup.


## Keep review ownership explicit across managed processes

When a managed executor hands a committed revision to its external parent for
independent review, that parent remains the sole assignment/result owner. A local
Codex process may identify its own role as `/root`; this does not transfer the
external parent’s responsibilities. Waiting time, a stale previous-round result,
or a runtime role label is not evidence that the parent abandoned the handoff.
Use revision-bound ready/result capsules, preserve each completed round, and keep
reviewed source immutable. Do not launch a duplicate review or overwrite the
parent-owned result to make waiting appear productive. If an overlapping review
already produced useful findings, retain and reconcile them rather than discard
actual evidence. Phase249 exposed this coordination defect; the correction adds
an explicit ownership clause to subsequent handoffs, without removing review.

Mapping validators that prove nonblank descriptions and existing reference IDs do
not prove that the referenced test observes the described behavior. Phase249’s
independent review found Home-only state descriptions on transaction/history
surfaces, missing ordinary comparisons for stress fixtures, and descriptions that
exceeded their linked populated-state proofs. Match each claim to its actual
renderer/test boundary, keep source/catalog/DB/browser evidence distinct, and add
negative controls at the failure boundary. Narrow unsupported wording when that
is the least disruptive supported remedy; do not add unrelated runtime tests to
preserve an inaccurate claim.

For before/after UI work, observe the existing supported path before making final
behavior a baseline prerequisite. Preserve missing capabilities as explicit before
limitations, then require the intended behavior in the after check. A passing
legacy workaround does not establish the final journey. Capture each meaningful
checkpoint, bind selected fields to live rows, validate artifact bytes and real
containment, and record runtime source before app startup. Comparing two current
disk trees does not prove what an already running app loaded. Keep parent review
and source-readiness handoffs distinct so a routine correction does not become a
new user approval or falsely promote incomplete evidence.


## Keep routine verification labels and archive lifecycles honest

A fixer template saying “requires human verification” does not create a user gate when the project explicitly requires automated checks and independent agent confirmation. Record the actual automated proof and pending/completed independent confirmation; do not fabricate a human pass.

When executable contracts cite versioned planning evidence, test the owning completion lifecycle, not only phase-directory cleanup. Active requirements may be archived, removed or replaced by a later milestone, and traceability Pending becomes Complete. Select the specific intended version and stable requirement wording; exercise archive precedence, absent sources and status changes in bounded fixtures. Keep unclassified intent separate from requirement completion. Prefer one explicit version-specific case to a new general archive framework.


For a completed immutable implementation awaiting external parent review, return a durable review-pending checkpoint instead of polling unchanged files in rapid tool/model cycles. The parent owns acceptance and reconciliation after the review. Keep executor closeout to one compact receipt referencing existing source-bound proof; parent owns cross-source reconciliation. Phase250’s corrected browser case took about six seconds while capture-to-worker-closeout took about nineteen minutes. Those are different measurements, and repeated evidence transcription or unchanged-source reads do not improve the browser proof. Status must distinguish completed product changes from verification machinery; a long run is not itself evidence of useful progress.


Freeze and return after the completed implementation handoff. Run required scoped scans before that boundary; do not reopen completed work with optional audits or change shared detector policy to silence unrelated findings. The signed-off brand controls intentional font choices. An integrity-only result is not an authorization result: pass the separate verified parent intake explicitly so a deliberate `parentAcceptance:false` integrity label cannot create a false approval stop. Use managed command sessions rather than detached shell jobs, which can disappear when their launching shell exits.


Keep executor context current and bounded. Phase250 measured 144,889 bytes in the full historical PROJECT versus 11,383 in its verbatim current purpose/milestone/context/constraints sections; `state.load` emitted 237,721 bytes versus about 4,000 after omitting `state_raw`. These are output-volume measurements, not latency claims. Supply current sections and preserve all configuration/status gates, use exact predecessor summaries, and inspect relevant blocks of large source/test files. Open historical decisions when a new relevant ambiguity requires them. Do not infer token usage from diff bytes or start elapsed time at the first task after setup.

Before another diagnostic, name the unanswered question and print only its relevant report fields. One Plan04 continuation emitted685,799 command-output bytes across56 commands, including repeated identical CSS records. These are measured output volumes, not latency savings. Avoid full-suite JSON dumps and repeated source blocks; compare full commit IDs consistently and place shell environment assignments before the command. When a focus assertion observes a transient state, preserve initial/cascade evidence and use a bounded assertion of the unchanged required settled state; never substitute a different expected width or claim an unproven browser cause.

Validate the complete readiness matching predicate before publishing a parent result: request, status, exact source commit, worktree and freshness. An omitted request discriminator caused a false wait despite ready services in Plan05. Compile the actual generated JavaScript when an Elixir string emits a script; source formatting cannot detect escapes lost across languages. Keep privately scoped proof registration from breaking ordinary test discovery, and require exact nonzero selected results for acceptance. Bind docs readiness to the served page carrying the hook as well as its redirect index. A halted SUMMARY is a checkpoint, not completed work. Fresh Pattern C continuations carry completed tasks and a narrow resume point; Plan05 supplied132,216 prompt bytes versus223,525 in its full initial prompt. Those are context-volume measurements, not claimed latency savings.

A required gate that fails still prevents plan completion when the failure predates the current task. Record an implementation-complete checkpoint with verification pending; the parent may integrate the committed source while explicitly retaining that pending gate, then resolve a bounded integration defect and verify before accepting the plan. Keep exact planning-only preparation commits distinct from implementation when reconciling evaluation-scope: verify their full identities, ancestry and changed paths rather than bypassing existing-commit checks. Phase250 exposed both a premature completion label and a planning-only commit caught by an overly broad dispatch guard.

For a structure receipt affected by an approved shell migration, causally isolate the changed owners before adding a new current receipt. Phase250 restored only the previous header/logo and passed all seven historical pins, restored exact current source, then preserved the historical map and changed only the new current shell pin. The combined affected checks passed with the canonicalizer, selectors, other pins and mutation controls intact. Keep that source comparison separate from visual/browser acceptance. In rendered-link regressions, extract the relevant hrefs or controls through the existing DOM parser before comparing them; avoid dumping a whole HTML document with embedded font payloads to diagnose one URL. Preserve full failure artifacts privately when needed.


When a migration changes rendered controls or function signatures, inventory the coupled exact selectors/source anchors before declaring its plan accepted. Phase250's selected cross-phase gate caught two old radio assertions, seven control anchors, two semantic locators and three added test declarations after narrower gates had passed. Update their existing owners together; preserve stable IDs, independent declaration discovery, source/duplicate checks and negative controls. A passing browser journey does not imply those source contracts are current. Require a genuinely fresh selected after pointer for each acceptance recapture, preserving superseded pointers and every original capsule; a fresh browser pass must not silently validate an older selection.

Before a composite browser gate, confirm the actual target selector, responsive disclosure, data type and instrumentation boundary once. Settled computed styles, a real document-level policy, pinned actual executable version and a connected production component avoid false diagnoses from synthetic fixtures or altered network classification. Preserve required failed attempts, then reuse current independent judgment with a bounded delta confirmation. The parent continuation's total duration is not evidence of a speedup over an interrupted worker with a different scope.


Resolve the required phase capability outputs before the first review dispatch: request the final code-review frontmatter and six-pillar UI scoring artifact together with source/capture identities. Reuse the same independent judgment for bounded corrections; do not create a separate format-only review round because the initial request omitted the final schema. Include coupled inventory/semantic regression owners in the initial verification plan. Phase250's additional schema-reconciliation handoffs were avoidable coordination, not new product evidence.


### Keep current orchestration documents current

Measured Phase251 intake repeatedly printed oversized historical STATE/PROJECT content. Keep active state concise and archive completed history with preserved, rebased links and a recorded source revision. Preserve all current approvals, stops, limits, pending work, requirements and effective decisions; archival is not authorization to disregard them. Read historical sections only when a current change depends on them, and select needed init/state fields instead of printing entire state payloads. Do not measure reduced document bytes as a runtime speedup.
