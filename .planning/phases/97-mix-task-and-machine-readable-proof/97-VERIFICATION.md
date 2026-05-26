---
phase: 97-mix-task-and-machine-readable-proof
verified: 2026-05-26T04:58:20Z
status: passed
score: 8/8 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: passed
  previous_score: 8/8
  gaps_closed: []
  gaps_remaining: []
  regressions: []
---

# Phase 97: Mix-Task And Machine-Readable Proof Verification Report

**Phase Goal:** Give operators and CI a stable no-Phoenix path to generate and inspect evidence outputs.
**Verified:** 2026-05-26T04:58:20Z
**Status:** passed
**Re-verification:** Yes - current tree after follow-up fixes

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Threadline ships one canonical no-Phoenix evidence viewer task instead of a family of per-subject tasks. | ✓ VERIFIED | `Mix.Tasks.Threadline.Evidence.Show` is the canonical viewer task, advertises overview/latest/history usage, and defaults to one task surface. See `lib/mix/tasks/threadline.evidence.show.ex:1-29`, `lib/mix/tasks/threadline.evidence.show.ex:36-70`. |
| 2 | The task is a thin wrapper over `Threadline.Evidence` read helpers and does not introduce task-local SQL or a second read model. | ✓ VERIFIED | The task only parses argv, validates inputs, and delegates to `Proof.proof_document/2`; the proof layer reuses `Evidence.list_overview/2`, `list_latest_subject_refs/3`, `get_latest_subject_ref/3`, `list_subject_ref_history/4`, and `list_history/2`. See `lib/mix/tasks/threadline.evidence.show.ex:91-97`, `lib/threadline/evidence/proof.ex:17-40`, `lib/threadline/evidence/proof.ex:83-105`. |
| 3 | The machine-readable proof output is one stable wrapped JSON document with explicit top-level contract keys. | ✓ VERIFIED | The proof document emits `format_version`, `generated_at`, `proof_type`, `subject`, `mode`, `filters`, `summary`, `claim_assessment`, and `records`, and tests lock that wrapper. See `lib/threadline/evidence/proof.ex:27-40`, `test/threadline/evidence/proof_test.exs:30-52`, `guides/domain-reference.md:82-111`. |
| 4 | Overview mode covers the full closed six-subject evidence inventory by default. | ✓ VERIFIED | `Evidence.list_overview/2` iterates `Subject.supported_subjects/0`, and tests prove both six-subject coverage and the follow-up global overview limit fix. See `lib/threadline/evidence.ex:124-143`, `test/threadline/evidence/proof_test.exs:55-77`, `test/threadline/evidence_test.exs:203-250`. |
| 5 | Proof outputs explicitly distinguish `proven`, `inferred_posture`, and `unsupported` instead of collapsing all non-happy paths into failure. | ✓ VERIFIED | The classifier separates semantic verdicts from error statuses and chooses explicit unsupported/posture/direct-fact outcomes. See `lib/threadline/evidence/proof.ex:8-12`, `lib/threadline/evidence/proof.ex:108-190`, `test/threadline/evidence/proof_test.exs:79-145`. |
| 6 | Unsupported claims remain valid machine-readable outputs and do not masquerade as runtime errors. | ✓ VERIFIED | Empty/unsupported reads still return a wrapped `claim_assessment`, and the CLI tests prove unsupported JSON is decodable and the task still returns `:ok`. See `lib/threadline/evidence/proof.ex:108-130`, `lib/mix/tasks/threadline.evidence.show.ex:64-70`, `test/mix/tasks/threadline.evidence_show_test.exs:116-155`. |
| 7 | Threadline names only the claims it owns and leaves host-owned or external guarantees outside its proof authority. | ✓ VERIFIED | Unsupported reasons like `host_owned_authorization` remain explicit, posture subjects are inferred instead of overclaimed, and docs preserve the host-owned boundary. See `lib/threadline/evidence/proof.ex:143-190`, `guides/domain-reference.md:94-111`, `guides/integration-contracts.md:110-117`. |
| 8 | Human-readable output and machine JSON use the same underlying verdict semantics. | ✓ VERIFIED | The task builds one proof document, then renders either JSON or human output from that same structure; the follow-up subject-aware human output path is covered by the unsupported CLI test. See `lib/mix/tasks/threadline.evidence.show.ex:62-68`, `lib/threadline/evidence/proof.ex:60-70`, `test/mix/tasks/threadline.evidence_show_test.exs:139-154`. |

