# Phase 59: Incident Drill-down Screen

## Goal
Turn `Threadline.incident_bundle/2` into a one-click answer for "what happened in this transaction" with a URL-addressable LiveView.

## Dependencies
- Phase 58

## Requirements
- **UI-01**: Incident drill-down LiveView at `/audit/transactions/:id` renders `Threadline.incident_bundle/2` — actor and request-context header, ordered changes with `Threadline.change_diff/2` per row, URL-addressable for log/ticket deep-links, and an explicit not-found state.

## Success Criteria
1. Visiting `/audit/transactions/:id` renders the incident bundle with an actor/request-context header and ordered changes laid out per row using `Threadline.change_diff/2`.
2. The screen URL is a stable deep-link suitable for log/ticket references — pasting `/audit/transactions/<known_id>` from a fresh session lands directly on the bundle without prior navigation state.
3. Visiting an unknown or malformed `:id` renders an explicit not-found state (no crash, no mis-attributed empty bundle) so operators can distinguish "no such transaction" from "transaction with zero changes."

## UI Hint
yes