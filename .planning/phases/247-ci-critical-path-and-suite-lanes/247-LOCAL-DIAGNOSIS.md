# Phase 247 local diagnosis and stop decision

**Decision: STOP with an invalid local canary and a valid descriptive replay.** The replay has complete frozen provenance, but the canary is `INVALID`: it stopped during one warmup, before any pair or control. This is not evidence for or against the historical CI cause. Keep the phase at **2/4**: CI-02 is **INCOMPLETE** (four of five required B4 main successes; median null) and CI-03 is **MISS** (the fixed first-three minimum-lane printed ratios are 1.24 / 1.28 / 1.27 against 1.15). No additional run, cohort, fit, optimizer, weight change, PR, merge, workflow change, or relaxation of the 1.15 / 540-second limits follows from this result.

## Machine projection

The authoritative machine projection is in [247-FROZEN-REPLAY.json](./247-FROZEN-REPLAY.json), schema `threadline.phase247-frozen-replay/1`, replay status `VALID`. Its `decision_projection` binds canary `INVALID`, historical cause `UNPROVEN`, CI-02 `INCOMPLETE`, CI-03 `MISS`, four B4 successes, and the fixed first-three min ratios. `VALID` describes only identity, source, artifact, assignment and arithmetic checks; it is not a CI acceptance or causal verdict.

Input SHA-256:

| Receipt | SHA-256 |
|---|---|
| `247-FROZEN-REPLAY.json` | `5bbf55a8e9958e6f38d33da9ff21a816fb2b7542b03a33829ed5b881a7b8a6f1` |
| `247-LOCAL-CANARY.json` | `7a946173a6e4c9ca407d94d766343596f77980eaf01eb0ad353985e85b171385` |
| `247-LOCAL-CANARY-PREFLIGHT.json` | `728d8c8efa6fd88c6124c0c1745bcd0a26b00c4b61ebbcd25c7135aa607bb553` |

The replay freezes three B3 training runs (`40433193088`, `40434036118`, `40434884357`) at `89add23e…`; four B4 holdout successes (`40449332597`, `40450141708`, `40450801580`, `40451533079`) at `02d115a3…`; and off-main diagnostic `40504321590` at `8177d00d…` as its own role. B3 is training data that informed the weights/model, not independent validation. The diagnostic is not a fifth B4 run. Excluded failures stay explicit and have no timing rows: B3 `40435657557`; B4 `40452150109` and `40452833440`; and initial PR failure `40446515239` (preserved, not retried or included).

The JSON binds all three source snapshots by git blob SHA-256, every timing TSV by its content SHA-256, all seven qualifying run metadata records by ID/head/attempt/conclusion and metadata SHA-256, plus the canonical measurement, canary and preflight receipts. Each successful lane has four partitions and exact-once timing-file coverage: 269 full/current files and 206 min/latest toolchain files, with source-head colocation groups intact. Diagnostic current/latest rows come from the named cached run artifacts; its min files also match the canonical embedded raw TSVs. No aggregate-only lane was expanded into invented per-file residuals.

## Reading the replay

Each row is one run/lane/partition observation, not an independent CI replicate. `historical_observed` groups measured per-file walls using that source revision's classifier and formula. `committed_weight_prediction` uses the committed lane weights on the same recorded file assignment. `weight_error_ms` is observed file cost minus that prediction; `active_residual_ms` is `(wall_ms - boot_ms) - observed file cost`. The standardized `S + max(0.292 A, L)` result is kept in its own field. Source-specific async classification, lane weights, colocation, cost implementation and blobs are read from the exact historical commits; no current-worktree grep is used for historical files.

Across min-lane partitions, weight error spans B3 **15,744 to 34,727 ms**, B4 **−46,853 to 9,124 ms**, and diagnostic **−62,912 to −48,278 ms**. Active residual spans B3 **−3,293 to 15,039 ms**, B4 **−5,836 to 17,888 ms**, and diagnostic **4,267 to 14,506 ms**. These ranges separate stale committed estimates from remaining active-wall discrepancy; they do not identify a cause, and partition-level values are descriptive within their shared workflow. The diagnostic run's canonical printed total ratios remain current/min/latest **1.17 / 1.31 / 1.10**. For B4 min, printed integer-second ratios from the canonical CI output (1.24 / 1.28 / 1.27 for the first three fixed runs) are the acceptance authority. Millisecond TSV totals, body-only ratios and quantization differences are diagnostics only.

