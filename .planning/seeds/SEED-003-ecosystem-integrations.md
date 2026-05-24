---
id: SEED-003
status: retired
planted: 2026-05-08
retired_on: 2026-05-24
retired_during: v1.20 closeout preparation
retired_reason: Kept as strategic direction in milestone arc and product narrative, but not maintained as an open implementation seed.
scope: Large
---

# Ecosystem Integrations (High-Value Wins)

**Domain:** Interoperability with sztheory ecosystem libraries
**Status:** Seed / Future Roadmap

Threadline is the central nervous system for operator observability. Its massive value comes from acting as the unified sink for all other sztheory libraries, giving support agents and security teams a single timeline.

## 1. The Unified Security & Access Timeline
*The Win:* Enterprise-grade compliance (SOC2, HIPAA) out-of-the-box.
*Integration point:* Threadline should provide a pre-built telemetry sink/adapter for identity and access events.
- **Sigra:** Logins, password resets, MFA changes (TOTP/passkeys), session revocations, encryption key rotations. (Ref: SEED-001)
- **Lockspire:** OAuth client authorizations, token issuance, scope granting/revocation.
- **Relyra:** SAML 2.0 assertions, IDP initiated sign-on outcomes.
*Value:* Security teams get a single pane of glass for "who did what, and when did they gain access?" without writing custom tracking code.

## 2. The Revenue & Subscription Timeline
*The Win:* Transparent billing operations for support agents.
*Integration point:* Accrue emits billing state changes. Threadline acts as the durable ledger.
- **Accrue:** Invoice generation, payment successes/failures, subscription plan upgrades/downgrades, refunds, dunning escalations.
- **Lattice Stripe / Oarlock:** Payment processor sync events (tracked through Accrue).
*Value:* When a customer asks "why was I charged?", support agents look at the Threadline timeline for the user and see the exact sequence of lifecycle events alongside their web actions.

## 3. The Communication Ledger
*The Win:* "Did the user get the email/alert?" answered definitively in the audit trail.
*Integration point:* Track system-outbound communications and their resolution.
- **Mailglass:** Transactional email dispatch, bounce, and delivery webhook tracking.
- **Chimeway:** Notification routing (in-app, SMS, push), suppression rules triggering, workflow escalations.
*Value:* Eliminates the black box of system communication. Mixed with the security timeline, you can prove the full chain: "User requested reset -> Mailglass delivered email -> User clicked link -> Sigra rotated password."

## 4. Scrypath (Search Indexing)
*The Win:* Blazing fast log discovery at scale.
*Integration point:* Threadline ledgers grow massive. Using Scrypath to provide Ecto-native full-text search indexing over the Threadline JSON/B payload columns makes the operator dashboard infinitely more powerful.
*Value:* Upgrades the Threadline Operator UI from a simple paginated list to a powerful investigative tool capable of searching deeply nested metadata and diffs.

## 5. Data Residency & Deletion Compliance
*The Win:* GDPR/CCPA "Right to be Forgotten" guaranteed across the stack.
*Integration point:* 
- **Rindle:** Media uploads, access logs, and hard deletions. 
- **Rendro:** PDF/document generation outcomes.
*Value:* Threadline tracks when Rindle media is accessed or deleted. Threadline's redaction mechanisms can coordinate with Rindle's media lifecycles to ensure PII in generated documents is provably purged.

## Note

This seed remains a useful future-product direction, but it is not currently an
active milestone candidate with enough scoping detail to stay open in the
closeout audit. The strategic intent belongs in `.planning/MILESTONE-ARC.md`
and future milestone definition work rather than as a dormant implementation
seed.
