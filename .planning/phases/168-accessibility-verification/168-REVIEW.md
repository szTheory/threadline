---
phase: 168-accessibility-verification
reviewed: 2026-06-14T00:00:00Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - test/threadline/operator_surface/style_contract_test.exs
  - examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex
  - examples/threadline_phoenix/e2e/playwright.config.ts
  - examples/threadline_phoenix/e2e/run-e2e.sh
findings:
  critical: 1
  warning: 5
  info: 3
  total: 9
status: resolved
resolved_in: 33ae611
---

# Phase 168: Code Review Report

**Reviewed:** 2026-06-14
**Depth:** standard
**Files Reviewed:** 4
**Status:** resolved (all 9 findings addressed in `33ae611`)

> **Resolution (commit `33ae611`):**
> - **CR-01 / WR-01 / IN-02 / IN-03** — the `desktop-chromium-light` project is now
>   registered ONLY when `THREADLINE_E2E_THEME=system` and scoped via `testMatch` to
>   `operator-accessibility.spec.ts`; `run-e2e.sh` targets `--project=desktop-chromium-light`
>   for the light lane; and a committed entrypoint `mix verify.example_browser_light`
>   runs the proof. A default run no longer registers a light project (verified via
>   `playwright test --list`), so the false-confidence/dark-mount path is gone; the
>   light lane was run and passed 4/4 against `data-tl-theme="system"`.
> - **WR-02** — focus halo alpha is parsed from the actual `--tl-focus-ring` source
>   per lane (`focus_ring_halo!/1`), not a hardcoded literal.
> - **WR-03** — `color_tokens` name class broadened to `[a-z0-9-]+`; a guard test now
>   fails if any `--tl-color-*` declaration uses a value format the parser drops.
> - **WR-04** — `hex_to_rgb/1` guards 6-hex-digit input and flunks clearly otherwise.
> - **WR-05** — `composite/2` output is uppercase by contract.
> - **IN-01** — added a `normalize_alpha` unit test for leading-dot / bare-integer alpha.

## Summary

Phase 168 adds an alpha-aware `color_tokens` parser + `composite/2` to the style
contract test (so translucent `rgba(...)` status tints can be WCAG-checked), a
light/system AA contrast mirror, a focus-ring 3:1 + interaction-state assertion
set, a compile-time `THREADLINE_E2E_THEME=system` router gate to serve the
`:system` lane, a new `desktop-chromium-light` Playwright project, and a
`touch router.ex` recompile guard in `run-e2e.sh`.

The Elixir test helpers (`composite/2`, `parse_color_value`, `hex_to_rgb`,
`normalize_alpha`) are arithmetically correct for the tokens present today and the
suite passes (31 tests, 0 failures). The headline defect is in the **end-to-end
wiring**: the `desktop-chromium-light` project is added unconditionally to the
default `npm test` run, but the `THREADLINE_E2E_THEME=system` env that the whole
mechanism depends on is **never set by any caller** (CI, `package.json`,
`run-e2e.sh`, Makefile — none). The result is that the "light-lane proof" runs
the entire spec suite against a `:dark`-compiled mount with only browser-level
`colorScheme: "light"` emulation, proving nothing about the
`[data-tl-theme="system"]` branch it claims to exercise — a false-confidence
accessibility verification, which is the explicit deliverable of this phase.

The parser and test also carry several latent-robustness and test-integrity gaps
documented below.

## Critical Issues

### CR-01: Light-lane e2e proof is inert — `THREADLINE_E2E_THEME` is never set, and the light project runs the full suite against the dark mount

**File:** `examples/threadline_phoenix/e2e/playwright.config.ts:31-34`, `examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex:177`, `examples/threadline_phoenix/e2e/run-e2e.sh:94-99`

**Issue:** The mechanism has three coupled parts that are not connected:

1. `router.ex:177` gates the `:system` mount on `System.get_env("THREADLINE_E2E_THEME") == "system"` at **compile time**.
2. `playwright.config.ts` adds `desktop-chromium-light` (colorScheme `"light"`) to the `projects` array unconditionally.
3. `run-e2e.sh` runs `npm test` → `playwright test` with **no `--project` filter** (`package.json` test script is bare `playwright test`), so every project — including `desktop-chromium-light` — runs every spec.

A repo-wide search shows `THREADLINE_E2E_THEME` appears only inside the gate
itself and in comments — **no CI workflow, `package.json`, `run-e2e.sh`, env file,
Makefile, or justfile ever exports it**. Consequences:

- The router always compiles the `else` branch (`:dark`). The
  `desktop-chromium-light` project therefore talks to a `:dark` mount; the served
  markup never carries `data-tl-theme="system"`, so the
  `@media (prefers-color-scheme: light)` system branch is never resolved. The
  "affordances are mode-independent" claim in the config comment is unverified.
