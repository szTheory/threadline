---
phase: 87-canonical-mount-recipe-and-example-app-proof
verified: 2026-05-25T15:25:00Z
status: verified
score: 2/2 evidence bands green
authoritative_surface_drift: none
---

# Phase 87: Canonical Mount Recipe & Example-App Proof — Verification Report

**Phase Goal:** Prove on the current tree that adopters get one canonical shared `/audit` mount recipe and one runnable example-host proof path for the same host-owned auth, scope, and export contract.

**Verified:** 2026-05-25T15:25:00Z  
**Status:** verified  
**Re-verification:** Yes

---

## Claim Boundary

Phase 87 closes the adopter-facing proof for one shared `/audit` tree:

- the public contract surfaces teach one canonical `/audit` mount
- the mount keeps auth, scope semantics, and export posture host-owned
- support operators stay on the same tree through `authorize_fn` and `scope_query_fn`
- export remains separately privileged through `export_authorize_fn`
- the runnable Phoenix example proves the same story through `mix verify.example`

This verification inherits the Phase 91 current-tree truth boundary. The claimed
support lane now includes support-scoped row history / as-of on the shipped
`/audit` route because that proof was already completed and promoted before this
backfill ran.

---

## 1. Public Contract Evidence

**Result:** PASS

The adopter-facing guides and the example README agree on the same shared-tree
recipe:

- `guides/getting-started-saas.md` teaches one copy-pasteable `/audit` mount
- `guides/operator-surface.md` keeps the mount, auth, and export contract
  focused on host-owned callbacks
- `guides/upgrade-path.md` names the `sigra-reference` example proof path and
  points adopters to `mix verify.example`
- `examples/threadline_phoenix/README.md` mirrors the same router shape and
  support/export posture

The contract language is truthful on the current tree and stays inside the
repo-proven lane. No additional router family or Threadline-owned policy model
is introduced here.

### Evidence

```bash
mix verify.doc_contract
```

Result: PASS

Supporting spot-checks:

```bash
rg -n 'scope "/audit"|authorize_fn|scope_query_fn|export_authorize_fn' \
  guides/getting-started-saas.md \
  guides/operator-surface.md \
  guides/upgrade-path.md \
  examples/threadline_phoenix/README.md
```

Result: PASS

---

## 2. Runnable Example-Host Evidence

**Result:** PASS

The nested Phoenix example remains the authoritative runnable proof for
`ADOPT-02`:

- the router mounts one shared `/audit` scope
- `my_authorize_fn/1` returns admin allow or support read-only scope on the
  same tree
- `my_export_authorize_fn/1` keeps export capability admin-only
- `scope_operator_query/3` narrows support-visible data in the example host
- the example test suite passes through the named repo entrypoint, not through
  an ad-hoc root-only shortcut

This keeps the example honest as a host-owned composition proof rather than a
broader compatibility claim.

### Evidence

```bash
mix verify.example
```

Result: PASS

Supporting spot-checks:

```bash
rg -n 'scope "/audit"|threadline_operator_surface\("/"|authorize_fn:|export_authorize_fn:|scope_query_fn:' \
  examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex
```

Result: PASS

---

## 3. Named Rerun Surface Evidence

**Result:** PASS

The same named entrypoints remain discoverable for maintainers and adopters:

- `mix verify.doc_contract`
- `mix verify.example`
- CI references for doc and example verification in `.github/workflows/ci.yml`

This preserves a rerunnable proof chain instead of relying on artifact-only
closure language.

### Evidence

```bash
rg -n 'verify\.example|verify\.doc_contract|ci\.all' mix.exs
rg -n 'run: mix verify\.example|run: mix verify\.doc_contract|verify-test|verify-docs' .github/workflows/ci.yml
```

Result: PASS

---

## 4. Requirement Verdicts

### ADOPT-01

**Verdict:** PASS

Threadline now ships one canonical `/audit` mount recipe showing admin and
support personas on the same host-owned route tree. The truth is locked across
the getting-started guide, operator-surface guide, upgrade-path guide, and the
example README.

### ADOPT-02

**Verdict:** PASS

The example Phoenix app proves the canonical support lane with host-owned
`scope_query_fn` narrowing and admin-only export posture through the named
example-host entrypoint `mix verify.example`.

---

## 5. Caveats

- This verification depends on the current-tree wording already promoted in
  Phase 91 for support-scoped row history / as-of.
- The example-host proof remains intentionally narrow: it proves the shipped
  Phoenix + Sigra reference lane, not arbitrary host stacks.

---

## 6. not closed here

The following concerns are not closed here and remain owned by later phases:

- broader denial / fallback UX closure across support-only unavailable views
- remaining milestone authority reconciliation beyond the requirement and plan
  status updates needed for this backfill
- any future widening of the support lane beyond what the current tree proves

Phase 87 is therefore verified for the canonical `/audit` mount and example-app
proof band, with later milestone work still responsible for unrelated surfaces.
