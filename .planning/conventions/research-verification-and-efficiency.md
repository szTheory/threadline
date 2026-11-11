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
