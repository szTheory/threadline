---
phase: 252-complete-operations-and-connected-catalog-review
audited: 2026-11-13
reviewed_revision: e79f7837e6e9817e739933c85d9579f436f42446
baseline_revision: b1888177648ef468c6d2bfc1cc1645f860fd2e4b
status: open_threats
verdict: OPEN_THREATS
level: ASVS1
block_on: high
threats_total: 12
threats_secured: 9
threats_open: 3
accepted_risks: []
---

# Independent security audit — initial verdict

The independent `phase252_security_review` auditor returned OPEN_THREATS. Parent persisted its structured findings because the auditor role is read-only. All19 frozen source hashes and reviewed HEAD matched. Actual runtime is7cca0a18; subsequent reviewed source changes are test/planning only. No tests/builds/apps/DB/browser/install operations were performed by this auditor. This is mitigation verification, not release acceptance. Original initial findings remain below; any later delta must preserve them.

| Unique threat | Initial disposition | Actual evidence |
|---|---|---|
|T-252-01 authorization|Secured|retention_history_live.ex101–110,190–229,250–257,280–304,488–534: server-held preview, event and completion authorization, constant-time token, identifiable actor, audit before exact trigger. Existing direct-forged-event tests192–294,897–1050.|
|T-252-02 exact target|Secured|pruner.ex49–83,135–146 allowlists original PID/repo/schema/sleep and compares full target before accepting. LiveView250–285 rechecks target/policy, audit526–534 uses it. Pruner67–91 and LiveView298–415 test stale/replacement/mismatch refusal.|
|T-252-03 outcome truth|OPEN high|components.ex140–144 coalesces failed-run nil deletion count to0 in Outcome prose. Existing missing-measurement LiveView test418–475 and static :many failed/nil fixture321–326 reach it; cells/aggregate correctly say unknown.|
|T-252-04 static authority|Secured|LiveView235–244,411–475 owns events/form. Shared renderers contain presentation only; stories have no destructive events/target. Actual-tag and target-free tests260–339.|
|T-252-05 mappings|Secured|Node validator380–414,501–526 checks real source/proof references; malformed/missing/duplicate/wrong-owner1144–1200 and stale-preview-anchor1204–1212 negative controls. Story links352–367.|
|T-252-06 fictional catalog|Secured|Literal deterministic projections fixtures.ex175–400 use Manifest/presentation helpers, no Repo/seeder/mutation/file output. Ordinary/stress separated; limitations visible/documented.|
|T-252-07 reconnect|Secured|Mounted new case1928–1995 observes unchanged real SQL rows offline and reconnected, cleared authority, rotated revision, fresh deliberate one-request/completed-run. Mutation script52–112 and LiveView mount35–45 support it. Two-case report retry0.|
|T-252-08 Export boundary|Secured|Router121–140 requires ExportAuthPlug. Separate authorization13–66; immediate scoped controller169–191,203–225,250–253; owner/status/expiry/file28–155 and storage/local56. Scoped queue refusal/actor-owned pending live63–134; owning HTTP/LiveView tests.|
|T-252-09 proof custody|Secured|Exact owned DB/port/partition/origin/readiness/no-overwrite guards1908–1935; mutation seal hashes match. Current selected capture/reconciliation digests and ordinary materializations match; both preview lanes preserve all audit/operation counts.|
|T-252-10 independent judgment|OPEN high|Assignments exist but complete source/UI/security judgments, UAT/disposition are not yet materialized. Planned controls are not completed controls.|
|T-252-11 final integrity|OPEN high|Actual final independent source/record fingerprint does not yet exist. Completed-record ordering and changed-record refresh cannot close from a planned invocation.|
|T-252-SC supply chain|Secured|Repeated register row counted once. No dependency/lock/package-manifest/runner changes or installation path in frozen scope. Existing legitimacy checkpoint remains applicable to a separately proposed installation.|

## Product finding and required remedy

**High — Unknown failed-run deletion outcome is presented as recorded zero.** At `lib/threadline/operator_surface/live/retention_history_live/components.ex:140`, `run.deleted_count || 0` produces a definite zero-removal claim when persistence contains no measurement. Render an explicit unrecorded-count failure sentence for nil, preserve recorded zero/one/many and safe category whitelist, and add Outcome assertions in the existing test owner. This high classification follows the authored register; it blocks affected acceptance.

T-10/T-11 remain actual closeout obligations: materialize independent judgments/UAT/dispositions/sampling/summaries, then actual independent fingerprint and necessary bounded changed-record refresh. The same auditor can confirm only these records and the product correction; no repeated full audit or runtime suite is needed for metadata.

## Other inspected boundaries and limits

Original trigger/0 and :prune handler remain supported (Pruner34–46,145–146); positive compatibility control follows stale-target refusal67–91. Mounted/worker mismatch refuses instead of retargeting; include both facts in253 migration notes. Guarded acknowledgement loss returns acceptance_unknown62–74, UI clears authority and explains possible queued request129–139 without retry/relookup. Causal after-audit suspension test150–189 exists.

Mutation proof records225 changes and133 empty transactions removed,358 stored rows, after unchanged offline/reconnect stages and one deliberate request. Current14 captures comprise4 paired defaults plus10 after-only scenes; clocks differ, before raw theme is null from retained selector error, housekeeping setup differs. No default-cleanup, broad accessibility, native clipboard, foreground, hosted or release acceptance is established. All three descriptorless prohibitions remain flagged-unverified; independent product intent is assessed separately. Two unclassified edges remain unresolved. No risk acceptance and no unregistered attack-surface flag identified.
