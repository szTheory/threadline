---
phase: 251
audited: "2026-11-13T05:32:56Z"
reviewed_revision: "da665edcb8590a86a209bc10acb1a98878c65353"
initial_reviewed_revision: "5ef9f8bf75ee31a8c1074daf39d75ba9063dcf81"
baseline_revision: "aa5079311ee14c5ad04500f6e1ddb851afa248c6"
status: secured
verdict: SECURED
level: ASVS1
block_on: high
threats_total: 14
threats_secured: 14
threats_open: 0
accepted_risks: []
---

# Independent security audit

The security auditor verified the declared mitigations for all fourteen unique authored threats (the dependency threat repeats in four plans). No blocking/nonblocking security finding or risk acceptance remains. This is an ASVS1 mitigation-presence verdict, not whole-phase acceptance or release readiness. The auditor returned the structured report without modifying files; the parent persisted its findings here.

## Source and method

All38 source hashes matched the frozen final-source-scope manifest at the reviewed revision. The auditor inspected source, security-sensitive callees and tests; it ran no builds, tests, browsers, apps or PostgreSQL operations. Baseline-to-revision changes contain no dependency manifest, lockfile, public router, runtime configuration or persistence-schema change. Planning configuration separately enables workflow.compact_content; this is not a claim that no configuration file changed. Prepared untracked dependency/build links do not establish installation history.

## Trust boundaries

Host assigns remain the sole repo, scope, callback and capability authority. Original URL/submitted/stored selection is validated before audit reads; display-only canonical preparation does not replace the untouched validation input. Retained navigation carries only validated predicates or fixed disclosed recovery. Successful selected inspection facts are separate from stale, invalid and unavailable state. Evidence uses a private allowlist and constant metadata summaries with a caller-overridable, unauthenticated-origin limitation.

## Authored threats

Every disposition is mitigate; none is accepted or transferred. Paths below are repository-relative evidence references.

| Threat | Plan | Severity | Status | Verified mitigation and evidence |
|---|---|---|---|---|
| T-251-01 | 01:219 | high | CLOSED | Original types/predicates/parser/query validation in `live/timeline_live/helpers.ex:135`; reads gated in `live/timeline_live.ex:136`, saved/submitted input at321/403. `live/timeline_live_test.exs:665/1825/1849` prove no read/patch with a supported-read control. |
| T-251-02 | 01:220 | high | CLOSED | Literal Timeline origin only in `live/timeline_live/helpers.ex:158`; host scope retained in Timeline699, Transaction23, RowHistory94 and `auth.ex:93/121`. Forged-scope controls in Timeline tests2026 and RowHistory tests343. |
| T-251-03 | 01:221 | medium | CLOSED | Fixed context-loss notices in Transaction147/RowHistoryComponent169 and local recovery at Transaction593/RowHistory136. RowHistory tests303/343/371 preserve valid predicates, exclude private extras and disclose loss. |
| T-251-04 | 02:242 | high | CLOSED | Default/blank/invalid classification in RowHistory103 and Transaction121; RowHistoryComponent51 skips invalid snapshot reads and209 displays invalid state. Owning tests106, component38 and Transaction1068 include positive-read controls and structured malformed input. |
| T-251-05 | 02:243 | medium | CLOSED | Actor28/450/473 retains exact allowlisted kind/id; helpers26 and Transaction471 invent no missing actor link. Actor tests197 isolate kinds with shared ID; Timeline tests1165 retain absent identity. Home63/96 creates no actor lookup. |
| T-251-06 | 02:244 | high | CLOSED | RowHistoryComponent32/39/98 passes repo/scope/callback on initial/retry; RowHistory94 and Transaction240 supply host assigns. Component tests239, RowHistory515 and Transaction1106 prove scoped boundaries. |
| T-251-07 | 03:199 | high | CLOSED | Coverage426/458 updates rows/header from one selected snapshot;445 retains last-good facts only for same schema; Coverage OnMount95 preserves selected polling. Coverage tests270/427 check equality and reject prior-schema facts. |
| T-251-08 | 03:200 | high | CLOSED | Coverage143/148 and SurfaceHeader176 render fixed selected unavailable/stale labels, not internal diagnostics. Coverage tests383/427 exclude error canaries and false empty/success. |
| T-251-09 | 03:201 | high | CLOSED | Coverage47/75 capability gates, CoverageSchemas23 conservative identifier/parameterized namespace lookup, Coverage431 one-schema read and Auth277 deny-on-error behavior. Coverage tests68/332/531 and mounted availability declaration1744 cover invalid/disabled/denied boundaries. |
| T-251-10 | 04:214 | high | CLOSED | PolicyRedaction256/263/280 normalizes schema-list/validation/report exceptions;276 constant correction and363 safe unavailable copy. RedactionPresenter146/457 emits parsed fields/fixed warnings. Policy tests164 cover all exception stages and canary absence; mounted declaration1843 checks rendered canaries. |
| T-251-11 | 04:215 | high | CLOSED | Evidence383 recognizes six exact subject/writer/entrypoint pairs;108 explicitly limits caller-overridable metadata. Evidence writers175–295/554 retain actual override semantics. Evidence tests124/162 cover exact/partial/mismatched/custom/absent metadata. |
| T-251-12 | 04:216 | high | CLOSED | Evidence363/379 constructs an allowlisted row and constant provenance summary without arbitrary map/detail/actor values. Evidence tests162/205 exclude nested, long, actor/detail canaries in latest/history. |
| T-251-13 | 04:217 | high | CLOSED | Policy280 stamps only successful inspection;292 clears failed report/sections/time;405 limits current definitions. Evidence334 clears failed results and134 separates unavailable/Retry from no-match; snapshot time is explicitly labeled. Policy tests145/213/245/431 and Evidence604 prove boundaries. |
| T-251-SC | All four plans | high | CLOSED | No dependency manifest/lock changes; all38 frozen source hashes matched. No auditor install occurred; a source diff does not independently establish historical installation activity. |

