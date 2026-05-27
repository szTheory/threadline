---
id: 0002
slug: wr-002-cli-syntax
classification: c
walkthrough_step: WALK-03-03
captured: 2026-05-27T00:00:00Z
status: fixed
fixed_in: 8dfcb87b8405ca232c0d114bf02844aa71b54d30
deferred_to:
---

## Expected

WALK-03-03 optional CLI parity uses the §5 (WALK-04-01) flag style:

```bash
mix threadline.evidence.show --subject retention_run \
  --subject-ref-json '{"run_id":"walk-retention-offboarded-co"}'
```

Command exits 0 from `examples/threadline_phoenix/`.

## Actual

WALKTHROUGH documented positional args:

```bash
mix threadline.evidence.show retention_run --subject-ref walk-retention-offboarded-co
```

`Mix.Tasks.Threadline.Evidence.Show` rejects positional args:

```
threadline.evidence.show: unexpected argument(s): retention_run, walk-retention-offboarded-co
```

## Evidence

108-REVIEW WR-002 block (2026-05-27):

```bash
mix threadline.evidence.show retention_run --subject-ref walk-retention-offboarded-co
# Mix error: unexpected argument(s)
```

Correct form already documented in WALK-04-01 step 5 of `WALKTHROUGH.md`.

## Classification note

Pre-registered 108-REVIEW WR-002; reproduced 108-REVIEW; Phase 109 blocked before WALK-03-03.
