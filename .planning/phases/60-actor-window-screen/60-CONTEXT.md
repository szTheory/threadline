# Phase 60: Actor Window Screen

## Goal
Turn `Threadline.actor_history/2` into a one-click answer for "what did this actor do recently" with deep-links into the incident drill-down.

## Dependencies
- Phase 59 (Incident Drill-down Screen)

## Requirements
- **UI-02**: Visiting `/audit/actors/:kind/:id` renders a paged transaction list for that actor with a time-window picker.
- Each transaction row links to the corresponding `/audit/transactions/:id` drill-down.
- Visiting an actor with no recorded activity in the chosen window renders an explicit empty state.

## Strategic Guidelines
- **Zero-Crash Scale:** System actors can generate massive transaction volumes. The surface must never crash due to memory exhaustion.
- **Principle of Least Surprise:** Use established observability UX patterns (Datadog, Stripe) for infinite scroll and time bounding.
