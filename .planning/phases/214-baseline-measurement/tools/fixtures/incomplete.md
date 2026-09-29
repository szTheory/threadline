# Negative fixture for check-baseline-complete.py

This doc must FAIL the completeness check. It has no heading for the `:live_dialyzer`
element, and its pull_request row for verify-test has only nine samples.

## 1. Per-job duration (ci.yml)

| Job id | Job name | Event | n | p50 | p95 | min–max | Regenerate |
|---|---|---|---|---|---|---|---|
| verify-test | Run test suite (current) | pull_request | n=9 | p50 546 s (run 34755536474) | p95 610 s (run 36258071425) | min–max 464–623 s | `python3 summarize-ci.py jobs` |
| verify-test | Run test suite (current) | push | n=18 | p50 574 s (run 34756589365) | p95 646 s (run 36257162368) | min–max 417–646 s | `python3 summarize-ci.py jobs` |

## 2. Critical path

Browser E2E finishes last in most runs.

## 3. Runner-minutes per unit of work

Per PR, per push-to-main and per release cycle figures would go here.

## 4. Flake Detection cost

## 5. Browser-full cost

## 6. Inert-path share of merged PRs

## 7. `mix test --slowest 25`
