## Current Milestone: v1.43 Supply Chain, CI Economy and Repo Hygiene

**Goal:** Close the known dependency advisory behind a CI audit gate, make every CI job earn its runner minutes and read clearly, and keep the public repo free of local paths. Measure a baseline first, fix the lowest-risk waste first, and ship as a patch.

**Baseline (measured 2026-09-26, `5e78b2f0` main green, 0 open PRs; re-measured 2026-09-26 in Phase 214, see `.planning/phases/214-baseline-measurement/214-BASELINE.md`):**
- Flake Detection: 79 consecutive scheduled fast failures (under 10 min each), 07-01→09-12 (runs 28225855438 → 34679766829; the last failed on a broken main that CI already reported), then 12 cancellations at 51 repeats × ~165 s past the old 120-min timeout (09-13→09-24), then 2 green (98 and 137 min) under the current 180-min timeout. It has never classified a run as `flaky`, and its issue #36 posted 11 misleading "unknown" comments. About 3,000–4,100 runner-min/month.
- `mix hex.audit` exits 1 on 2 advisories in the root `mix.lock`. mint 1.10.0 (MEDIUM, EEF-CVE-2026-82672 / GHSA-rj5m-69wp-cxq9, response smuggling) comes in through the optional runtime dependency req → finch → mint; fixed in 1.10.1. lazy_html 0.1.12 (LOW, test-only, EEF-CVE-2026-92106 / GHSA-8rqp-v692-v82q, mutation XSS) is fixed in 0.1.13. Both fixes are lockfile-only. `bench/mix.lock` has 8 advisories, 3 HIGH in bench (postgrex 0.22.0 ×1, plug 1.19.1 ×2), plus 3 MEDIUM and 2 LOW across decimal 2.3.0, postgrex and plug. `examples/threadline_phoenix/mix.lock` is clean (hex.audit exit 0). No audit gate in CI. Dependabot alerts are disabled on the repo.
- CI wall time, p50 from `214-BASELINE.md` sections 2 and 5 (ci.yml n=20 per event; Browser-full successful runs since 2026-08-27, n=19 push and n=14 nightly): PR 10.5 min (run 34758417725), push 10.7 min (run 34755997103). Browser-full: 18.0 min on every push to main (run 35780709940) plus 14.5 min nightly (run 34932091760).
- Machine-local paths: 387 tracked files at `e58aa067` match an absolute home path (a `Users` or `home` root) or a home-relative tilde-slash path, by `git grep -l -I -E` with both regexes (`.planning/phases/214-baseline-measurement/tools/measure-base02.sh paths`). That total is 383 under `.planning/`, 2 in `prompts/prior-art/` and 2 in `.github/workflows/` (the runner's Playwright cache path, not a maintainer path). Absolute paths alone: 303 files. origin/main `5e78b2f0`: 345 files (292 absolute).
- Also found: CI's `otp-version: "27.0"` resolves to 27.0.1, `.tool-versions` was untracked, 3 actions still declare Node 20 (removed 2026-09-23), the min lane's `ubuntu-22.04` is deprecated, and the release PR is dispatched twice (9 SHA pairs).
- `mix xref graph --format cycles --label compile-connected`: clean, and already gated by `verify.xref_cycles` (in `ci.all` and both test lanes). Without the label there are 5 runtime cycles of length 2, including `Capture.AuditTransaction`↔`Semantics.AuditAction`, which crosses the capture and semantics layers.

**Target features:**
- Supply chain: fix the advisories (root and bench), add a CI audit gate, set a dependency-freshness policy (not dependabot churn)
- CI economy (measured first): a broken/costly Flake Detection lane fixed or re-scoped, duplicate proofs removed, the release-PR double dispatch, Browser-full re-running CI projects, a deps-only `_build` cache, and an uncached live-Dialyzer test (540 s timeout) that runs in both test lanes and in every flake iteration
- CI DX: job names say what failed, and the fastest likely failure comes first
- Platform currency: commit `.tool-versions`, exact OTP, Node 24 actions, a supported min-lane runner
- One lane on the newest PostgreSQL/Elixir (spike first)
- tmp_dir hygiene: leaking tests moved to `@tag :tmp_dir` (no temp-dir flake is recorded)
- Repo hygiene: a PII/local-path CI guard, a forward scrub of tracked files (no history rewrite), and no runtime-cycle gate: the existing compile-connected `verify.xref_cycles` gate stays (0 compile-connected cycles), and the 5 runtime cycles of length 2 stay ungated (2 are Ecto schema pairs; 3 are module pairs in the operator-surface checker, `Threadline`↔`Investigation`, and the critic.measure task). The capture↔semantics edge is logged for the v1.45 API/architecture review.
- SEED-006: change-aware lanes behind a tested fail-closed classifier (last phase, only after the cheap wins are measured)

**Deferred to v1.44:** v1.42 debt (gen.triggers `down` leaves an orphaned rerun per-table function; `mix threadline.gen.backfill`; health `--strict`).

