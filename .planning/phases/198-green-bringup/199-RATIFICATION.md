# 199-RATIFICATION — the nine irreducible Phase 198 checkpoints

**Status: AWAITING MAINTAINER.** Drafted by the phase-199 executor; not decided.

## Why this document exists

Phase 198 closed with 36 coverage entries flagged `human_judgment: true`, which
`/gsd-verify-work` re-presents as manual checkpoints on **every** run. Phase 199 discharged
27 of them against evidence that now exists and is checked mechanically — recorded
maintainer decisions, a measured CI run committed as an attestation, and four mechanisms
built or found.

These nine are the remainder, and they are different in kind. Each is a **judgment**:
whether a record is candid, whether a scoping call was right, whether a risk tolerance is
acceptable, whether a forward estimate is sound. No test can adjudicate any of them, and
building one that appeared to would be the laundering this phase's artifacts exist to
prevent.

They are grouped here so they can be settled **once** rather than re-prompted forever. What
is being asked is not "is this true" — the underlying facts are all recorded and verifiable
— but "do you accept the judgment as recorded."

## How to answer

One reply covering all nine is enough (e.g. `ratify all` / `ratify all except 198-05 D7`).
Your words will be recorded verbatim, dated, and attributed. Only then will the entries be
flipped to `human_judgment: false`, with a `manual_procedural` verification ref pointing
here — an honest attestation that a decision **was made**, never that a test proved it.

Anything you do not ratify stays a human checkpoint, which is the correct outcome for a
judgment you are not comfortable delegating.

---

## Group 1 — Candour calls (2)

Both ask the same question: is the record genuinely unsoftened, or accurate-but-hedged?
Both entries say plainly that no automated check can tell the difference.

Worth knowing before you answer: the adjacent *mechanics* were independently verified. The
round-6 verifier byte-diffed the sealed prediction at `23c16267` before and after the push
and confirmed no retro-editing, and `.planning/audits/ci-attestation-33344382035.json` now
pins the measured result these records describe. So the facts are attested; only the tone is
in question.

**198-29 D3** — The round-6 record states it MISSED its target (red needs 3→1) and
FALSIFIED its own pre-push prediction (2).
*Ratify that this is recorded without softening.*

**198-37 D4** — The record scores one composition-level partial miss (a third un-predicted
Playwright failure row) rather than reporting a clean hit.
*Ratify that it distinguishes conclusion-level from composition-level accuracy without
rhetorically minimising the miss.*

> **Executor's note, offered because you should weigh it:** I am the wrong party to certify
> candour in records produced by this same pipeline. Reading them, both state their misses
> in the first sentence rather than burying them, which is the behaviour the entries ask
> about. Treat that as an observation, not an endorsement.

---

## Group 2 — Scoping and framing calls (3)

**198-03 D7** — Classifying the min-lane failure as a genuine code/test failure rather than
runner-image or Playwright drift. The differential evidence (min and current failing
identically) is mechanical and does rule out toolchain drift. The judgment is what the 83
shared failures mean for the **Elixir 1.15 floor promise**.
*Now materially easier to ratify: `Run test suite (min)` concluded `success` on run
`33351326371`. The floor promise holds on a measured run.*

**198-04 D8** — The corrected root cause of the red baseline: 79 test-side defects assuming
an unprefixed `search_path`, not a stale database. Mechanism proven, arithmetic reconciles
exactly (79+1+1+1 = 82 local, 83 CI). The judgment was the remediation shape.
*The choice was made and has since been validated: per-call-site prefixing shipped, and
`storage_schema_call_site_contract_test.exs` now sweeps the whole tree so the class cannot
return. Suite is 1471/0.*

**198-12 D5** — That `mix ci.all`'s remaining `verify.example` failure is a documented,
out-of-scope pre-existing gap rather than something silently ignored.
*Also easier now: `verify.example` runs inside `Run test suite (current)`, which concluded
`success` on run `33351326371`.*

---

## Group 3 — Risk tolerance (1)

**198-05 D7** — Every job in `ci.yml`, `release.yml`, and `browser-full.yml` carries a
`timeout-minutes` bound. Presence is already automated and passing; the **values** are the
judgment.

The entry flags one as weaker than the rest, and it is right to: **18 minutes for the
browser lane is a D-16 budget, not a multiple of an observed green p95**, because that lane
had no observed green run — its only recorded durations were 1h33m38s (broken) and ~2m
(fast-failing). No bound has ever been observed firing on a hang.

*New evidence that did not exist when this was written:* the browser lane concluded
**`success`** on run `33351326371`. There is now a green duration to calibrate against, so
the 18-minute bound can be reviewed on data rather than ratified on judgment alone.
**Recommend deferring this one** until the p95 is worth computing, rather than ratifying a
number that can now be derived.

---

## Group 4 — Forward-looking estimates (2)

**198-01 D4** — The sizing implication for Phase 201 Tier 2: copy work is cheap to gate but
unprotected against layout consequences. The measurement is proven; the estimate drawn from
it is a planning judgment.
*The entry says it should be ratified "when Phase 201 is planned." **Recommend deferring**
— ratifying a Phase 201 estimate now, before 201 is planned, would be ratifying it at the
moment you know least.*

**198-31 D4** — A local unbounded Playwright measurement recorded beside round 4's
CI-capped figures, with the non-nested-population caveat stated. The entry describes itself
as a measurement/documentation deliverable, "not machine-verifiable as pass/fail."
*Ratify that the measurement and its caveat are recorded adequately.*

---

## Group 5 — An open root cause (1)

**198-27 D3** — A new discovery (`operator-accessibility.spec.ts:655:3`, mobile-chromium)
logged with a cause-in-progress note and a dated `deferred-items.md` entry rather than
silently absorbed.

This one is **not** purely a judgment, and should be treated differently: the root cause is
genuinely unestablished. What can be attested mechanically is that the dated deferral row
exists; whether the deferral is *adequate* cannot.

*Recommend ratifying the deferral as adequate only if you are content for the root cause to
stay open. Otherwise leave it as a checkpoint — it is the one item here that marks real
unfinished work rather than a completed judgment.*

---

## Summary

| Item | Kind | Executor recommendation |
|---|---|---|
| 198-29 D3 | candour | ratify |
| 198-37 D4 | candour | ratify |
| 198-03 D7 | scoping | ratify — min lane now green on a measured run |
| 198-04 D8 | scoping | ratify — remedy shipped and swept |
| 198-12 D5 | scoping | ratify — verify.example green on a measured run |
| 198-05 D7 | risk tolerance | **defer** — a green duration now exists; derive the bound |
| 198-01 D4 | forward estimate | **defer** — ratify when Phase 201 is planned |
| 198-31 D4 | measurement record | ratify |
| 198-27 D3 | open root cause | **your call** — ratifying accepts the cause staying open |

Ratifying the six recommended leaves **3** recurring human checkpoints, each deferred for a
stated reason rather than because nobody looked.

---

## Maintainer's decision

> _(verbatim answer to be recorded here, with date and attribution)_

**Decided by:**
**Date:**
