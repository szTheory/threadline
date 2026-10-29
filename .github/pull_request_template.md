<!-- Do not disclose vulnerabilities, secrets, personal data, or production audit data in a public pull request. Report vulnerabilities through the private route in SECURITY.md. -->

## Why

What problem does this change solve?

## What changed

Describe the smallest useful summary of the implementation.

## Verification

How did you verify the behavior?

<!-- Add or update tests when behavior changes. Update public documentation when a supported API, configuration key, command, or workflow changes. -->

## Release impact

The squash subject's type decides whether merging cuts a release. The squash subject is the PR title, or the commit subject when the PR has a single commit, so set both. Check one:

- [ ] Ships no code to adopters (CI, tests, tooling) or changes documentation only: the title uses `ci:`, `test:`, `chore:` or `docs:`, never `fix(ci):`.
- [ ] Changes the library code or dependency requirements, or another shipped non-documentation file (`priv/fonts`, the brandbook logos, `.formatter.exs`): the title uses `feat:`, `fix:`, `perf:` or `deps:`, and this PR adds prose under `## Unreleased — highlights` in `CHANGELOG.md`.

## Related issue (optional)

Link an issue when one exists; small fixes do not need a prior issue.