## Canary and causal limits

The immutable Docker preflight failure remains `PREFLIGHT` evidence: the original invocation exited before ExUnit because the bind-mount argument was invalid, and stderr was not retained. After the documented pre-data launcher correction, the one permitted local series ran only `arm-01-warmup-async` (2,578 ms); the child exited 0 but the event parser rejected valid negative monotonic timestamps. Registration events and a valid formatter TSV were absent, so the receipt is `INVALID`; there were zero A/B pairs and zero controls. The coordinator error also overwrote the captured process stderr excerpt. No runtime fix or replacement sample is claimed here; the raw receipt and producer snapshot remain unchanged.

The initial `Mix.Tasks.Test` call site alone did not establish event ordering: it delegates test compilation/execution, while the relevant scheduling behavior is in the exact-version callee and ExUnit registration/server/runner path. The corrected source review cites [Mix.Compilers.Test v1.15.8](https://github.com/elixir-lang/elixir/blob/v1.15.8/lib/mix/lib/mix/compilers/test.ex), [ExUnit.Case v1.15.8](https://github.com/elixir-lang/elixir/blob/v1.15.8/lib/ex_unit/lib/ex_unit/case.ex), [ExUnit.Server v1.15.8](https://github.com/elixir-lang/elixir/blob/v1.15.8/lib/ex_unit/lib/ex_unit/server.ex), and [ExUnit.Runner v1.15.8](https://github.com/elixir-lang/elixir/blob/v1.15.8/lib/ex_unit/lib/ex_unit/runner.ex). `Mix.Compilers.Test` starts `ExUnit.async_run()` before parallel test-file require and awaits it afterwards, so async module registration can occur during loading. The invalid canary did not validate that timing oracle.

The historical B4 minimum-lane P3 had 31 all-sync files; the off-main diagnostic P3 had 36 files including eight async files. Changed source and assignment prevent a causal A/B interpretation. Fitted B3 balance is training fit, not measured holdout balance. The profile-only exit 1 is a separate compilation-only path that skips test execution; it is neither a failed test nor evidence of a missing file. The original full acceptance measure remains total printed wall time, not `wall - boot`.

Fixture reliability fixes remain independently reviewable, temporary startup trace stays off main, and CI-01/CI-04 retain their existing verified evidence. CI-02 and CI-03 remain open. The exact-version primary sources and broader rationale are recorded in [247-NEXT-SYNTHESIS.md](./247-NEXT-SYNTHESIS.md). A later causal candidate or hosted cohort needs a separate scope decision with an explicit exact budget and verification path.

## Independent review receipt

**Reviewer:** `replay_reviewer` (independent Codex subagent)  
source: automated-review  
**Reviewed body SHA-256:** `6981c057ef061d5fc25b57fc71bdbc70c80c952bd77b982cae36e935be76ccec`

Checked artifact hashes (`sha256:`): replay `5bbf55a8e9958e6f38d33da9ff21a816fb2b7542b03a33829ed5b881a7b8a6f1`; canary `7a946173a6e4c9ca407d94d766343596f77980eaf01eb0ad353985e85b171385`; B3 measurement `afd1c32c6e0c6d3058bfb2afba7f0ece82b71ed75cd9564c4148764091847b4d`; B4 incomplete `4a4a9b237afbd3565d59dd15eb6d8083a77fc92f033302e3780d4cb3a488fe7f`; diagnostic evidence `0481429ae14418a4cf7757442923795797396786f622eadb17b8da93e4a9a29f`; preflight `728d8c8efa6fd88c6124c0c1745bcd0a26b00c4b61ebbcd25c7135aa607bb553`.

**Findings and disposition:** Reviewer independently checked all 96 rows and found no weight-error or active-residual arithmetic mismatches. Cohort roles, failures, canary status, CI gates, source-bound separation, and stop language match the raw receipts and synthesis. All non-diagnostic printed ratios match the canonical per-run lane arrays; the diagnostic ratios match saved lane aggregates and their `printed_ratio_source` labels that aggregate scope. No factual or inference errors; review **PASS**.