- Even when the env *is* set, the recompile guard switches the **single** mount
  to `:system` for **all** projects in the same `npm test` run — the dark
  projects (`chromium`, `desktop-chromium`, `mobile-chromium`) would then run
  against a `:system` mount. There is no per-project theme isolation; one
  `playwright test` invocation cannot serve both `:dark` and `:system`.

This is the phase's primary deliverable (A11Y-02 part 2, accessibility
verification of the light lane) and it does not actually verify anything.

**Fix:** Make the light-lane run a dedicated, env-scoped invocation rather than a
project appended to the default run. For example, gate the project on the env and
run it as a separate pass:

```ts
// playwright.config.ts — only register the light project when the server is
// actually compiled :system, and have it run ONLY the affordance spec.
const lightLane = process.env.THREADLINE_E2E_THEME === "system";
projects: [
  { name: "chromium", use: { ...devices["Desktop Chrome"] } },
  { name: "desktop-chromium", use: { ...devices["Desktop Chrome"], viewport: { width: 1280, height: 900 } } },
  { name: "mobile-chromium", use: { ...devices["Pixel 5"] } },
  ...(lightLane
    ? [{
        name: "desktop-chromium-light",
        testMatch: /operator-accessibility\.spec\.ts/,   // the "SAME affordance spec" the comment promises
        use: { ...devices["Desktop Chrome"], viewport: { width: 1280, height: 900 }, colorScheme: "light" },
      }]
    : []),
]
```

```bash
# run-e2e.sh — add a second, explicitly env-scoped pass after the dark run, each
# with its own recompile so the served theme matches the project under test.
THREADLINE_E2E_THEME=system  # export before the recompile+server boot for the light pass
npm test -- --project=desktop-chromium-light
```

At minimum, fail loudly: if `desktop-chromium-light` runs while
`THREADLINE_E2E_THEME != "system"`, the affordance spec should assert the served
`data-tl-theme` attribute is `system` (or skip with a clear message) so the
inert state cannot pass silently.

## Warnings

### WR-01: `desktop-chromium-light` runs the entire spec suite, not the "SAME affordance spec verbatim"

**File:** `examples/threadline_phoenix/e2e/playwright.config.ts:31-34`

**Issue:** The config comment states the project "re-runs the SAME affordance
spec verbatim." Playwright projects, however, run **all** specs in `testDir`
unless `testMatch`/`grep` scopes them. With no scoping, `desktop-chromium-light`
runs mobile-targeted specs (`operator-find-mobile`, `operator-prove-mobile`,
`operator-home-nav-mobile`, `operator-responsive-mobile-first`) at a 1280x900
desktop viewport, plus `operator-screenshot-regression` and `operator-motion`.
The mobile-first specs assert mobile layout/affordances and are liable to fail or
silently mis-pass at desktop width. The comment's promise and the actual behavior
diverge.

**Fix:** Add `testMatch: /operator-accessibility\.spec\.ts/` (or the intended
affordance spec) to the `desktop-chromium-light` project so it runs only what the
comment claims.

### WR-02: Focus-ring halo alpha is a hardcoded literal, not parsed from the source — test can silently rot

**File:** `test/threadline/operator_surface/style_contract_test.exs:882`

**Issue:** The focus-ring test hardcodes `composite({21, 87, 192, 0.22}, ...)`
instead of extracting the halo layer from the actual `--tl-focus-ring` token in
`style.ex` (lines 236/288). The test asserts "the translucent halo alone must NOT
reach 3:1," but it tests a duplicated constant. If the source halo alpha changes
(e.g. to `0.40`), the CSS could regress to a halo-masking focus affordance while
this test keeps passing against the stale `0.22`. The test claims source-fidelity
("REPORTED ... value=#{halo_ratio}") it does not have.

**Fix:** Parse the first rgba layer out of the `--tl-focus-ring` value in each
lane and feed that tuple to `composite/2`, so the assertion tracks the real
source:

```elixir
halo = focus_ring_halo!(map_or_block)   # regex the rgba(...) before the first comma in --tl-focus-ring
halo_over_surface = composite(halo, map["--tl-color-surface"])
```

### WR-03: `color_tokens` parser silently drops digit-named and 8-digit-hex/AA tokens — the same silent-drop class the phase claims to fix

**File:** `test/threadline/operator_surface/style_contract_test.exs:1316`

**Issue:** The token-name group is `--tl-color-[a-z-]+` and the value group
accepts only `#[0-9a-fA-F]{6}` or `rgba(...)`. Verified by probe:
- A token like `--tl-color-surface-2: ...` (digit in name) is not matched and is
  silently dropped (returns no entry → `map[token]` is `nil`).
- An 8-digit `#RRGGBBAA` value is silently dropped.
- An rgba with an integer alpha (`rgba(10,20,30,1)`) *is* matched (good), but
  `#RGB` shorthand and `hsl(...)` are not.

