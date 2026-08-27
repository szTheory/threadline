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

**One judgment call is flagged for the maintainer** rather than settled silently — findings F-002 and F-003 (the example app's dev/test `secret_key_base` literals). See the register reason column and the note beneath it. **RESOLVED at the Task 3 gate on 2026-08-27: Class C stands, no rotation.** See the rider under `## D-30 authorization`.

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

**This was surfaced at the Task 3 decision gate.** If the maintainer had preferred the blanket policy, F-002/F-003 would have been re-dispositioned as Class A, rotated before any push, and this register updated with real rotation timestamps — which D-29 permits without changing the PROCEED verdict, since Class A rotation proceeds to push.

**Outcome (2026-08-27T20:15:04Z): the blanket policy was NOT applied. Class C stands for both; neither value was rotated.** The maintainer delegated this call at the gate. Full rationale is recorded under `## D-30 authorization` → *Rider — F-002 / F-003*. Class counts are unchanged: **A = 0 (rotated: 0) · B = 0 · C = 5.**

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

**Decision: `proceed`. Publication of `.planning/` history is AUTHORIZED.**

**Taken:** 2026-08-27T20:15:04Z
**Gate:** Task 3, `<task type="checkpoint:decision" gate="blocking-human">` — resolved by the maintainer at an explicit, recorded checkpoint. Not auto-approved; `blocking-human` gates are never auto-selected in any mode.

**Maintainer's confirmation, verbatim:**

> auto foolow ur recs proceed

The maintainer was presented with the verdict line, the five-row finding register with class counts (A=0 rotated 0, B=0, C=5), the disclosure surface being published (2175 tracked `.planning/` files, 51 containing dollar figures down to `$0.015`, plus vendor and model names and internal quality assessments that in places contradict the repository's own documentation), and the explicit statement that this action is **one-way**: after the first push this history is public and mirrorable, and D-30's accepted posture forbids a history rewrite as the remedy.

The reply authorizes publication and directs that the recommendations be followed, which includes enabling secret scanning and push protection (recorded below).

### Rider — F-002 / F-003 disposition stands as Class C (no rotation)

The one open judgment call flagged in the register above — the example app's `dev.exs` / `test.exs` `secret_key_base` literals — was delegated by the maintainer along with the rest of the recommendation. **Decision: do NOT rotate. Class C stands.**

Rationale, recorded because this is a disposition a reasonable maintainer could decide differently:

- These values guard nothing. They belong to a bundled example application with **no deployed instance** — it runs on localhost and in CI only.
- Production is env-sourced: `examples/threadline_phoenix/config/runtime.exs:64` reads `System.get_env("SECRET_KEY_BASE")` and raises if absent. The dev/test defaults are checked in by upstream Phoenix's own `mix phx.new` design, and `runtime.exs` says so in its own comment.
- The example app's demo login credentials are printed on its login page **by design**. There is no confidentiality for a session cookie to protect.
- Rotating would stamp a misleading `rotated on 2026-08-27` incident row into a register that is **about to be published**, describing something that was never an exposure. That is precisely the laundering this phase's artifacts exist to prevent. Class C is the honest classification.

This rider does **not** change the verdict. `## VERDICT: PROCEED` stands, with class counts unchanged: **A = 0 (rotated: 0) · B = 0 · C = 5.**

---

## Push protection enabled

**Enabled and verified:** 2026-08-27T20:15:23Z
**Repository:** `szTheory/threadline` (public)

Command run (verbatim):

```
gh api --method PATCH repos/:owner/:repo -f 'security_and_analysis[secret_scanning][status]=enabled' -f 'security_and_analysis[secret_scanning_push_protection][status]=enabled'
```

Verification command (verbatim) and its returned JSON, pasted verbatim:

```
$ gh api repos/:owner/:repo --jq .security_and_analysis
{"dependabot_security_updates":{"status":"disabled"},"secret_scanning":{"status":"enabled"},"secret_scanning_non_provider_patterns":{"status":"disabled"},"secret_scanning_push_protection":{"status":"enabled"},"secret_scanning_validity_checks":{"status":"disabled"}}
```

**`secret_scanning`: `enabled`. `secret_scanning_push_protection`: `enabled`.** Both required settings are live.

**Recorded honestly: both settings were ALREADY `enabled` before the PATCH ran.** A read of `gh api repos/:owner/:repo --jq .security_and_analysis` taken at 2026-08-27T20:15:04Z, before any modification, returned the identical JSON above. GitHub enables secret scanning and push protection by default on public repositories, and this repository has been public throughout. The PATCH was executed anyway — per the plan's action — and succeeded as a no-op confirmation rather than a state change.

This corrects, in the honest direction, the halt record's statement in `198-02-SUMMARY.md` that the settings were "NOT enabled". That statement was accurate about **what the plan had done** (it had changed no setting) but was never a verified read of the remote. The remote state was already correct. No credit is claimed here for enabling something that was already on.

Two related settings remain `disabled` and were deliberately **not** changed, because the plan's constraint is to touch only the two settings it names: `secret_scanning_non_provider_patterns` and `secret_scanning_validity_checks`. `dependabot_security_updates` is likewise untouched. Enabling any of these is out of scope for this plan.

**Standing D-29 invariant for every later plan in this phase:** push protection blocking a push is a **Class A/B signal**. The "allow secret" bypass is **forbidden** under all circumstances — it must not be clicked, invoked, or passed as a flag. A blocked push does not get retried around; it returns to this artifact's `## Finding register` and is dispositioned under the D-29 Class A/B/C rule before any further push attempt. A Class A finding is rotated before the push retries; a Class B finding aborts the phase.

**This plan pushed nothing.** Enabling push protection and authorizing publication are the gate; the first actual push of these commits is Plan 03's staging-branch push. `git log origin/main..main` remains non-empty.
