---
created: 2026-06-20T12:51:12Z
title: Demo login copy credentials
area: operator-surface
origin: User feedback during Phase 180 manual accessibility checkpoint on the local `/users/log_in` demo flow.
files:
  - examples/threadline_phoenix/lib/threadline_phoenix_web/controllers/session_html.ex
  - examples/threadline_phoenix/test/threadline_phoenix_web/sigra_auth_flow_test.exs
  - examples/threadline_phoenix/e2e/tests/operator-accessibility.spec.ts
---

## Problem

The Phoenix example login page at `/users/log_in` shows demo credentials, but a user still has to
manually select and copy `admin@example.com` and `password123456` before signing in. During manual
Phase 180 testing this adds friction right at the start of the demo/evidence flow.

The current page is at least predictable because the credentials are visible as text. Any enhancement
should preserve that principle of least surprise: clicking a credential should not silently submit the
form, hide the value, or imply the password is a production secret.

## Solution

Add a small demo-only copy affordance to each visible credential on the login page:

- Keep the email and password visible as selectable text.
- Make each credential explicitly clickable/copyable with accessible naming.
- Copy only the clicked value, not both values at once.
- Provide clear feedback after copy, such as an inline "Copied email" / "Copied password" status
  message announced politely for assistive tech.
- Keep behavior CSP-clean and local to the example app; no inline handlers and no new runtime
  dependencies.
- Preserve the existing dev/test demo-credentials framing so this does not read as production auth
  guidance.

## Acceptance Criteria

- On `/users/log_in`, clicking or keyboard-activating the visible demo email copies
  `admin@example.com` to the clipboard and shows clear feedback.
- Clicking or keyboard-activating the visible demo password copies `password123456` to the clipboard
  and shows clear feedback.
- The feedback is visible and exposed through an appropriate live/status region without stealing focus.
- The underlying values remain visible/selectable for users who prefer manual copy.
- The implementation is CSP-clean, has no inline JavaScript handlers, and adds no dependencies.
- Existing login/auth tests still pass, with at least one focused test covering the copy affordance or
  its rendered contract.
