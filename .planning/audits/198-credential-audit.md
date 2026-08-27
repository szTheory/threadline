# Phase 198 Credential Audit (D-28 / D-29)

**Scanned:** 2026-08-27
**Scope:** full git history (`--all --full-history`) plus the untracked working tree, ahead of the first `git push` of this phase's 587 unpushed commits.
**Gate:** D-34 step 4. This audit gates step 5 (push) on **any** ref — the staging-branch push in Plan 03 is the disclosure event just as much as the `main` push in Plan 07.

This artifact never quotes a live secret string. Findings are referenced by rule id, file path, and commit SHA only, because this file is itself about to be published.

---

## VERDICT: PROCEED

**Determined:** 2026-08-27T20:02:01Z

Five findings across four sweeps. **Zero Class A. Zero Class B. Five Class C.** No credential requires rotation, and nothing blocks the push under D-29.

Basis:

- No Class B finding exists — no third party's credential, no customer or user personal data, no NDA'd vendor terms appear anywhere in the 2381 commits scanned.
- No Class A finding exists, so the D-29 invariant "rotation happens before `git push`, never after" is vacuously satisfied. There is no rotation timestamp to record because there is nothing to rotate.
- trufflehog verified mode — the one engine that tests liveness against the issuing provider — returned **zero verified and zero unverified secrets** over the full history.
- No `.env`, `.pem`, `id_rsa`, or `.netrc` file was ever added in the repository's history.

**This verdict covers credentials only.** Per D-30, content disclosure is explicitly *not* a gate: the `.planning/` history publishes as-is, including LLM spend figures and internal quality assessments. See `## Known disclosure surface (D-30, accepted)` below for what that means concretely. The maintainer's one-way authorization for that publication is a separate gate, recorded under `## D-30 authorization`.

