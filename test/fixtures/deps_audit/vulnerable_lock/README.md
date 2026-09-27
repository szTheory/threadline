# Deliberately vulnerable lock fixture

This directory holds a standalone `mix.exs` + `mix.lock` pair pinned to `plug 1.19.1`,
which carries stable, long-published HIGH advisories (for example
`EEF-CVE-2026-54892`). It is consumed only by `bin/verify-deps-audit --self-test`,
which copies both files into a throwaway temp project and proves the gate goes red
on a known-vulnerable lock, with the actual advisory text (`Advisories:` +
`plug 1.19.1`) present in the output — not merely a non-zero exit.

This lock must never be "fixed" or bumped. A green `hex.audit` here would mean the
self-test's positive-vulnerability case can no longer prove anything, silently
defeating the gate it exists to validate.
