# Threadline ↔ phx.gen.auth integration

<!-- PHX-GEN-AUTH-03-INTEGRATION-GUIDE -->

This guide documents Threadline's current `phx-gen-auth-reference` lane: a maintained
composition path for Phoenix hosts using `mix phx.gen.auth` (or equivalent generated
session auth). It is a reference claim, not a blanket support promise for arbitrary
generator versions, role fields, or non-Phoenix auth. This lane is narrower than
generic `phoenix-surface` integration and is not Sigra-compatible.

## Prerequisites

- Your host already ran `mix phx.gen.auth` (or equivalent generated session auth).
- Threadline does not add an auth Hex dependency; capture uses `Threadline.Plug` callbacks only.
- The host owns user schema, session tables, and pipeline plugs.
