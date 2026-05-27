---
id: 0001
slug: landing-500-badmap
classification: a
walkthrough_step: WALK-01-04
captured: 2026-05-27T19:15:10Z
status: open
fixed_in:
deferred_to:
---

## Expected

WALK-01-04: `mix phx.server` listens on port 4000; help-desk landing at `http://localhost:4000` shows ThreadlinePhoenix heading with Register and Log in links; no 500 on `/`. `curl -sS -o /dev/null -w '%{http_code}' http://localhost:4000/` returns `200`.

## Actual

Server starts without crash, but `GET /` returns HTTP 500 with `BadMapError` — `expected a map, got: nil` in `PageHTML.home/1` when accessing `@current_scope` for logged-out visitors.

## Evidence

```
curl -sS -o /dev/null -w '%{http_code}' http://localhost:4000/
500

Server log:
** (BadMapError) expected a map, got: nil
(threadline_phoenix 0.1.0) lib/threadline_phoenix_web/controllers/page_html.ex:10
```

Clone: `/var/folders/f3/f0clj9rd2zb85n2c849wcsrc0000gn/T//threadline-walk-109-368c315`  
SHA: `368c3159596dfa067f01f93ad25442553f3516db`  
DB: `DB_HOST=localhost DB_PORT=5433`

## Classification note

Hard §1 gate failure — landing page unusable for onboarding and all subsequent walk sections.