**Score:** 8/8 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/mix/tasks/threadline.evidence.show.ex` | Canonical CLI proof viewer with bounded filters and `--json` | ✓ VERIFIED | Exists, is substantive, rejects invalid flags, validates bounded inputs, and delegates proof shaping to the library layer. |
| `lib/threadline/evidence/proof.ex` | Reusable proof projection and wrapped JSON builder | ✓ VERIFIED | Exists, is substantive, and is wired to the public evidence read helpers with explicit verdict semantics. |
| `lib/threadline/evidence.ex` | Existing public evidence boundary reused by proof projection | ✓ VERIFIED | Supports overview, latest, subject-ref latest, and history reads; overview limit now applies after combining all supported subjects. |
| `test/mix/tasks/threadline.evidence_show_test.exs` | Executable CLI proof for default, JSON, invalid flags, bounded history, and unsupported output | ✓ VERIFIED | 6 task-facing tests passed. |
| `test/threadline/evidence/proof_test.exs` | Executable proof for wrapped contract, six-subject overview, and verdict semantics | ✓ VERIFIED | 5 proof tests passed. |
| `test/threadline/evidence_test.exs` | Evidence API proof for overview and append-only latest/history behavior | ✓ VERIFIED | Covers six-subject overview and combined-inventory `limit`. |
| `guides/domain-reference.md` | Public documentation of wrapper keys and verdict vocabulary | ✓ VERIFIED | Documents `claim_assessment`, wrapper fields, and the proof-language boundary. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `lib/mix/tasks/threadline.evidence.show.ex` | `lib/threadline/evidence/proof.ex` | task delegates all proof shaping to the library layer | ✓ WIRED | `proof_document/2` constructs request opts and pipes them to `Proof.proof_document/2`. |
| `lib/threadline/evidence/proof.ex` | `lib/threadline/evidence.ex` | proof projection must reuse latest/history helpers instead of direct SQL | ✓ WIRED | `fetch_records/5` calls `list_overview`, `list_latest_subject_refs`, `get_latest_subject_ref`, `list_subject_ref_history`, and `list_history`. |
| `test/mix/tasks/threadline.evidence_show_test.exs` | `lib/mix/tasks/threadline.evidence.show.ex` | CLI contract tests must exercise the shipped task | ✓ WIRED | Tests invoke `Mix.Tasks.Threadline.Evidence.Show.run/1` directly for default, JSON, invalid-flag, and unsupported paths. |
| `test/threadline/evidence/proof_test.exs` | `lib/threadline/evidence/proof.ex` | verdict tests must lock exact enum strings and unsupported semantics | ✓ WIRED | Tests assert `proven`, `inferred_posture`, `unsupported`, and proven negative-fact behavior. |
| `guides/domain-reference.md` | `lib/threadline/evidence/proof.ex` | docs should describe the shipped contract, not a speculative variant | ✓ WIRED | Docs list the actual wrapper keys and the shipped verdict vocabulary. |
| `lib/threadline/evidence/proof.ex` | `guides/integration-contracts.md` | proof semantics must preserve the host-owned authority boundary | ✓ WIRED | Integration docs still reserve auth/tenant/policy meaning to the host. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `lib/threadline/evidence/proof.ex` | `records` | `fetch_records/5` -> `Threadline.Evidence` read helpers -> `EvidenceRecord` Ecto queries | Yes | ✓ FLOWING |
| `lib/mix/tasks/threadline.evidence.show.ex` | `document` | `Proof.proof_document/2` rendered through `render_json/1` or `render_human/1` | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| CLI viewer keeps JSON, unsupported, and invalid-flag behavior green | `mix test test/mix/tasks/threadline.evidence_show_test.exs --max-failures 1` | `6 tests, 0 failures` | ✓ PASS |
| Proof contract and verdict semantics stay green | `mix test test/threadline/evidence/proof_test.exs --max-failures 1` | `5 tests, 0 failures` | ✓ PASS |
| Phase-owned task + proof slice passes together | `mix test test/mix/tasks/threadline.evidence_show_test.exs test/threadline/evidence/proof_test.exs --max-failures 1` | `11 tests, 0 failures` | ✓ PASS |
| Evidence read API honors six-subject overview and combined global limit | `mix test test/threadline/evidence_test.exs --max-failures 1` | `9 tests, 0 failures` | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| `PROOF-02` | `97-01` | Mix-task parity exists for the milestone's evidence subjects, including stable machine-readable output for CI, procurement, or audit handoff. | ✓ SATISFIED | Canonical `mix threadline.evidence.show`, stable wrapped JSON, six-subject overview, invalid-flag validation, and passing CLI/proof/API tests. |
| `PROOF-03` | `97-02` | Evidence outputs clearly distinguish proven facts, inferred posture, and unsupported claims. | ✓ SATISFIED | Proof classifier, CLI rendering, and docs all encode the exact verdict vocabulary and keep unsupported claims as valid output. |

No orphaned phase-97 requirements were found in `.planning/REQUIREMENTS.md`.

### Anti-Patterns Found

No blocker or warning anti-patterns were found in the phase-owned implementation files. The Mix task contains no direct SQL or placeholder logic, and the proof/data paths are wired to real evidence reads.

### Human Verification Required

None.

### Gaps Summary

No phase-owned gaps found on the current tree. The follow-up fixes called out by the user are present in code and tests:

- Invalid CLI flags fail fast via explicit unknown-option handling in `validate_argv!/2`.
- Overview `limit` is applied after combining the full supported subject inventory.
- Human-readable output is rendered from the same proof document and remains subject-aware for non-overview reads.

---

_Verified: 2026-05-26T04:58:20Z_  
_Verifier: Claude (gsd-verifier)_
