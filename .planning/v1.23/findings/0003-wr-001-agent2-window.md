---
id: 0003
slug: wr-001-agent2-window
classification: c
walkthrough_step: WALK-03-02
captured: 2026-05-27T00:00:00Z
status: fixed
fixed_in: 8dfcb87b8405ca232c0d114bf02844aa71b54d30
deferred_to:
---

## Expected

WALK-03-02: actor history for **`agent2@acme.example.com`** (`33123cc4-da21-5674-b030-e168cee90521`) is non-empty in the documented time window — seeded leaving-agent activity visible on `/audit/actors/user/:id`.

## Actual

WALKTHROUGH instructed a **24-hour window ending at `demo_epoch`** (`from` = `2026-05-26T12:00:00Z`, `to` = `2026-05-27T12:00:00Z`). Seeded leaving-agent transactions are stamped at **`demo_last_tuesday` + 1..12 minutes** (`2026-05-20T14:31:00Z` … `2026-05-20T14:42:00Z`) in `seed_leaving_agent_window/1` (`anchors.ex` lines 95–121).

Following the documented filter exactly yields **empty** actor history — contradicting the expected outcome.

## Evidence

108-REVIEW WR-001 block (2026-05-27).

`anchors.ex` `seed_leaving_agent_window/1`:

```elixir
ts =
  Manifest.last_tuesday()
  |> DateTime.add(n, :minute)
```

12 transactions at `2026-05-20T14:31:00Z` … `2026-05-20T14:42:00Z` — outside the documented 24h window ending `2026-05-27T12:00:00Z`.

## Classification note

Pre-registered 108-REVIEW WR-001; reproduced 108-REVIEW; Phase 109 blocked before WALK-03-02.
