# Prior-art corpus — canonical sources

## `oss-deep-research/`

Files in this directory were copied from **`~/projects/scrypath/prompts/`** on 2026-04-22.

For these seven filenames, **SHA-256 matched** across scrypath, sigra, and lattice_stripe (where the file existed):

- `elixir-best-practices-deep-research.md`
- `elixir-opensource-libs-best-practices-deep-research.md`
- `elixir-oss-lib-ci-cd-best-practices-deep-research.md`
- `phoenix-best-practices-deep-research.md`

These matched **scrypath** and **sigra** (lattice_stripe has no `ecto-*` or `phoenix-live-view-*` or `elixir-plug-ecto-phoenix-*` in prompts):

- `ecto-best-practices-deep-research.md`
- `phoenix-live-view-best-practices-deep-research.md`
- `elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md`

**Lattice Stripe–specific** research under `lattice_stripe/prompts/` was intentionally **not** copied (Stripe / payments domain noise for Threadline).

## `from-scrypath/`

Scrypath-only research and brand reference.

## `from-sigra/`

Auth-library research retained for **actor semantics, security framing, and Phoenix integration** patterns relevant to audit libraries—not as product scope for Threadline.
