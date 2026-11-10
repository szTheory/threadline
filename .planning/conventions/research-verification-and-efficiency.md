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
