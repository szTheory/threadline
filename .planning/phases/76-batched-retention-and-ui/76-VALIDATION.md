# Phase 76 Validation Architecture

## Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test` |
| Full suite command | `MIX_ENV=test mix ci.all` |

## Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| RET-01 | Pruner GenServer sleeps and yields | unit | `mix test test/threadline/retention/pruner_test.exs` | ❌ Wave 0 |
| RET-02 | Runs tracked in `threadline_retention_runs` | unit | `mix test test/threadline/retention_test.exs` | ✅ Wave 0 (partially) |
| RET-03 | Retention History UI displays runs | e2e | `mix test test/threadline/operator_surface/live/retention_history_live_test.exs` | ❌ Wave 0 |

## Sampling Rate
- **Per task commit:** `mix test`
- **Per wave merge:** `MIX_ENV=test mix ci.all`
- **Phase gate:** Full suite green before `/gsd-verify-work`

## Wave 0 Gaps
- [ ] `test/threadline/retention/pruner_test.exs` — covers RET-01
- [ ] `test/threadline/operator_surface/live/retention_history_live_test.exs` — covers RET-03
