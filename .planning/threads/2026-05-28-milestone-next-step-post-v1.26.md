# Thread: Milestone next-step assessment (post-v1.26)

**Opened:** 2026-05-28
**Status:** closed
**Outcome:** Recommend **v1.27 Distribution & First-Hour Finish** — not external pilot (no sustained adopter signal). Done band **~90–93%** for stated narrow audit-platform scope.

**Supersedes:** [2026-05-27-diminishing-returns-assessment.md](./2026-05-27-diminishing-returns-assessment.md) (v1.26 wedge closed; done-% revised upward).

## Done-% judgment

- **~90–93%** for stated narrow audit-platform scope (post-v1.26).
- Band: **90–95% near-done / diminishing returns soon** — one distribution wedge still foundational.
- Remaining delta is **IMPORTANT-BUT-NARROW** (release truth + first-hour footguns), not missing core engine.

## Repo-grounded evidence (2026-05-28)

| Finding | Severity | Source |
|---------|----------|--------|
| Hex.pm latest **0.5.0** vs in-repo **0.6.0** | Adopter-facing blocker | `mix.exs`, `guides/evaluating-threadline.md`, adoption-pilot backlog |
| `config :threadline, ecto_repos` required by mix tasks; **absent from getting-started** | Day-1 silent failure | `lib/mix/tasks/threadline.evidence.show.ex` `resolve_repo!/0`; example `config.exs:14` |
| getting-started §6 cookie staging sigra-specific | Non-blocking friction | v1.26 audit INFO-2; phx.gen.auth adopters need fork |
| ADOPT-AUTH neutrality literals not doc-contract locked | Non-blocking | v1.26 audit; content on disk only |
| Evidence plane is **host-write**, not auto-populated from retention/health | Expectation gap | `lib/threadline/evidence.ex`; no lib/ callers from ops paths |
| Row history in `/audit` requires mount `:schemas` | Undocumented | `operator_surface/live/row_history_component.ex` |

**Planning drift fixed in this pass:** PROJECT.md Active reqs for Phases 119–121 moved to Validated; MILESTONE-ARC updated v1.26 shipped / v1.27 queued.

## Wedge ranking

| Rank | Wedge | Verdict |
|------|-------|---------|
| 1 | **Distribution truth (Hex 0.6.0)** | Highest leverage — evaluators cannot install shipped stack from Hex |
| 2 | **First-hour `ecto_repos` config** | Hidden day-1 blocker for all mix tasks in host app |
| 3 | **First-hour doc finish** (§6 neutrality, ADOPT-AUTH contracts) | Closes v1.26 audit carry-forward |
| 4 | **Mount completeness docs** (`:schemas`, evidence expectations) | Operator expectation alignment |
| 5 | External pilot | **Deferred** — no sustained adopter signal |
| 6 | Pow / bearer auth lane | On demand only |
| 7 | v1.22 DEFER trio | Procurement pressure only |

## Single pick: v1.27 — Distribution & First-Hour Finish

**Goal:** Close gap between "library is built" and "adopter can evaluate and wire first hour without maintainer context."

**Suggested phases (continue from 122):**

1. Release & distribution truth — tag `v0.6.0`, verify `hex-publish.yml`, adoption-pilot Published row, CHANGELOG four-lane phx-gen-auth mention
2. First-hour config — document `ecto_repos`; doc contract; production-checklist cross-link optional
3. Adopter doc finish — ADOPT-AUTH literals; §6 neutrality; `:schemas` mount note; evidence host-write expectation; narrow integration-contracts naming SSOT

**Done enough:** Evaluator reaches audited write + investigation path from Hex 0.6.0 or clean clone without undocumented config; doc contracts green.

**Not in v1.27:** external pilot, compliance expansion, second reference app, Pow lane, evidence auto-population.

## Suggested ordering after v1.27

1. Hold / adopter-driven maintenance
2. **v1.28 External Pilot** — when re-engagement trigger fires
3. Pow or bearer lane — on explicit demand
4. DEFER trio — procurement pressure only

## Re-engagement trigger (unchanged)

First **sustained** real-adopter signal (pilot host, integration issue, procurement/security review) → pivot to pilot unblockers instead of synthetic milestones. See PROJECT.md Key Decisions v1.23.

## Graduation candidates (cross-phase patterns)

- Three-phase vertical slice: guide → root proof → doc neutrality (v1.26)
- Doc-contract tests as milestone closeout gate
- `mix verify.*` as claim authority over prose
- Assessment thread at each `/gsd-new-milestone` (`milestone_assessment.run_at_new_milestone`)
- Explicit **distribution truth** check (in-repo semver vs hex.pm) in milestone assessment
- Guide + root proof > second reference app for reference lanes

## Open investigations (carry forward)

| ID | Topic | Routing |
|----|-------|---------|
| HEX-PUBLISH-0.6.0 | hex.pm still 0.5.0 | Maintainer tag → CI; v1.27 Phase 122 candidate |
| IN-110-003 | `:agent2` not on `Manifest.user_id/1` | Optional hardening; no milestone |
| STG-01 | Host staging depth | Integrator-owned; external pilot when signal |

## Next step

Run **`/gsd-new-milestone`** with v1.27 Distribution & First-Hour Finish scope when ready. Maintainer may push `v0.6.0` tag in parallel or as Phase 122.