No such tokens exist in `style.ex` today, so this is latent — but the entire
premise of the phase is "stop silently dropping translucent tokens from the WCAG
check." A future `--tl-color-accent-2` or `#RRGGBBAA` reintroduces exactly the
blind spot the phase set out to close, with no test failure to flag it.

**Fix:** Broaden the name class to `[a-z0-9-]+` and either support `#RRGGBBAA` /
`#RGB` or add a guard test that fails if any `--tl-color-*` declaration in
`style.ex` is not captured by `color_tokens/1` (close the parser-coverage gap
explicitly rather than relying on absence).

### WR-04: `hex_to_rgb`/`composite` assume 6-digit base hex; a 3-digit base raises an opaque MatchError

**File:** `test/threadline/operator_surface/style_contract_test.exs:1352-1360`

**Issue:** `hex_to_rgb/1` chunks the hex into 2-char pairs and binds `[r, g, b] = ...`.
A 3-digit shorthand base (`"#FFF"`) yields `["FF", "F"]` (2 elements) → MatchError;
an 8-digit base yields 4 elements → MatchError. `composite/2`'s base is
caller-named, so a future caller passing a non-6-digit base hits a cryptic crash
with no context. Same brittleness in `relative_luminance/1` (line 1371).

**Fix:** Add a guard/clear flunk for non-6-hex-digit input, e.g.
`defp hex_to_rgb("#" <> hex) when byte_size(hex) == 6 do ... end` plus a fallback
clause that `flunk`s with the offending value.

### WR-05: `composite/2` output casing is unspecified and only one call-site upcases — equality assertions are casing-fragile

**File:** `test/threadline/operator_surface/style_contract_test.exs:1342-1350`

**Issue:** `Integer.to_string(n, 16)` returns uppercase hex, so `composite/2`
currently emits uppercase (`#F6EBEB`). The composited values are then fed back
into `composite/2`/`contrast_ratio/2` and compared via the
`composited_rows`/halo paths. The one place a literal-equality check exists
(`assert String.upcase(over_white) == "#F6EBEB"`, line 720) defensively upcases —
implying the author was unsure of the casing contract. Any future helper that
string-compares composite output without normalizing (e.g. `composite(...) ==
"#abc123"`) will be casing-fragile.

**Fix:** Normalize `composite/2` output deterministically
(`|> String.downcase()` or `String.upcase()`) and document the contract, so
callers can compare without per-call defensive casing.

## Info

### IN-01: `normalize_alpha` is dead-ended for the integer-alpha case it appears to guard

**File:** `test/threadline/operator_surface/style_contract_test.exs:1331-1332`

**Issue:** `normalize_alpha/1` handles a leading-dot alpha (`".5"` → `"0.5"`) and
appends `".0"` to a bare integer (`"1"` → `"1.0"`). The leading-dot branch is
never exercised because the source rgba tokens are all authored with a leading
zero (`0.10`, `0.22`), and the bare-integer branch is never exercised because no
rgba in `style.ex` uses integer alpha. The helper is defensively correct but
currently untested in practice; keep it but consider a unit test so the branches
are not silently dead.

**Fix:** Add a small parser unit test covering `".5"` and `"1"` alpha inputs, or
drop the unused branch if integer/leading-dot alpha is disallowed by convention.

### IN-02: `desktop-chromium-light` will generate a new snapshot baseline set under its project name

**File:** `examples/threadline_phoenix/e2e/playwright.config.ts:8,31-34`

**Issue:** `snapshotPathTemplate` embeds `{projectName}`, and existing baselines
exist only for `chromium` (10 PNGs). The screenshot-regression spec is
`test.skip(!!process.env.CI)` so CI is unaffected, but a local run of the new
project would auto-create a `*-desktop-chromium-light` baseline set on first run
(masking real visual regressions for that lane until reviewed). Low impact given
the CI skip and the `{projectName}` isolation; noted for completeness.

**Fix:** If the light project is scoped to the affordance spec (per WR-01), it
will not touch the screenshot guard at all; otherwise, decide intentionally
whether light-lane baselines should exist.

### IN-03: `operator-screenshot-regression` viewport guard does not handle `desktop-chromium-light`

**File:** `examples/threadline_phoenix/e2e/tests/operator-screenshot-regression.spec.ts:84-92`

**Issue:** The `beforeEach` sets viewport explicitly for `desktop-chromium` and
`mobile-chromium` but has no branch for `desktop-chromium-light`. If the new
project runs this spec (it will, absent WR-01's `testMatch`), the screenshot tests
execute with the device default rather than the intended 1280x900, producing
inconsistent baselines. Resolved automatically if WR-01 scopes the light project.

**Fix:** Either scope the light project away from this spec (WR-01) or add a
`desktop-chromium-light` branch mirroring the `desktop-chromium` 1280x900 case.

---

_Reviewed: 2026-06-14_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
