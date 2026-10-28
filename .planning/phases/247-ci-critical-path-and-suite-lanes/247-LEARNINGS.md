# Phase 247 lessons carried into local gap work

These lessons come from Plans 01–19, the verified fixture recovery, the one-run
diagnostic and the subsequent primary-source research. They do not mark the
phase complete.

| Lesson | Evidence | Working rule |
|---|---|---|
| A field name does not establish its timing boundary. | `boot_ms` is VM time at the first module event; Mix can execute async modules while requiring files. | Name the event and clock. Record loading, helper and execution boundaries separately. |
| Read the callee and exact version before asserting ordering. | The first research pass inferred a barrier from `Mix.Tasks.Test`; `Mix.Compilers.Test` v1.15.8 calls async_run before require. | Cross-check caller, callee and event producer; correct the record when source contradicts a claim. |
| Change one variable for a causal comparison. | Old P3 was 31 all-sync files; the diagnostic had 36/eight async plus fixture changes. | Different source/assignment runs are descriptive cohorts, not causal A/B pairs. |
| Balanced estimates do not prove balanced elapsed time. | Equal predicted costs still yielded min ratio 1.31 and current 1.17. | Separate committed-weight drift from residual model error; evaluate the real total-wall criterion. |
| Training fit is not holdout validation. | B3 informed both refreshed weights and the model check; B4 still missed. | Freeze cohorts before analysis, stratify lanes/runs, and never tune on the acceptance cohort. |
| A discounted async sum needs an individual duration floor. | A long async file could count as only 29.2% of its wall time. | Preserve the verified longest-async floor and its mutation control. |
| Database isolation is not filesystem isolation. | Partition VMs shared `priv/threadline_exports` despite separate databases. | Co-locate every shared-root user and serialize the module; prove split ownership goes red. |
| A fixture must own detached workers. | A PrunerTest ended while an unlinked worker could delete the next fixture's parent. | Give ExUnit ownership through its task supervisor; install ownership before arming short timers. |
| Profile output is not an execution receipt. | Elixir 1.15 profile mode compiled the paths, skipped execution and emitted exit 1. | Validate profile-specific markers; do not call it missing files, failed tests, or passing tests. |
| Local optimization can merely move cost. | Fixture extraction saved 0.400 s require but added 1.531 s compile. | Measure the complete affected path, including cold/warm cache effects, before adopting a refactor. |
| Passing CI does not satisfy every performance gate. | All 17 diagnostic jobs passed while two lanes exceeded 1.15. | Keep warning-only job behavior and numeric acceptance separate. |
| Caps and incomplete samples are outcomes. | B4 exhausted six runs with four successes/two failures; diagnostic used 1/1. | Preserve exclusions and null medians. Do not buy another favorable sample or retry an attempt. |
| Small, understood tools often beat another dependency. | The remaining experiment needs only Elixir/OTP and standard shell/Python. | Add a dependency only when its security, maintenance and reuse benefits justify the surface. |
| Instrumentation should be scoped to its job. | The trace is retained on an immutable diagnostic branch and absent from the source authority. | Keep one-shot probes out of permanent CI; remove them before a landing candidate is merged. |
| Validate external CLI preconditions and preserve errors before measuring. | Docker rejected an invalid bind-mount `,rw` flag before ExUnit, and the coordinator initially dropped stderr. | Retain failed-launch provenance; repair setup before observations; capture bounded stderr/exit on every path. Never reclassify an observed failure as preflight. |

The bounded local plans are executed. The canary stopped INVALID; the frozen replay has 96 checked rows. Neither establishes a main five-run median or a three-run-per-lane balance pass. No further hosted budget is implicit.

Additional lessons from the invalid canary and its reviewed repairs:

- OTP monotonic timestamps may be negative. Parser fixtures must include real saved output, signed clocks, malformed records and child stderr.
- A trace collector needs inherited tracing, delivery/flush acknowledgment and occurrence timestamps. Delivery alone cannot prove ordering; timestamping at flush measures the wrong event.
- Keep child stderr immutable after capture and put parser errors in their own field. A failed parser must not erase evidence.
- Bind a receipt to its historical producer bytes. Repairing the current tool does not repair an old observation.
- Hashes taken after reading a cache are fingerprints, not independent provenance. Pin original observations to detect later changes and state what missing archives prevent proving.
- Test small probe plumbing before spending a bounded measurement budget. When an observed arm is invalid, retain it and stop; pure repairs do not authorize replacement samples.

Sources: `247-NEXT-SYNTHESIS.md` links the exact-version primary sources;
`247-LOCAL-RECOVERY.md` and `247-DIAGNOSTIC-RUN.md` bind the observations to
commits, runs, controls and artifacts.
