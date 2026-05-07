# Upgrade Path

This guide is the canonical lifecycle reference for Threadline's optional Phoenix/LiveView/HTML/PubSub operator surface. `guides/operator-surface.md` covers mount, auth, and screens. This guide answers a different set of questions: which track you are on, what compatibility is actually supported, and how surface-only changes move between Threadline minors.

## Who this guide is for

Use this guide if you are:

- deciding whether you are running capture-only or surface-mounted
- upgrading Threadline across minors and need to know what the operator-surface contract includes
- checking whether a Phoenix/LiveView stack is supported, CI-covered, or merely unclaimed

If you only need router wiring, auth posture, or screen references, stay in `guides/operator-surface.md`.

## How to tell which track you are on

You are on the `capture-only` track when your host application does not depend on Threadline's optional Phoenix surface dependencies and does not mount `threadline_operator_surface/2`. The proof point for this track is `mix verify.compile_no_optional`.

You are on the `surface-mounted` track when your host application adds the optional Phoenix surface dependencies and mounts `threadline_operator_surface/2` in a Phoenix router.

Threadline supports these tracks differently:

- `capture-only` is supported with no optional Phoenix dependencies installed and is enforced by `mix verify.compile_no_optional`.
- `surface-mounted` is supported only for the exact dependency ranges Threadline declares and CI-covers in this release.
- Anything outside the listed ranges is not claimed, even if it may work.

## Supported compatibility matrix

Support claims in this table come from three in-repo sources only:

1. declared optional dependency ranges in `mix.exs`
2. current lock resolution in `mix.lock`
3. current CI coverage in `.github/workflows/ci.yml`

| Track | Declared support | Current tested resolution | Proof / CI coverage |
| --- | --- | --- | --- |
| capture-only | No optional Phoenix surface dependencies required | N/A | `mix verify.compile_no_optional` and CI job `verify-compile-no-optional` |
| surface-mounted | `phoenix ~> 1.7` | Phoenix `1.8.7` | `mix verify.test`, `mix ci.all`, and CI jobs `verify-test` and `verify-docs` |
| surface-mounted | `phoenix_live_view ~> 1.0` | Phoenix LiveView `1.1.30` | `mix verify.test`, `mix ci.all`, and CI jobs `verify-test` and `verify-docs` |
| surface-mounted | `phoenix_html ~> 4.0` | Phoenix HTML `4.3.0` | `mix verify.test`, `mix ci.all`, and CI jobs `verify-test` and `verify-docs` |
| surface-mounted | `phoenix_pubsub ~> 2.1` | Phoenix PubSub `2.2.0` | `mix verify.test`, `mix ci.all`, and CI jobs `verify-test` and `verify-docs` |

Threadline does not claim support for Phoenix, LiveView, HTML, or PubSub versions outside those declared ranges. If your lockfile resolves to different versions within the declared ranges, treat that as your responsibility to verify locally unless and until the Threadline repo updates its own declared ranges, lock resolution references, and CI coverage accordingly.

## Upgrade by Threadline minor

When you upgrade by Threadline minor:

1. read `CHANGELOG.md` for upgrade notes and any announced surface-only deprecations
2. identify your track before changing dependencies
3. if you are capture-only, run `mix verify.compile_no_optional`
4. if you are surface-mounted, confirm your Phoenix stack still fits the declared optional dependency ranges in `mix.exs`
5. run `mix ci.all` in the upgraded application

Current guidance by minor:

- `0.3.x -> 0.4.x`: the operator surface became an official optional dependency track. Capture-only adopters keep the no-optional-deps path. Surface-mounted adopters must align with the declared `phoenix`, `phoenix_live_view`, `phoenix_html`, and `phoenix_pubsub` ranges and re-check their router mount/auth setup after upgrade.
- future minor upgrades: do not infer support from ecosystem norms or upstream release notes alone. Re-check this guide, the declared optional dependency ranges, and the current changelog entry for the target Threadline minor.

## What breaks when Phoenix/LiveView floors move

If Threadline raises a Phoenix or LiveView floor for the optional surface, the break is surface-only unless the changelog says otherwise.

Typical symptoms:

- `mix deps.get` or dependency resolution fails because your host app pins older Phoenix surface packages outside the declared ranges
- `mix compile` fails in a surface-mounted host because the mounted stack no longer satisfies the declared optional dependency ranges
- docs/examples no longer match your older Phoenix router or LiveView APIs

Capture-only adopters should not be affected by surface-only dependency floor changes as long as `mix verify.compile_no_optional` continues to pass for the Threadline release they adopt.

## Surface-only deprecation and removal policy

Threadline treats the operator surface as a public surface-only contract. That contract includes the router macro and documented options, documented mount/auth pattern, documented operator-surface routes, required optional dependency ranges, parity Mix task names and flags, and stable machine-readable literals already locked by tests.

Surface-only deprecations require overlap:

- deprecate in docs and changelog first
- remove no earlier than the next Threadline minor after at least one released overlap window
- do not silently narrow the supported optional dependency ranges without updating this guide and the changelog together

Exceptions are allowed only for security issues, upstream hard incompatibility, or undocumented internals.

## Release checklist for adopters

- Decide whether you are `capture-only` or `surface-mounted`.
- Compare your host dependencies against the declared optional dependency ranges in `mix.exs`.
- If you are `capture-only`, run `mix verify.compile_no_optional`.
- If you are `surface-mounted`, run `mix ci.all` and verify your mounted routes and auth pipeline still match `guides/operator-surface.md`.
- Review `CHANGELOG.md` for any surface-only deprecation notice before deploying.

## Canonical references

- `guides/operator-surface.md`
- `mix.exs`
- `mix.lock`
- `.github/workflows/ci.yml`
- `CHANGELOG.md`
