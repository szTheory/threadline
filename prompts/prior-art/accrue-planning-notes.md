# Accrue — planning pointers for Threadline (no `prompts/` tree)

Accrue keeps research and shipped discipline under **`.planning/`** only. High-signal paths for **verification, adoption, audit corpus, and CI**:

## Project spine

- `~/projects/accrue/.planning/PROJECT.md` — VERIFY-01 narrative, `examples/accrue_host`, Fake-backed CI, Playwright gates, host-first docs, Release Please / Hex alignment.

## Adoption + installer + CI clarity (v1.7 arc)

- `~/projects/accrue/.planning/phases/32-adoption-discoverability-doc-graph/` — doc graph, discoverability.
- `~/projects/accrue/.planning/phases/33-installer-host-contracts-ci-clarity/` — **installer ↔ host contracts**, CI semantics, `act` / job naming stability (see `33-CONTEXT.md`, `33-PATTERNS.md`).

## Operator / admin UX (patterns for future Threadline ops UI)

- `~/projects/accrue/.planning/phases/34-operator-home-drill-flow-nav-model/`
- `~/projects/accrue/.planning/phases/35-summary-surfaces-test-literal-hygiene/` — **`AccrueAdmin.Copy`**, test literal hygiene, VERIFY-01 bar.

## Audit corpus + integration hardening

- `~/projects/accrue/.planning/phases/36-audit-corpus-adoption-integration-hardening/` — **traceability matrix**, verifier ownership, forward-coupling notes; `36-PATTERNS.md` (single contributor entrypoint, three-source matrix: REQUIREMENTS + VERIFICATION + SUMMARY frontmatter, **immutable CI job ids** vs evolving `name:`).

## How Threadline should use this

- **Tamper-evident / corpus / traceability** language from phase **36** maps directly to audit **platform** maturity—not billing domain.
- **Host example + CI-equivalent verify** pattern from `PROJECT.md` is the adoption template for a future `examples/threadline_host` (or similar), without taking Accrue’s Stripe/Fake stack as a dependency.
