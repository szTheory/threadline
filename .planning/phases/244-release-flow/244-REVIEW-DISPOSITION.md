---
phase: 244
review: 244-REVIEW.md
titles: json
findings:
  - id: CR-01
    severity: critical
    disposition: fixed
    title: "retry_network/0 raises during project load on paths with whitespace or quotes"
    evidence: "244-09 23ef7071 (lazy RETRY_NETWORK wrapper) + f91ec4c2 (load-purity and env-pairing tests)"
  - id: WR-01
    severity: warning
    disposition: fixed
    title: "Dependency resolution failed marker never matches Hex's real message"
    evidence: "244-09 3c08524b (case-insensitive `dependency resolution failed` marker)"
  - id: WR-02
    severity: warning
    disposition: deferred
    title: "Denylist still retries common non-network failures"
    rationale: "A transient-signature allowlist needs a corpus of real Hex network-failure output, or it would turn genuine transients into hard failures and reopen REL-03. Today's cost is about 20s extra on a deterministic failure, never a wrong verdict."
  - id: WR-03
    severity: warning
    disposition: fixed
    title: "Exponential backoff has no cap"
    evidence: "244-09 3c08524b (60s per-delay cap, RETRY_NETWORK_BASE_DELAY max 30)"
  - id: WR-04
    severity: warning
    disposition: fixed
    title: "SIGINT/SIGTERM exit-at-once claim false while the command runs"
    evidence: "244-09 3c08524b (header corrected: signal during backoff exits at once, during an attempt is deferred until mix exits; 130/143 never retried)"
  - id: WR-05
    severity: warning
    disposition: deferred
    title: "Sync job push runs hooks/config with PUSH_TOKEN in env and URL (pre-existing)"
    rationale: "Pre-existing and outside phase 244 by the gap-closure scope (release.yml push and token behaviour are not touched here); routed to the next release-hardening work."
  - id: IN-01
    severity: info
    disposition: deferred
    title: "--date checked for shape only"
    rationale: "The date comes from the workflow's own `date -u`, the flag is a maintainer seam, and an impossible date fails verify-release-shape downstream."
  - id: IN-02
    severity: info
    disposition: deferred
    title: "--check exit 1 for both rename-pending and refusal"
    rationale: "No caller distinguishes the two outcomes today."
  - id: IN-03
    severity: info
    disposition: deferred
    title: "basename == mix check couples the MIX_BIN hook"
    rationale: "Both MIX_BIN users are test seams whose fakes are named `mix`; revisit when a real versioned shim appears."
  - id: IN-04
    severity: info
    disposition: deferred
    title: "Placeholder-only Unreleased block also stops install-pin sync"
    rationale: "The release PR still fails loudly at verify-release-shape, which names the real cause."
open: 0
total: 10
recorded: 2026-10-25T15:45:00Z
updated: 2026-10-25T16:35:00Z
---

# Phase 244: Code Review Disposition

| Finding | Severity | Disposition | Evidence / rationale | Source |
|---------|----------|-------------|----------------------|--------|
| CR-01 | critical | fixed | 244-09 `23ef7071` (lazy `RETRY_NETWORK` wrapper) + `f91ec4c2` (load-purity tests) | 244-REVIEW.md |
| WR-01 | warning | fixed | 244-09 `3c08524b` (real Hex `dependency resolution failed` marker) | 244-REVIEW.md |
| WR-02 | warning | deferred | Allowlist needs a corpus of real Hex network-failure output or it reopens REL-03; cost today is about 20s on a deterministic failure, never a wrong verdict | 244-REVIEW.md |
| WR-03 | warning | fixed | 244-09 `3c08524b` (60s delay cap, base delay max 30) | 244-REVIEW.md |
| WR-04 | warning | fixed | 244-09 `3c08524b` (signal header corrected to observed behaviour) | 244-REVIEW.md |
| WR-05 | warning | deferred | Pre-existing; release.yml push/token behaviour is outside phase 244's gap-closure scope; routed to the next release-hardening work | 244-REVIEW.md |
| IN-01 | info | deferred | Date comes from the workflow's own `date -u`; the flag is a maintainer seam; an impossible date fails `verify-release-shape` downstream | 244-REVIEW.md |
| IN-02 | info | deferred | No caller distinguishes rename-pending from refusal today | 244-REVIEW.md |
| IN-03 | info | deferred | Both `MIX_BIN` users are test seams with fakes named `mix`; revisit when a real versioned shim appears | 244-REVIEW.md |
| IN-04 | info | deferred | The release PR still fails loudly at `verify-release-shape`, which names the real cause | 244-REVIEW.md |
