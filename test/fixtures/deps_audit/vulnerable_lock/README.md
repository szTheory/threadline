# Deliberately vulnerable lock fixture

This directory holds a standalone `mix.exs` + `mix.lock` pair pinned to `plug 1.19.1`,
which carries stable, long-published HIGH advisories (for example
`EEF-CVE-2026-54892`). It is consumed only by `bin/verify-deps-audit --self-test`,
which copies both files into throwaway temp projects under the repo's gitignored
`tmp/`:

- **Case (a)** runs the gate on the pair as committed and proves it goes red on a
  known-vulnerable lock for a blocking advisory: the output carries the machine line
  `deps-audit-finding tier=blocking ... package=plug id=EEF-CVE-2026-54892`, not
  merely a non-zero exit.
- **Case (e)** reuses the same lock unchanged and rewrites only the copied `mix.exs`
  deps to `[{:plug, "== 1.19.1", only: :test}, {:telemetry, "~> 1.4"}]`. `mix.lock`
  does not record `only:`, so `deps.get --check-locked` still passes and the lock
  stays byte-identical. plug and plug_crypto are now outside the `--only prod`
  closure (telemetry keeps it non-empty), so the gate must exit 0 and report
  `tier=non-blocking` for `package=plug id=EEF-CVE-2026-54892`. This is the real-Hex
  proof of the SUP-03 downgrade and a tripwire for SARIF format drift.

This lock must never be "fixed" or bumped. A green `hex.audit` here would mean the
self-test's positive-vulnerability case can no longer prove anything, silently
defeating the gate it exists to validate.
