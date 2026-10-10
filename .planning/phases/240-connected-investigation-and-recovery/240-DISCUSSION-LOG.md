# Phase 240: Connected investigation and recovery - Discussion Log

> **Audit trail only.** Planning and implementation agents should use `240-CONTEXT.md`; this file preserves alternatives considered during the auto discussion.

**Date:** 2026-10-10
**Phase:** 240-connected-investigation-and-recovery
**Areas discussed:** row-history return and failure behavior; actor/correlation pivots and saved searches; copy lifecycle and truthful feedback; purposeful reduced-motion-aware behavior

All areas were auto-selected under `$gsd-discuss-phase 240 --auto`. Recommendations came from four targeted parallel advisor reviews, with current source and prior phase decisions checked. There was no remaining high-impact or no-winner decision to escalate.

---

## Row-history return and failure behavior

| Option | Description | Selected |
| --- | --- | --- |
| Depend on browser Back alone | Keeps browser history where available but fails for fresh entry, reload, and shared links. | |
| Keep the drawer/parent LiveView patch only | Preserves its mounted state for one origin, but does not cover direct entry. | |
| Use an explicit bounded, validated origin on existing URLs, with a safe Timeline default | Preserves supported committed filters and transaction identity without trusting arbitrary redirects or changing authorization scope. | ✓ |

**Auto-selected recommendation:** Use an explicit safe return action; browser Back remains an additional shortcut. Keep scope server-owned and do not restore cursor pages. Do not mount row-history reads when the parent transaction is unavailable; distinguish retryable failures from empty, denied, and not-found.

## Actor/correlation pivots and saved searches

| Option | Description | Selected |
| --- | --- | --- |
| Share actor-owned saved-search records | Requires shared ownership/authorization semantics not in scope. | |
| Share the canonical URL for the committed query | Preserves current actor-owned named searches and lets each recipient re-evaluate query/scope. | ✓ |
| Rely only on browser history | Does not provide a reusable named search or shareable link. | |

**Auto-selected recommendation:** Continue actor/correlation pivots using the existing allowlisted Timeline filters. Save and resume only the committed query as the current operator's named search; share filters through a canonical URL, not a saved-search record or a promise of the same result set/access.

## Copy lifecycle and truthful feedback

| Option | Description | Selected |
| --- | --- | --- |
| Bind a handler per copy element with LiveView hooks | Explicit per-element lifecycle, but adds binding state and duplicate-handler risk. | |
| Keep one document-level delegated listener bound once | Fits patched DOM and fresh entry; rely on confirmed browser result and preserve selection fallback. | ✓ |
| Continue silently on clipboard failure | Leaves operators unsure whether exact values were copied. | |

**Auto-selected recommendation:** Start the Clipboard API write from the user's click; announce success only after resolution. If the API is absent, try the existing legacy fallback and confirm only on success. If a write rejects or fallback fails, show accessible actionable failure feedback and keep the authorized value selectable. Preserve redaction and no duplicate event handling.

## Purposeful, reduced-motion-aware behavior

| Option | Description | Selected |
| --- | --- | --- |
| Use short pointer/touch drawer motion if existing lifecycle can reliably distinguish it | Gives an occasional spatial cue without delaying keyboard actions. | ✓ |
| Animate all drawer activations and evidence changes | Adds delay and may blur old and new evidence. | |
| Make all transitions immediate | Predictable fallback if modality-aware behavior would need fragile shared state. | |

**Auto-selected recommendation:** Keep copy, keyboard, Escape, filter, pivot, saved-search, pagination, and as-of actions immediate. Limit any motion to short interruptible tokenized spatial drawer movement only where existing lifecycle makes the input modality safe; otherwise make it immediate. Honor reduced motion and do not animate row/value changes.

## the agent's Discretion

- Four targeted research clusters returned coherent recommendations and no major architect-level split.
- Implementation may choose exact safe URL encoding, user-facing copy, and tests while preserving the approved constraints.

## Deferred Ideas

- No new capability was raised. New backend history APIs, shared saved-search ownership, cursor restoration, new routes/APIs/dependencies, and broad motion or framework work remain outside this phase.

