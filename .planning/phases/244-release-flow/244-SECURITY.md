---
phase: "244"
slug: "release-flow"
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
block_on: high
register_authored_at_plan_time: true
created: "2026-10-25"
---

# Phase 244 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| repo files -> bin/date-release-changelog | `mix.exs` `@version` and `CHANGELOG*.md` content are parsed and fed to perl | version/date strings (untrusted text) |
| release branch -> PAT push | sync job pushes with `RELEASE_PLEASE_TOKEN` after compiling dependencies | PAT (secret) |
| release-please config -> GitHub | `always-update` force-pushes the release branch with the PAT | PAT (secret) |
| rehearsal clone -> contract verdict | stand-in prose could make the rehearsal pass for a reason the real release lacks | release-shape verdict |
| CI runner -> hex.pm / builds.hex.pm | network fetches (deps, Hex archive) that may fail transiently | package archives (integrity) |
| workflow author -> CI behaviour | a retry placed on a test step would hide flakes | test verdicts |
| mix alias / `__DIR__` path -> child shell | checkout or dependency path is outside project control | path text (injection surface) |
| mix.exs in the Hex package -> adopter project load | `project/0` runs inside every adopter's `mix deps.get` / compile | adopter build availability |
| release lane jobs -> PAT / HEX_API_KEY | Hex pin step runs before credential-bearing steps | secrets |
| tracked mix.lock -> bin/verify-lock-hygiene | lock text comes from any PR, including dependency-bump commits | untrusted Elixir term text |
| agent -> GitHub API / scratch repro | read-only `gh` queries; isolated Hex installs outside the repo | run/PR metadata |
| local Docker daemon -> gate database | throwaway postgres:16 the gate trusts for test data only | test data, throwaway password |
| agent-written .planning/ prose -> published main | `.planning/` is published, so prose must not leak home paths or the username | machine-local paths (PII) |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-244-01 | Tampering | bin/date-release-changelog perl rewrite | medium | mitigate | `bin/date-release-changelog:44,88` semver/date regexes; values reach perl only via `$ENV{VER}`/`$ENV{DATE}` (:114,:159); `test/threadline/date_release_changelog_test.exs` non-semver `$(touch x)` case | closed |
| T-244-02 | Information disclosure | sync job PUSH_TOKEN | high | mitigate | Date step (`release.yml:204-205`) has no `env:`; `PUSH_TOKEN` bound once (:212); ref checkouts keep `persist-credentials: false`; contract rule `date-no-token` | closed |
| T-244-03 | Repudiation | release PR born red silently | medium | mitigate | `bin/date-release-changelog:139` dies naming the rule on empty/placeholder-only Unreleased block | closed |
| T-244-04 | Elevation of privilege | always-update force-push | low | accept | `release-please-config.json:4`; same PAT and scopes; `permissions:` unchanged — see Accepted Risks | closed |
| T-244-05 | Repudiation | retry masking a real test failure | high | mitigate | `bin/retry-network:94-95` allowlist (`deps.get`/`local.hex`, exit 2 otherwise); rules `retry-no-test`, `retry-allowlist` with mutation controls | closed |
| T-244-06 | Tampering | third-party retry action supply chain | medium | mitigate | No retry `uses:` in any workflow; rule `retry-no-action` | closed |
| T-244-07 | Repudiation | retry hiding a permanent lock defect | medium | mitigate | `bin/retry-network:129-137` stops on 126/127/130/143 and deterministic markers; behaviour tests in `retry_network_contract_test.exs` | closed |
| T-244-08 | Denial of service | runaway retries | low | mitigate | Attempts bounded 1..10 (`bin/retry-network:77`); rule `retry-inline-shape` bounds inline loops | closed |
| T-244-09 | Tampering | retry_network path interpolated into `bash -lc` | low | mitigate | Superseded by T-244-26 (CR-01): the planned `Mix.raise` guard was removed from `project/0`; the path now travels in `RETRY_NETWORK` env and is expanded quoted (`mix.exs:271-287`) — strictly stronger | closed |
| T-244-10 | Repudiation | hex-evaluator tests silently retried | high | mitigate | Only the leading `mix deps.get` is wrapped (`mix.exs:287,297,310`); wrapper allowlist refuses `mix test`; rules `retry-unwrapped`/`retry-allowlist` mutation controls | closed |
| T-244-11 | Repudiation | lock-drift gate weakened by retries | medium | mitigate | `FAKE_LOCK_DRIFT` single-call test in `deps_audit_gate_test.exs` | closed |
| T-244-12 | Tampering | floating Hex version in CI | medium | mitigate | `install-hex: false` + `mix local.hex 2.6.0 --force` in every setup-beam job; rules `pin-install-hex-off`, `pin-step`, `pin-uniform` (`hex_pin_contract_test.exs`) | closed |
| T-244-13 | Repudiation | local gate accepting a lock CI rejects | medium | mitigate | Literal `MIN_HEX="2.6.0"` (`bin/verify-deps-audit:66`); rule `pin-floor` | closed |
| T-244-14 | Tampering | Hex archive integrity | low | accept | `mix local.hex` over HTTPS with signature verification; no checks disabled — see Accepted Risks | closed |
| T-244-15 | Tampering | unpinned Hex in any job | medium | mitigate | Pin steps across ci/browser-full/deps-health/flake-detection/release; `pin-*` rules over `all_workflows()` | closed |
| T-244-16 | Information disclosure | release.yml credential anchors disturbed | high | mitigate | Pin inserted before ref checkouts; `persist-credentials: false` anchors intact (`release.yml:68,157,188,505,534,703,732`); `release_control_plane_contract_test.exs` unchanged | closed |
| T-244-17 | Denial of service | transient builds.hex.pm failure on release-lane pins | low | mitigate | Inline 3-attempt loop with 10s/20s sleeps (`release.yml:169-180,517,715-727`); rules `pin-step`, `retry-inline-shape` | closed |
| T-244-18 | Tampering | REL-02 evidence produced by a manufactured release | medium | mitigate | `244-REL02-EVIDENCE.md:22` prohibition; read-only `gh` only; status pending natural release cycle | closed |
| T-244-19 | Information disclosure | evidence file leaking machine-local paths | low | mitigate | `bin/verify-repo-hygiene` clean (re-run 2026-10-25, exit 0) | closed |
| T-244-20 | Tampering | reproduction altering tracked locks | low | mitigate | Isolated `MIX_HOME`/`HEX_HOME` under scratch, pristine lock restore (`244-07-SUMMARY.md:108`) | closed |
| T-244-21 | Repudiation | rehearsal stand-in laundering a born-red cause | medium | mitigate | Stand-in seeded only when placeholder-only and disclosed on stdout; production dating script called in real order (`244-02-SUMMARY.md:53,69`) | closed |
| T-244-22 | Denial of service | recovery publish of a pre-phase tag missing bin/retry-network | medium | mitigate | publish-hex uses inline retry with no repo-file reference (`release.yml:714-727`); rule `retry-ref-independent` with mutation control | closed |
| T-244-23 | Tampering / Elevation | bin/verify-lock-hygiene parsing a hostile mix.lock | high | mitigate | `Code.string_to_quoted/2` only (`bin/verify-lock-hygiene:15,103`); 0 occurrences of `eval_` | closed |
| T-244-24 | Repudiation | `[]` manager lock passing on warm deps/ | medium | mitigate | Lock-text-only check run per directory inside `bin/verify-deps-audit:335` before fetch; fake-mix test in `deps_audit_gate_test.exs` | closed |
| T-244-25 | Denial of service | malformed lock crashing or passing vacuously | low | mitigate | `System.halt(2)` fail-closed paths (`bin/verify-lock-hygiene:75,168`) | closed |
| T-244-26 | Tampering / Elevation | mix.exs fetch scripts built from `__DIR__` | high | mitigate | `RETRY_NETWORK` env var expanded quoted (`"$RETRY_NETWORK"`), never spliced into shell text (`mix.exs:271-287`) | closed |
| T-244-27 | Denial of service | adopter project load raising in `project/0` | high | mitigate | No path computation/guard in `project/0`/`aliases/0` (lazy, `mix.exs:281`); rule `alias-load-pure` with eager-guard mutation control | closed |
| T-244-28 | Denial of service | unbounded backoff in bin/retry-network | medium | mitigate | `max_delay=60`, `RETRY_NETWORK_BASE_DELAY` ≤ 30 (`bin/retry-network:87-90`); tests `retry_network_contract_test.exs:199-233` | closed |
| T-244-29 | Repudiation | deterministic Hex resolution failure retried 3x | low | mitigate | Real Hex text, case-insensitive match (`bin/retry-network:132-137`); real-output fixture test | closed |
| T-244-30 | Information disclosure | ephemeral postgres:16 container | low | mitigate | `-p 127.0.0.1::5432`, throwaway password, trap teardown, leftover-label check (`244-10-SUMMARY.md:40`) | closed |
| T-244-31 | Information disclosure | SUMMARY/disposition prose in published .planning/ | medium | mitigate | Placeholder path shapes; `bin/verify-repo-hygiene` clean (`244-10-SUMMARY.md:50,63`; re-run exit 0) | closed |
| T-244-32 | Repudiation | gate "pass" from a wrapper's status | medium | mitigate | Exit with `${PIPESTATUS[0]}` plus decisive-log-line assertions (`244-10-PLAN.md:85-89`, `244-10-SUMMARY.md:40-50`) | closed |
| T-244-SC | Tampering | npm/pip/cargo/hex installs | low–high | mitigate / accept | No package installs in any plan; only the version-pinned Hex archive; no new `uses:`; postgres:16 used `--pull never` — see Accepted Risks | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-244-01 | T-244-04 | `always-update` force-pushes the release branch with the same PAT and scopes release-please already uses; no new secret or permission; `ci_token_permissions_contract_test.exs` untouched | plan 244-01 threat model | 2026-10-25 |
| AR-244-02 | T-244-14 | Hex archive fetched over HTTPS from builds.hex.pm with signature verification; integrity rests on Hex's own controls | plan 244-05 threat model | 2026-10-25 |
| AR-244-03 | T-244-SC | Plans 244-08..10 install no package; the only external artefacts are the pinned Hex archive and a pre-cached postgres:16 image (`--pull never`) | plans 244-08/09/10 threat models | 2026-10-25 |

---

## Notes

- Out-of-register review findings deferred in `244-REVIEW-DISPOSITION.md` (not threat-register items): WR-05 (sync-job push with `PUSH_TOKEN` while git hooks can run — pre-existing, routed to the next release-hardening work) and WR-02 (retry denylist breadth). Neither was introduced by this phase.
- REL-02 live evidence remains pending a natural release cycle (`244-REL02-EVIDENCE.md`); that is a verification item, not an open threat.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-25 | 33 | 33 | 0 | /gsd-secure-phase (orchestrator, ASVS L1 grep-depth; auditor skipped per short-circuit rule) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-10-25
