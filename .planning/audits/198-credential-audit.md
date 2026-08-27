# Phase 198 Credential Audit (D-28 / D-29)

**Scanned:** 2026-08-27
**Scope:** full git history (`--all --full-history`) plus the untracked working tree, ahead of the first `git push` of this phase's 587 unpushed commits.
**Gate:** D-34 step 4. This audit gates step 5 (push) on **any** ref — the staging-branch push in Plan 03 is the disclosure event just as much as the `main` push in Plan 07.

This artifact never quotes a live secret string. Findings are referenced by rule id, file path, and commit SHA only, because this file is itself about to be published.

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

- Sweep 1 scanned **2381 commits / 38.42 MB**. `--exit-code 0` is deliberate: a finding must not abort the sweep before the remaining scanners run. The verdict is decided in the finding register below, never by an exit code. `--redact` ensures the committed JSON report does not itself publish the secret it found.
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

Both matches are filename-glob hits, not credential hits. `.env.example` is a committed template of Docker host/port defaults (`COMPOSE_PROJECT_NAME`, `THREADLINE_DB_PORT`, …) with no secret values. The todo file matched `*credentials*` in its title; it is a UX note about the example app's deliberately-visible demo login. Both are dispositioned as rows in the finding register.

**No `.env`, `.pem`, `id_rsa`, or `.netrc` file was ever added in the repository's history** — which is what `.gitignore:26-28,79` was there to prevent, and this sweep confirms it held across all 2381 commits rather than only at HEAD.
