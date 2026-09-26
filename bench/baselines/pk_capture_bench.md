# CAP-06 capture overhead benchmark

- **Commit:** 128f5cb5b6cfc7f0e4ce9d743b7867774a19b5e8
- **PostgreSQL server_version:** 14.17 (Homebrew)
- **Elixir:** 1.17.3
- **OTP:** 27
- **Machine:** Darwin arm64 (Apple M5 Pro)
- **Rows:** 50000
- **Reps:** 5

| Operation | baseline (us/row) | current (us/row) | current/baseline | catalog (us/row) | catalog/baseline | composite (us/row) | composite/current |
| --- | --- | --- | --- | --- | --- | --- | --- |
| insert | 21.750 | 23.299 | 1.071 | 42.402 | 1.949 | 22.346 | 0.959 |
| update | 35.275 | 33.994 | 0.964 | 54.187 | 1.536 | 36.333 | 1.069 |
| delete | 20.601 | 21.134 | 1.026 | 39.840 | 1.934 | 22.766 | 1.077 |

PASS: current/baseline <= 1.10x and catalog/baseline >= 1.25x on every operation (D-07 pass bar).
