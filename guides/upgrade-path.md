# Upgrade Path

This guide is the canonical support-matrix and lifecycle reference for Threadline's named adoption lanes. `guides/integration-contracts.md` defines the reusable seams, and `guides/operator-surface.md` covers mount, auth, and screens. This guide answers a different set of questions: which lane you are on, what compatibility is actually supported, and how surface-only changes move between Threadline minors.

Threadline **0.6.0** packages Evidence, `Audit.transaction/3`, and aligned operator surfaces that landed in-repo after **0.5.0**; upgrade steps are semver-scoped in `CHANGELOG.md` and this guide.

## Who this guide is for

Use this guide if you are:

- deciding whether you are running `capture-only`, `phoenix-surface`, or `sigra-reference`
- upgrading Threadline across minors and need to know what the operator-surface contract includes
- checking whether a host path is `supported`, `reference`, or `unclaimed`

If you only need router wiring, auth posture, or screen references, stay in `guides/operator-surface.md`.

## How to tell which lane you are on

You are on the `capture-only` lane when your host application does not depend on Threadline's optional Phoenix surface dependencies and does not mount `threadline_operator_surface/2`. The proof point for this lane is `mix verify.compile_no_optional`.

You are on the `phoenix-surface` lane when your host application adds the optional Phoenix surface dependencies and mounts `threadline_operator_surface/2` in a Phoenix router using the in-tree operator surface. The proof for this lane comes from the root package: `mix.exs`, `mix.lock`, root CI, and the root doc-contract tests.

You are on the `sigra-reference` lane when your Phoenix host already uses Sigra and composes `Threadline.Integrations.Sigra` into `Threadline.Plug` using the current example app and guide path. The proof for this lane comes from `examples/threadline_phoenix/`, its lockfile and README, `guides/integrations/sigra.md`, and `mix verify.example`. This is a narrower claim than generic Sigra compatibility.

For 0.5.0 support-lane wording, read those lane claims together with
`guides/operator-surface.md`: current mounted proof covers the shared `/audit`
timeline, actor, transaction, support-scoped row history / as-of, and
export-auth seams on the current tree.

Mounted `/audit/evidence` is narrower than that broad `/audit` proof. Treat it
as a separately authorized capability under the `phoenix-surface` lane rather
than a surface that appears automatically everywhere `/audit` is mounted.

Threadline uses three support words intentionally:

- `supported` means the lane is documented and backed by current repo proof.
- `reference` means the repo maintains a first-party composition path inside a narrower host story.
- `unclaimed` means the combination may be plausible locally, but this repo does not currently prove it.

That distinction matters more than dependency rows alone:

- `capture-only` is `supported` with no optional Phoenix dependencies installed and is enforced by `mix verify.compile_no_optional`.
- `phoenix-surface` is `supported` only for the exact optional dependency ranges Threadline declares and CI-covers in this release.
- `sigra-reference` is a `reference` lane for Phoenix hosts already using Sigra; it is proven only by the current example app, example lockfile, docs, and focused verification in this repo.
- Anything outside these named lanes is `unclaimed`, even if it may work.

## Supported compatibility matrix

Support claims in this table come from current in-repo proof only:

1. declared optional dependency ranges in `mix.exs`
2. current lock resolution in `mix.lock`
3. current CI coverage in `.github/workflows/ci.yml`
4. focused guide, doc-contract, and example-app verification for the named lane

| Lane | Claim type | Declared support | Current tested resolution | Proof / CI coverage |
| --- | --- | --- | --- | --- |
| `capture-only` | `supported` | No optional Phoenix surface dependencies required | N/A | `mix verify.compile_no_optional` and CI job `verify-compile-no-optional` |
| `phoenix-surface` | `supported` | `phoenix ~> 1.7`, `phoenix_live_view ~> 1.0`, `phoenix_html ~> 4.0`, `phoenix_pubsub ~> 2.1` | Phoenix `1.8.7`, Phoenix LiveView `1.1.30`, Phoenix HTML `4.3.0`, Phoenix PubSub `2.2.0` | Root `mix.exs`, root `mix.lock`, `mix verify.test`, `mix ci.all`, root doc-contract coverage, and CI jobs `verify-test` / `verify-docs` |
| `sigra-reference` | `reference` | Example host path uses `{:sigra, "~> 0.2", optional: true}` alongside the Phoenix reference app stack | Example app lock resolves Sigra `0.2.5`, Phoenix `1.8.5`, Phoenix LiveView `1.1.28`, Phoenix HTML `4.3.0`, Phoenix PubSub `2.2.0` | `examples/threadline_phoenix/mix.lock`, `examples/threadline_phoenix/README.md`, `guides/integrations/sigra.md`, `mix verify.example`, and focused doc-contract tests |

Threadline does not claim support for Phoenix, LiveView, HTML, PubSub, or Sigra combinations outside these named proofs. The `{:sigra, "~> 0.2", optional: true}` declaration is a host install shape, not a blanket promise covering every Sigra `0.2.x` host. If your lockfile resolves to different versions within the declared ranges, or your host auth/layout differs from the reference path, treat that as your responsibility to verify locally unless and until the Threadline repo updates its own declared ranges, lock resolution references, docs, and CI coverage accordingly.

