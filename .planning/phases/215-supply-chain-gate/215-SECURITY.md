---
phase: "215"
slug: "supply-chain-gate"
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: "2026-09-26"
---

# Phase 215 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| hex.pm registry → lockfiles | Package tarballs and advisory data are fetched from hex.pm; checksums in mix.lock pin what is fetched | Package tarballs, advisory metadata (public) |
| lockfile → published package | Root `mix.lock` does not ship, but CHANGELOG.md does and tells adopters what to do | Release notes (public) |
| PR author → CI | An untrusted PR can edit lockfiles, workflows, env and mix.exs; none of those edits may silently green the required gate on a vulnerable lock | Workflow YAML, env, mix.exs, mix.lock |
| CI runner → hex.pm | hex.audit / deps.get fetch advisory data and packages over the network | Advisory data, tarballs |
| contributor → mix.exs `:hex` config | A PR can add an ignore entry that silences hex.audit | Advisory suppression config |
| Developer machine → local gate | `~/.hex/hex.config` / HEX_HOME is machine state outside the repo | Global Hex client config |
| Gate → Hex client config | The gate trusts Hex's own report of its effective config (`mix hex.config KEY`) | Ignore lists |
| scheduled workflow → GitHub Issues API | GITHUB_TOKEN with `issues: write` can create/comment issues | Issue bodies (public) |
| Weekly lane → maintainer | The `ci-deps` issue and the lane's red/green are what the maintainer trusts between releases | Health classification |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-215-01 | Tampering | root mix.lock (mint via req→finch) | medium | mitigate | `mix.lock` pins mint 1.10.1 | closed |
| T-215-02 | Tampering | bench/mix.lock (postgrex, plug HIGH; decimal) | high | mitigate | bench/mix.lock no longer pins plug 1.19.1; group bump landed in 215-01 | closed |
| T-215-03 | Repudiation | advisory suppression shortcut | high | mitigate | No non-empty `ignore_advisories` in any audited mix.exs; enforced by T-215-06/T-215-11 controls | closed |
| T-215-04 | Information Disclosure | CHANGELOG.md in Hex tarball | low | mitigate | `test/threadline/release_artifact_contract_test.exs` scans the archive | closed |
| T-215-05 | Tampering | PR introducing a vulnerable dep | high | mitigate | `verify-deps-audit` job in `ci.yml`, listed in `ci-required` needs; deps_audit_contract_test guards removal/skip | closed |
| T-215-06 | Repudiation | HEX_IGNORE_ADVISORIES / HEX_IGNORE_RETIREMENTS env bypass | high | mitigate | `bin/verify-deps-audit` refuses both env vars before any mix call; contract test forbids them in workflows | closed |
| T-215-07 | Tampering | gate narrowed by args or env | medium | mitigate | `MIN_HEX` and canonical dirs are script literals in `bin/verify-deps-audit` | closed |
| T-215-08 | Spoofing | vacuous red/green | medium | mitigate | Self-test asserts `Advisories:` and `plug 1.19.1` text, not exit code alone | closed |
| T-215-09 | Elevation of Privilege | new job token scope | low | mitigate | `ci.yml` workflow-level `permissions: contents: read`; no write scope | closed |
| T-215-10 | Denial of Service | hex.pm outage turns required gate red | low | accept | See AR-215-01 | closed |
| T-215-11 | Repudiation | `hex: [ignore_advisories: ...]` in any mix.exs | high | mitigate | `ignore_advisories_contract_test.exs` requires reason/reachability/unexpired review_by per id, in default `mix test` | closed |
| T-215-12 | Repudiation | `ignore_retirements` suppression | medium | mitigate | Same contract test refuses any non-empty `ignore_retirements` | closed |
| T-215-13 | Tampering | literal-list bypass of metadata convention | medium | mitigate | Test reads `Mix.Project.config()[:hex]`, the value Hex actually uses | closed |
| T-215-14 | Repudiation | expiry never re-reviewed | low | mitigate | `review_by` on/before `Date.utc_today()` fails the suite (test "review_by equal to today is expired") | closed |
| T-215-15 | Elevation of Privilege | deps-health.yml token scope | medium | mitigate | Workflow-level `contents: read`; `issues: write` only on the `deps-health` job | closed |
| T-215-16 | Denial of Service | issue flood | medium | mitigate | `bin/upsert-ci-issue` marker dedup + workflow `concurrency` group | closed |
| T-215-17 | Repudiation | advisory silently unreported | medium | mitigate | Upsert/fail steps gate on `!= 'clean'`; `unknown` is the default arm in `bin/deps-health-report` | closed |
| T-215-18 | Tampering | report body injection | low | mitigate | `--body-file` argv passing; body capped at 60000 bytes | closed |
| T-215-19 | Spoofing | Dependabot version-update PR flood | low | mitigate | `.github/dependabot.yml`/`.yaml` absent, asserted by test | closed |
| T-215-20 | Information Disclosure | public issue body | low | accept | See AR-215-02 | closed |
| T-215-30 | Tampering / Repudiation | global Hex `ignore_advisories` / `ignore_retirements` (CR-01) | critical | mitigate | `refuse_global_hex_ignores` in `bin/verify-deps-audit` dies unless both are exactly `[]`; self-test case (c) against real Hex; re-verified exit 2 in 215-VERIFICATION | closed |
| T-215-31 | Tampering | workflow edit adding `HEX_HOME:` / `MIX_HOME:` / `hex.config ignore_` | high | mitigate | `forbidden_hex_surface/1` in `deps_audit_contract_test.exs` scans every workflow | closed |
| T-215-32 | Spoofing | unparseable `hex.config` output read as "no ignores" | high | mitigate | Fail closed with `could not read global Hex config`; offline tests per case | closed |
| T-215-33 | Elevation of Privilege | global check picking up project ids | medium | mitigate | Query runs in a fresh mix.exs-free `tmp/deps-audit-hex-config.*` dir | closed |
| T-215-34 | Tampering | lock drift re-resolved by plain `deps.get` (WR-02) | high | mitigate | `deps.get --check-locked`; self-test case (d) checks lock byte-identical; re-verified exit 1 in 215-VERIFICATION | closed |
| T-215-35 | Denial of Service | stricter gate red on dev machine with legacy global ignore | low | accept | See AR-215-03 | closed |
| T-215-36 | Tampering | MIX_EXS / MIX_HOME-installed patched Hex archive | medium | accept | See AR-215-04; MIX_HOME rejected in workflows by T-215-31; runtime hardening tracked in deferred-items.md | closed |
| T-215-40 | Tampering / Repudiation | weekly lane `clean` while a suppression is active | high | mitigate | `bin/deps-health-report` suppression check classifies `unknown` and skips all audits; offline tests for both keys and both env vars | closed |
| T-215-41 | Spoofing | unreadable `hex.config` read as "no ignores" (weekly) | high | mitigate | `could not read global Hex config` → `unknown` | closed |
| T-215-42 | Tampering | weekly report on re-resolved lock (WR-02/WR-03) | medium | mitigate | `deps.get --check-locked` in `bin/deps-health-report`; failure → `unknown` | closed |
| T-215-43 | Tampering | per-PR gate and weekly lane disagree on suppression | medium | mitigate | Same keys, neutral-dir rule (`tmp/deps-health-hex-config.*`) and parse; `deps_health_report_test.exs:392` asserts the key literal in both scripts | closed |
| T-215-44 | Denial of Service | legacy runner ignore turns weekly lane red weekly | low | accept | See AR-215-05 | closed |
| T-215-SC | Tampering | hex.pm package fetch / fixture fetch / package installs | low | accept | See AR-215-06 | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-215-01 | T-215-10 | Red on hex.pm outage is the fail-closed direction; a re-run clears it; noted in CONTRIBUTING | plan 215-02 threat model | 2026-09-26 |
| AR-215-02 | T-215-20 | Issue body holds only public Hex advisory metadata and versions of a public repo; no secrets or paths | plan 215-04 threat model | 2026-09-26 |
| AR-215-03 | T-215-35 | Fail-closed; the message names the key and the `mix hex.config KEY --delete` remedy | plan 215-05 threat model | 2026-09-26 |
| AR-215-04 | T-215-36 | Out of gap scope; workflow surface already closed by T-215-31; runtime hardening recorded in deferred-items.md | plan 215-05 threat model | 2026-09-26 |
| AR-215-05 | T-215-44 | Fail-closed; report names key and remedy; lane is non-required | plan 215-06 threat model | 2026-09-26 |
| AR-215-06 | T-215-SC | No new packages; only long-established existing deps move, pinned by mix.lock checksums; fixture fetched into gitignored tmp/ and never compiled | plans 215-01/02/05/06 threat models | 2026-09-26 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-09-26 | 33 | 33 (27 mitigated, 6 accepted) | 0 | /gsd-secure-phase orchestrator — ASVS L1 grep verification; auditor skipped per short-circuit (register authored at plan time, threats_open 0) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-09-26