Short runtime/test names above refer to `lib/threadline/operator_surface/` and `test/threadline/operator_surface/`; the presenter is `lib/threadline/policy/redaction_presenter.ex`, writers are `lib/threadline/evidence.ex`, and mounted declarations are in `examples/threadline_phoenix/e2e/tests/operator-route-states.spec.ts`. Plan line numbers refer to each phase plan's threat register.

## Retained engine flags

All six descriptorless prohibitions remain **flagged-unverified in the engine**. Verified behavior does not establish wired prohibition enforcement: do not silently widen/discard a search (01:79); invent a human actor/lookup (02:96); substitute latest for requested history (02:99); imply all-schema completeness (03:62); infer historical/export redaction correctness (04:80); or authenticate metadata/reveal arbitrary provenance/detail/actor values (04:83).

The four edge assumptions remain unclassified/unresolved: ADM-15 (01:152), ADM-18/19 (02:171–172), ADM-21 (04:147). No criterion or engine resolution is inferred. Available Plan01–03 summaries had no Threat Flags section; Plan04 summary was not available during audit. That is a reporting limit, not evidence that no other attack surface exists.

## Proof limits and disposition

The explicit Evidence outage boundary in [Plan04 continuation](251-04-BOUNDARY-CONTINUATION.md) is adequate for this ASVS1 audit: the existing owning LiveView/DB endpoint proves selected-reference unavailable/Retry and hidden diagnostics (Evidence tests604). The mounted example has no outage injection route; adding one or disrupting PostgreSQL is unnecessary and outside this audit's authority. The mounted case covers labels, latest/history, no-match, controlled copy and disabled host, not a browser-observed database outage.

Parent-reported execution is separately reconciled in [pair evidence](251-PAIR-EVIDENCE.md); the auditor does not independently certify test execution. Native clipboard/permissions, actual zoom, full-root repetition, hosted CI, broad browser/toolchain support and release readiness remain unverified. The consumed full-repeat stop remains effective. No user action is needed for this audit; parent completes the remaining phase gates.

## Independent bounded delta confirmation

The same security auditor confirmed revision da665edcb8590a86a209bc10acb1a98878c65353 against the initial5ef9f8bf review. All40 manifest hashes and seven declared source/test/style delta files matched; the additional planning continuation is bookkeeping. This confirmation supersedes the initial audit’s incomplete zero-configuration assessment under T-251-13. CR-01 is remediated, with no open threat or risk acceptance.

| Threat | Current status | Verified delta |
|---|---|---|
| T-251-10 | CLOSED | PolicyRedaction282 keeps config loading/parsing, reads and projection inside the safe rescue boundary;331 clears report/sections/time on failure. No diagnostic/raw-policy exposure was introduced. |
| T-251-13 | CLOSED | PolicyRedaction303 derives explicit configured keys for the selected schema;317 restricts comparison rows/groups/counts to those keys;444 separately counts deployed-but-unconfigured tables. Success time follows completed projection at291. Policy tests145 prove the old Presenter false-match premise, zero/other-schema negatives and explicit configured-empty positive. |
| T-251-SC | CLOSED | No dependency/lock/public router/runtime config/persistence-schema delta; other changes are existing Home typography and attributed style assertions/golden. |

The Presenter/public API is unchanged. The auditor inspected only this delta and necessary callees, reusing unchanged-source findings for the other threats; it wrote no files and ran no tests/builds/apps/browser/PG. All six prohibition flags and four edge assumptions retain unresolved engine statuses. Evidence outage, native clipboard/zoom/full-root/hosted limits and the consumed full-repeat stop are unchanged. Current verdict remains **SECURED,14 closed,0 open,0 accepted risks**.