**One judgment call is flagged for the maintainer** rather than settled silently — findings F-002 and F-003 (the example app's dev/test `secret_key_base` literals). See the register reason column and the note beneath it.

---

## Finding register

Every finding from every sweep gets exactly one row. No class is decided verbally (D-29).

| id | source scan | rule id | file path | commit SHA | class | reason | action taken | timestamp |
|----|-------------|---------|-----------|------------|-------|--------|--------------|-----------|
| F-001 | sweep 1 (gitleaks history) + sweep 2 (gitleaks worktree) | `generic-api-key` | `.planning/phases/101-phase-96-verification-backfill/101-02-SUMMARY.md:118` (now at `.planning/milestones/v1.22-phases/101-phase-96-verification-backfill/101-02-SUMMARY.md:118`) | `2c359ee5eb7c8c917b0d2e258fca686bf6f4dbb4` | C | False positive. The regex matched English prose in a planning summary — the phrase `Key shape constraints:` followed by a backticked **filename** (`95-VALIDATION.md`). No credential of any kind; the "secret" is a markdown document name. | None required. Recorded. | 2026-08-27T20:02:01Z |
| F-002 | sweep 1 (gitleaks history) + sweep 2 (gitleaks worktree) | `generic-api-key` | `examples/threadline_phoenix/config/dev.exs:27` (HEAD line 33) | `09caeb3000254da7f22df97c811e8b2db19ae9bc` | C | Example value. The Phoenix **example app's** development `secret_key_base`, emitted by `mix phx.new` and checked in by upstream Phoenix's own design. The example app has no deployed instance — it runs on localhost and in CI only. Production is env-sourced: `examples/threadline_phoenix/config/runtime.exs:64` reads `System.get_env("SECRET_KEY_BASE")` and raises if absent, and its own comment states the dev/test defaults are intentionally checked in. Compromise value is nil — it would forge session cookies for a local demo whose login credentials are printed on its own login page. | None required. Recorded. Flagged to maintainer — see note below. | 2026-08-27T20:02:01Z |
| F-003 | sweep 1 (gitleaks history) + sweep 2 (gitleaks worktree) | `generic-api-key` | `examples/threadline_phoenix/config/test.exs:21` (HEAD line 31) | `09caeb3000254da7f22df97c811e8b2db19ae9bc` | C | Example value. Identical rationale to F-002 — the example app's **test** `secret_key_base`. Same generator origin, same absence of a deployed instance, same env-sourced production path. | None required. Recorded. Flagged to maintainer — see note below. | 2026-08-27T20:02:01Z |
| F-004 | sweep 4 (ever-added sweep) | filename glob `*.env.*` | `.env.example` | `5431462016e9ee90f750bc47752dc001086c730c` | C | Filename match, not a credential match. `.env.example` is a committed template of Docker host/port defaults (`COMPOSE_PROJECT_NAME`, `THREADLINE_DB_HOST`, `THREADLINE_DB_PORT`, `THREADLINE_DEMO_PORT`, `THREADLINE_PGBOUNCER_PORT`, `THREADLINE_E2E_PORT`). Content inspected at the adding commit: no secret values, by construction — it is the template one copies *to* `.env`, and `.env` itself is gitignored (`.gitignore:26-28,79`). | None required. Recorded. | 2026-08-27T20:02:01Z |
| F-005 | sweep 4 (ever-added sweep) | filename glob `*credentials*` | `.planning/todos/pending/2026-06-20-demo-login-copy-credentials.md` | `231687f92e776795efef35166a9da16b1628e1b8` | C | Filename match, not a credential match. The word `credentials` appears in the todo's **title**. Content is a UX note proposing a copy-to-clipboard affordance for the example app's *deliberately visible* demo login, which the page already renders as plain text on purpose. The demo account exists only in the example app's seeded local database. Not referenced by value here. | None required. Recorded. | 2026-08-27T20:02:01Z |

**Class counts: A = 0 (rotated: 0) · B = 0 · C = 5.**

### Flagged judgment call — F-002 / F-003

These two are classified **C (example value)** rather than **A (rotatable credential we control)**, and the reasoning is recorded here rather than left implicit, because it is the one disposition in this audit that a reasonable maintainer could decide differently.

The case for C, which is what was applied: a `secret_key_base` is a real cryptographic secret *shape*, but these two instances guard nothing. They belong to a bundled example application with no deployment, whose production configuration reads the value from the environment, and whose demo login credentials are printed on its own login page by design. D-29's Class C explicitly covers "example value". Recording a fabricated "rotation" for a value that protects no live surface would put a misleading rotation timestamp in a published register — the precise kind of laundering this phase's artifacts exist to prevent.

The case a maintainer might make for A: rotation is nearly free (`mix phx.gen.secret`, replace two literals), and "rotate anything secret-shaped" is a defensible blanket policy for an audit vendor's own repository.

**This is surfaced at the Task 3 decision gate.** If the maintainer prefers the blanket policy, F-002/F-003 are re-dispositioned as Class A, rotated before any push, and this register updated with real rotation timestamps — which D-29 permits without changing the PROCEED verdict, since Class A rotation proceeds to push.

---

## Known disclosure surface (D-30, accepted)

D-30 records the maintainer's posture as **publish as-is, no content sweep**: an audit library that shows its own record is on-brand and defensible, and the record is treated as an asset. What the push publishes:

| Measure | 198-CONTEXT.md ground_truth (2026-08-27) | Re-measured at audit time | Note |
|---|---|---|---|
| Tracked `.planning/` files | 2159 | **2175** (`git ls-files .planning \| wc -l`) | Drift is this phase's own additions — the 198 plans, CONTEXT/PATTERNS, and the four audit artifacts committed by Task 1. |
| Files containing dollar figures | 49 | **51** (`git grep -lIE '\$[0-9]' -- .planning \| wc -l`) | Same cause. LLM spend is recorded down to `$0.015`. |

Beyond the counts, the published history contains vendor and model names, internal quality assessments, and — per the milestone's own findings — assessments that in places **contradict the repository's own documentation**. None of this is a credential, and per D-30 none of it gates the push. It is recorded here so that the published record states plainly what was published, rather than leaving a future reader to discover it.

The remaining gate is not technical: it is the maintainer's explicit, one-way authorization, taken at the Task 3 checkpoint.

---

## Scans run

| # | Tool | Version | Command line (verbatim) | Exit status | Findings |
|---|------|---------|-------------------------|-------------|----------|
| 1 | gitleaks | `8.30.1` | `gitleaks detect --source . --log-opts="--all --full-history" --report-format json --report-path .planning/audits/198-gitleaks-history.json --redact --exit-code 0` | `0` | 3 |
| 2 | gitleaks | `8.30.1` | `gitleaks detect --no-git --source . --report-format json --report-path .planning/audits/198-gitleaks-worktree.json --redact --exit-code 0` | `0` | 3 |
| 3 | trufflehog | `trufflehog 3.97.1` | `trufflehog git file://. --json --only-verified > .planning/audits/198-trufflehog-verified.json` | `0` | 0 verified |
| 4 | git | (git plumbing) | `git log --all --full-history --diff-filter=A --name-only --pretty=format:'%H %ad' --date=short -- '*.env' '*.env.*' '*.pem' '*id_rsa*' '*credentials*' '*.netrc'` | `0` | 2 paths |

**Availability (flagged_assumptions resolution).** Neither scanner was present at plan start — both `command -v gitleaks` and `command -v trufflehog` exited non-zero. Both were installed from `homebrew/core` after verifying the formulae resolve to their genuine upstreams (`gitleaks` → `github.com/gitleaks/gitleaks`, `trufflehog` → `github.com/trufflesecurity/trufflehog`). **No scanner is recorded UNAVAILABLE; all four sweeps ran.**

**Sweep provenance details:**

- Sweep 1 scanned **2381 commits / 38.42 MB**. `--exit-code 0` is deliberate: a finding must not abort the sweep before the remaining scanners run. The verdict is decided in the finding register above, never by an exit code. `--redact` ensures the committed JSON report does not itself publish the secret it found.
- Sweep 2 scanned **24.50 MB** of the working tree with `--no-git`, which also covers untracked files that no commit would reveal.
- Sweep 3 scanned **17572 chunks / 39244982 bytes**, reporting `verified_secrets: 0` and `unverified_secrets: 0`. `198-trufflehog-verified.json` is therefore **0 bytes — an empty result, not a failed run**; the run statistics above are the corroborating evidence. Verified mode calls the issuing provider to test liveness, which is the one capability gitleaks lacks and the reason D-28 locks running both engines. (Threat T-198-02-04 accepts that this transmits candidates to the provider that already holds them.)
- Sweep 1 and sweep 2 report the same three findings because all three still exist at HEAD; they are not six distinct exposures. Sweep 2's paths differ from sweep 1's for finding F-001 only because the file was relocated into `.planning/milestones/v1.22-phases/` by a later milestone archive.

---

## Ever-added credential-shaped files

Raw output of sweep 4 (`git log --all --full-history --diff-filter=A` over `*.env`, `*.env.*`, `*.pem`, `*id_rsa*`, `*credentials*`, `*.netrc`):

```
231687f92e776795efef35166a9da16b1628e1b8 2026-06-20
.planning/todos/pending/2026-06-20-demo-login-copy-credentials.md

5431462016e9ee90f750bc47752dc001086c730c 2026-06-02
.env.example
```

Both matches are filename-glob hits, not credential hits — dispositioned as F-004 and F-005 above.

**No `.env`, `.pem`, `id_rsa`, or `.netrc` file was ever added in the repository's history** — which is what `.gitignore:26-28,79` was there to prevent, and this sweep confirms it held across all 2381 commits rather than only at HEAD. This is the finding a HEAD-only grep structurally cannot produce, and the reason D-28 requires full history.

---

## D-30 authorization

_Pending — Task 3 (`checkpoint:decision`, `gate="blocking-human"`). Not yet taken._

The one-way publication decision has **not** been made, and nothing in this phase may push until it is. See `.planning/phases/198-green-bringup/198-02-SUMMARY.md` for the halt record.

---

## Push protection enabled

_Pending — Task 3. GitHub secret scanning and push protection have **not** been enabled, and no repository setting was changed by this plan._

**Standing D-29 invariant for every later plan in this phase:** push protection blocking a push is a **Class A/B signal**. The "allow secret" bypass is **forbidden** under all circumstances. A blocked push returns to this artifact's finding register for disposition — it is never clicked through.