## Upgrade by Threadline minor

When you upgrade by Threadline minor:

1. read `CHANGELOG.md` for upgrade notes and any announced surface-only deprecations
2. identify your lane before changing dependencies
3. if you are `capture-only`, run `mix verify.compile_no_optional`
4. if you are `phoenix-surface`, confirm your Phoenix stack still fits the declared optional dependency ranges in `mix.exs`
5. if you are following the `sigra-reference` lane, compare your host against the current example-app proof path before widening anything
6. run the lane-appropriate verification entrypoints in the upgraded application

Current guidance by minor:

- **0.5.x → 0.6.x**: Evidence plane (`Threadline.Evidence`, `mix threadline.evidence.show`, `/audit/evidence`), recommended audited write path (`Threadline.Audit.transaction/3`); see `CHANGELOG.md` `[0.6.0]` for deprecated manual GUC + `record_action/2` recipe.
- `0.3.x -> 0.4.x`: the operator surface became an official optional dependency lane. `capture-only` adopters keep the no-optional-deps path. `phoenix-surface` adopters must align with the declared `phoenix`, `phoenix_live_view`, `phoenix_html`, and `phoenix_pubsub` ranges and re-check their router mount/auth setup after upgrade. `sigra-reference` adopters should also re-check the current example app and Sigra guide before treating that path as unchanged.
- future minor upgrades: do not infer support from ecosystem norms or upstream release notes alone. Re-check this guide, the declared optional dependency ranges, the current example-app proof path, and the current changelog entry for the target Threadline minor.

## What breaks when Phoenix/LiveView floors move

If Threadline raises a Phoenix or LiveView floor for the optional surface, the break is surface-only unless the changelog says otherwise.

Typical symptoms:

- `mix deps.get` or dependency resolution fails because your host app pins older Phoenix surface packages outside the declared ranges
- `mix compile` fails in a surface-mounted host because the mounted stack no longer satisfies the declared optional dependency ranges
- docs/examples no longer match your older Phoenix router or LiveView APIs

`capture-only` adopters should not be affected by surface-only dependency floor changes as long as `mix verify.compile_no_optional` continues to pass for the Threadline release they adopt.

## Packaging Boundary Scorecard

Threadline's 0.5.0 integration-breadth era closed with a clear package-boundary decision: stay in-tree for now. The optional Phoenix surface is already isolated behind optional dependencies, the repo still proves one coherent release story from the root package, and the current evidence does not justify the extra versioning and release overhead of a separate `threadline_web` package.

Future extraction is a scorecard decision, not a taste decision. The trigger is "yes, extract" only when one or more of these pressures is sustained and materially increases maintainer or adopter cost:

- **Version Matrix Pressure**: the root package must regularly prove multiple incompatible Phoenix or LiveView lines, or operator-surface dependency movement starts forcing unrelated core-package release coordination.
- **Release Cadence Divergence**: operator-surface changes want to ship on a meaningfully different cadence than the core capture/query APIs, so keeping one package either delays surface fixes or churns the core release line unnecessarily.
- **Adopter Glue Burden**: repeated real-world adopter feedback shows that the in-tree optional surface still leaves too much host-specific mounting or packaging glue, and a separate package would reduce that burden without weakening the core auth-agnostic contract.

Until those pressures are real, Threadline keeps the operator surface optional and in-tree. If a future split happens, Threadline will preserve the public `threadline_operator_surface/2` router integration API so hosts do not have to rewrite their mount call shape as the cost of following the package boundary.

## Surface-only deprecation and removal policy

Threadline treats the operator surface as a public surface-only contract. That contract includes the router macro and documented options, documented mount/auth pattern, documented operator-surface routes, required optional dependency ranges, parity Mix task names and flags, and stable machine-readable literals already locked by tests.

Surface-only deprecations require overlap:

- deprecate in docs and changelog first
- remove no earlier than the next Threadline minor after at least one released overlap window
- do not silently narrow the supported optional dependency ranges without updating this guide and the changelog together

Exceptions are allowed only for security issues, upstream hard incompatibility, or undocumented internals.

## Release checklist for adopters

- Decide whether you are `capture-only`, `phoenix-surface`, or following the `sigra-reference` lane.
- Compare your host dependencies against the declared optional dependency ranges in `mix.exs`.
- If you are `capture-only`, run `mix verify.compile_no_optional`.
- If you are `phoenix-surface`, run `mix ci.all` and verify your mounted routes and auth pipeline still match `guides/operator-surface.md`.
- If you are using the `sigra-reference` lane, run `mix verify.example` and compare your host wiring against `guides/integrations/sigra.md` plus `examples/threadline_phoenix/README.md`.
- Review `CHANGELOG.md` for any surface-only deprecation notice before deploying.

## Canonical references

- `guides/operator-surface.md`
- `guides/integration-contracts.md`
- `guides/integrations/sigra.md`
- `examples/threadline_phoenix/README.md`
- `mix.exs`
- `mix.lock`
- `.github/workflows/ci.yml`
- `CHANGELOG.md`
