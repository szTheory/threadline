# Phase 122: Release & Distribution Truth — Pattern Mapping

**Mapped:** 2026-05-28  
**Phase:** 122-release-distribution-truth  
**Requirements:** DIST-01, DIST-02, DIST-03  
**Context SSOT:** `122-CONTEXT.md` · **Research SSOT:** `122-RESEARCH.md`

---

## 1. File inventory (create / modify)

| File | Wave | Action | Requirement |
|------|------|--------|-------------|
| `CHANGELOG.md` | 1 | **Modify** | DIST-03 — four-lane upgrade bullet in `[0.6.0]` |
| `test/threadline/release_distribution_doc_contract_test.exs` | 1 | **Create** (recommended) | DIST-03 — regression lock on `[0.6.0]` section |
| `mix.exs` | 1 | **Modify** (conditional) | Wire new test into `verify.doc_contract` alias only |
| `test/threadline/adoption_pilot_doc_contract_test.exs` | 1 + 3 | **Modify** | DIST-02 — conditional anti-stale when Hex row OK |
| `test/threadline/evaluating_threadline_doc_contract_test.exs` | 1 + 3 | **Modify** | DIST-02 — conditional anti-stale via adoption-pilot SSOT chain |
| `guides/adoption-pilot-backlog.md` | 3 | **Modify** | DIST-01 + DIST-02 — Hex row Pending → OK + evidence |
| `guides/evaluating-threadline.md` | 3 | **Modify** | DIST-02 — remove hex lag caveat |
| `.planning/phases/122-release-distribution-truth/122-VERIFICATION.md` | 3 | **Create** | DIST-01 — maintainer attestation record |
| `.planning/REQUIREMENTS.md` | 3 | **Modify** | Tick DIST-01–03 |
| `.planning/STATE.md` | 3 | **Modify** | Hex lag resolved; phase progress |
| `.planning/ROADMAP.md` | 3 | **Modify** | Mark Phase 122 complete |
| `CONTRIBUTING.md` | 3 | **Modify** (optional) | One-line DIST-01 proof pointer |

**Wave 2 (maintainer gate):** no repo files — annotated tag `v0.6.0`, green `hex-publish.yml`, `mix hex.info threadline`.

**Explicit no-touch (out of scope):**

| File | Reason |
|------|--------|
| `.github/workflows/hex-publish.yml` | Publish policy unchanged |
| `mix.exs` `@version` | Already `0.6.0` |
| `guides/upgrade-path.md` | Four-lane matrix SSOT — CHANGELOG links here only |
| `README.md` | Four-lane vocabulary already correct |
| `test/threadline/release_artifact_contract_test.exs` | Stays in `verify.release`; prefer separate distribution doc contract |

---

## 2. Per-file role classification

### Wave 1 — source truth + doc contracts (safe pre-publish)

| File | Role | Data flow |
|------|------|-----------|
| `CHANGELOG.md` | **Adopter-facing release narrative** | Names four lane IDs briefly → deep matrix in `upgrade-path.md` |
| `release_distribution_doc_contract_test.exs` | **Regression gate (automated)** | Reads `CHANGELOG.md` `[0.6.0]` section → asserts lane IDs + link |
| `mix.exs` | **Verification router** | `verify.doc_contract` alias lists doc-contract test files |
| `adoption_pilot_doc_contract_test.exs` | **Conditional honesty gate** | Reads backlog → if Hex row OK, refute stale lag prose; always lock `@version` + `~> 0.6` |
| `evaluating_threadline_doc_contract_test.exs` | **Downstream honesty gate** | Reads adoption-pilot SSOT → if Hex OK, refute evaluating lag caveat |

### Wave 2 — registry publish (human + event-triggered CI)

| Artifact | Role | Data flow |
|----------|------|-----------|
| Git tag `v0.6.0` | **Release event trigger** | Tag push → `hex-publish.yml` → hex.pm registry |
| `hex-publish.yml` | **Registry automation** (unchanged) | `GITHUB_REF_NAME` ↔ `@version` gate → `mix hex.publish --yes` |
| `mix verify.release` | **Pre-tag source gate** | Clean tree → release-shape → artifact contracts → docs → `hex.build` |
| `mix hex.info threadline` | **Human registry proof** | Maintainer confirms **0.6.0** in Recent releases |

### Wave 3 — post-publish sync (maintainer-authored + doc contracts activate)

| File | Role | Data flow |
|------|------|-----------|
| `guides/adoption-pilot-backlog.md` | **Adopter-facing distribution SSOT** | Maintainer attestation → OK row with date, workflow URL, CONTRIBUTING pointer |
| `guides/evaluating-threadline.md` | **Evaluator packaging anchor** | Points at Hex 0.6.0 + preflight; no “may still list 0.5.0” |
| `122-VERIFICATION.md` | **GSD / maintainer audit trail** | Tag + workflow URL + redacted `mix hex.info` excerpt |
| `REQUIREMENTS.md` / `STATE.md` / `ROADMAP.md` | **Planning closeout** | Requirement ticks; phase complete markers |
| `CONTRIBUTING.md` | **Procedure SSOT** (optional cross-link) | Publish runbook; not alone sufficient for DIST-01 “recorded” |

---

## 3. Closest analog + code excerpts

### 3.1 `CHANGELOG.md` — four-lane upgrade bullet (modify)

**Role:** Adopter-facing release narrative; lane names only, matrix SSOT elsewhere.

**Current gap (line 38 — three lanes, missing `phx-gen-auth-reference`):**

```38:38:CHANGELOG.md
- See `guides/upgrade-path.md` for lane matrix (`capture-only`, `phoenix-surface`, `sigra-reference`) and surface deprecation policy.
```

**Closest analog — README four-lane canonical order (target enumeration):**

```54:57:test/threadline/readme_doc_contract_test.exs
    assert String.contains?(
             readme,
             "canonical `capture-only`, `phoenix-surface`, `phx-gen-auth-reference`, and `sigra-reference` matrix"
           )
```

**Closest analog — upgrade-path four-lane matrix SSOT (do not duplicate in CHANGELOG):**

```92:98:test/threadline/upgrade_path_doc_contract_test.exs
  test "upgrade-path guide locks the four named lanes and their proof anchors" do
    guide = File.read!("guides/upgrade-path.md")

    assert String.contains?(guide, "| `capture-only` | `supported` |")
    assert String.contains?(guide, "| `phoenix-surface` | `supported` |")
    assert String.contains?(guide, "| `phx-gen-auth-reference` | `reference` |")
    assert String.contains?(guide, "| `sigra-reference` | `reference` |")
```

**Pattern to replicate:** Option A minimal fix — replace parenthetical on line 38 with four IDs in canonical order; keep `guides/upgrade-path.md` link; do **not** add `### Adopter lanes` or rewrite `[0.5.0]` history (D-09, D-10).

---

### 3.2 `test/threadline/release_distribution_doc_contract_test.exs` — **CREATE**

**Role:** Automated DIST-03 regression lock scoped to `[0.6.0]` only.

**Closest analog — scoped section extraction (`upgrade_path_doc_contract_test.exs`):**

```156:171:test/threadline/upgrade_path_doc_contract_test.exs
  test "upgrade-path guide locks 0.5.x to 0.6.x minor upgrade bullet" do
    guide = File.read!("guides/upgrade-path.md")

    {idx_minor, _} = :binary.match(guide, "## Upgrade by Threadline minor")
    {idx_phoenix, _} = :binary.match(guide, "## What breaks when Phoenix")
    scope = {idx_minor, idx_phoenix - idx_minor}

    assert :binary.match(guide, "0.5.x → 0.6.x", scope: scope) != :nomatch or
             :binary.match(guide, "0.5.x -> 0.6.x", scope: scope) != :nomatch
    ...
    assert :binary.match(guide, "[0.6.0]", scope: scope) != :nomatch
  end
```

**Closest analog — release artifact contract (CHANGELOG in package, but no lane assertions today):**

```26:37:test/threadline/release_artifact_contract_test.exs
  test "release package includes the shipped documentation surfaces" do
    files = package_files()
    extras = docs_config()[:extras]

    assert "guides" in files
    assert "README.md" in files
    assert "CHANGELOG.md" in files
    assert "CONTRIBUTING.md" in files
    ...
  end
```

**Pattern to replicate:**

```elixir
# Suggested shape (new file)
defmodule Threadline.ReleaseDistributionDocContractTest do
  use ExUnit.Case, async: true

  @changelog "CHANGELOG.md"
  @lanes ~w(capture-only phoenix-surface phx-gen-auth-reference sigra-reference)

  defp section_0_6_0 do
    changelog = File.read!(@changelog)
    [_before, rest] = String.split(changelog, "## [0.6.0]", parts: 2)
    section = hd(String.split(rest, "\n## [", parts: 2))
    section
  end

  test "CHANGELOG [0.6.0] upgrade section lists four canonical lane IDs in order" do
    section = section_0_6_0()
    assert String.contains?(section, "guides/upgrade-path.md")
    assert section =~ ~r/`capture-only`, `phoenix-surface`, `phx-gen-auth-reference`, `sigra-reference`/
    refute section =~ ~r/`capture-only`, `phoenix-surface`, `sigra-reference`/
  end
end
```

Wire into `mix verify.doc_contract` (not `verify.release`) — mirrors other adopter-critical doc contracts.

---

### 3.3 `mix.exs` — `verify.doc_contract` alias (conditional modify)

**Role:** Verification entrypoint router; lists doc-contract test files for `mix ci.all`.

**Closest analog — current alias list:**

```80:82:mix.exs
      "verify.doc_contract": [
        "test test/threadline/readme_doc_contract_test.exs test/threadline/how_threadline_works_doc_contract_test.exs test/threadline/operator_surface_doc_contract_test.exs test/threadline/upgrade_path_doc_contract_test.exs test/threadline/getting_started_saas_doc_contract_test.exs test/threadline/audit_doc_contract_test.exs test/threadline/integration_contracts_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs test/threadline/adoption_pilot_doc_contract_test.exs test/threadline/evaluating_threadline_doc_contract_test.exs test/threadline/evidence_cli_doc_contract_test.exs test/threadline/v1_23_charter_doc_contract_test.exs test/threadline/exploration_routing_doc_contract_test.exs test/threadline/semver_adopter_doc_contract_test.exs test/threadline/integrations/phx_gen_auth_doc_contract_test.exs"
      ],
```

**Contrast — `release_artifact_contract_test.exs` lives under `verify.release`:**

```111:119:mix.exs
  defp verify_release(_args) do
    ensure_clean_tree!()

    [
      "bin/verify-release-shape",
      "mix test test/threadline/release_artifact_contract_test.exs test/threadline/ci_topology_contract_test.exs",
      "MIX_ENV=dev mix docs",
      "mix hex.build"
    ]
```

**Pattern to replicate:** Append `release_distribution_doc_contract_test.exs` to `verify.doc_contract` only if new file is created; no `@version` change.

---

### 3.4 `test/threadline/adoption_pilot_doc_contract_test.exs` — conditional anti-stale

**Role:** Locks in-repo version + constraint always; refutes stale hex lag **only when** Hex row is OK.

**Closest analog — existing always-on version/constraint tests:**

```8:16:test/threadline/adoption_pilot_doc_contract_test.exs
  test "adoption-pilot distribution preflight matches mix.exs version and ~> 0.6 constraint" do
    guide = File.read!(@guide)

    assert String.contains?(guide, @version)
    assert String.contains?(guide, "~> 0.6")
    refute String.contains?(guide, "~> 0.5")
    refute String.contains?(guide, "0.2.0")
    refute String.contains?(guide, "~> 0.2")
  end
```

**Closest analog — honest Pending row (current pre-publish state):**

```13:13:guides/adoption-pilot-backlog.md
| `threadline` **0.6.0** on [Hex](https://hex.pm/packages/threadline) | Pending | Verified 2026-05-27: [hex.pm](https://hex.pm/packages/threadline) latest is **0.5.0**; in-repo `@version` is **0.6.0** (`mix hex.build` OK). Unblock: push annotated tag **`v0.6.0`** → CI `hex-publish.yml` (see [CONTRIBUTING.md](../CONTRIBUTING.md#hex-publish-maintainers)). Doc contract: `test/threadline/adoption_pilot_doc_contract_test.exs` |
```

**Closest analog — STG-style OK = pointer (not full output paste):**

```38:39:test/threadline/stg_doc_contract_test.exs
    assert String.contains?(section, "| `POST /api/posts` | HTTP | OK |")
    assert String.contains?(section, "| `GET /api/audit_transactions/:id/changes` | HTTP | OK |")
```

**Pattern to replicate:**

```elixir
# New test — passes while Pending; enforces when OK (D-07)
test "when Hex distribution row is OK, refutes stale 0.5.0 lag narrative" do
  guide = File.read!(@guide)
  hex_row = guide |> String.split("\n") |> Enum.at(12)  # fragile: document line or parse first data row after header

  if String.contains?(hex_row, "| OK |") do
    refute String.contains?(guide, "latest is **0.5.0**")
    refute String.contains?(guide, "Unblock: push tag")
  end
end
```

**Explicit rejection (D-03):** do **not** `assert` Hex row `| OK |` whenever `@version == "0.6.0"`.

---

### 3.5 `test/threadline/evaluating_threadline_doc_contract_test.exs` — SSOT chain

**Role:** Evaluator guide locks; post-publish refutes lag caveat when adoption-pilot Hex row is OK.

**Closest analog — existing 0.6.0 anchor + preserved 0.5.0 upgrade context:**

```6:13:test/threadline/evaluating_threadline_doc_contract_test.exs
  test "evaluating guide exists with 0.6.0 packaging anchor (PILOT-02)" do
    guide = File.read!(@guide)

    assert String.contains?(guide, "0.6.0")
    assert String.contains?(guide, "Audit.transaction/3")
    assert String.contains?(guide, "0.5.0")
    assert String.contains?(guide, "0.6.0 packages Evidence")
  end
```

**Current lag caveat (Wave 3 removal target):**

```11:11:guides/evaluating-threadline.md
Threadline **0.6.0** is the in-repo and doc SSOT (`mix.exs` `@version`). As of 2026-05-27, [hex.pm](https://hex.pm/packages/threadline) may still list **0.5.0** as latest until maintainers push tag **`v0.6.0`** (see [`guides/adoption-pilot-backlog.md`](adoption-pilot-backlog.md) Distribution preflight).
```

**Pattern to replicate:**

```elixir
defp adoption_pilot_hex_ok? do
  backlog = File.read!("guides/adoption-pilot-backlog.md")
  # parse first Distribution preflight data row; true when status cell contains OK
end

test "when adoption-pilot Hex row is OK, refutes hex still 0.5.0 caveat" do
  guide = File.read!(@guide)
  if adoption_pilot_hex_ok?() do
    refute String.contains?(guide, "may still list **0.5.0** as latest")
  end
end
```

Keep existing `0.5.0` assert (semver upgrade story, not “latest” claim).

---

### 3.6 `guides/adoption-pilot-backlog.md` — Hex row OK + evidence (Wave 3)

**Role:** Adopter-facing distribution preflight SSOT; DIST-01 adopter half of verification record.

**Closest analog — existing OK row with dated, pointer-style evidence:**

```14:15:guides/adoption-pilot-backlog.md
| App depends on `{:threadline, "~> 0.6"}` | OK | README + adoption-pilot doc contract lock constraint |
| `mix deps.get` resolves without overrides | OK | **GitHub Actions** runs `mix deps.get` per job ...
```

**Pattern to replicate (D-05 post-publish cell shape):**

- Status: `OK`
- Evidence: `Verified YYYY-MM-DD:` + hex.pm latest **0.6.0** + link to successful `hex-publish.yml` run for tag **`v0.6.0`** + pointer to `CONTRIBUTING.md#hex-publish-maintainers` for `mix hex.info threadline`
- Do **not** paste full `mix hex.info` output

**Honest Pending (Wave 1 — do not merge OK before registry):**

- Keep `Pending` + “latest is **0.5.0**” + “Unblock: push tag **`v0.6.0`**” until Wave 2 completes (D-06).

---

### 3.7 `guides/evaluating-threadline.md` — remove lag caveat (Wave 3)

**Role:** Evaluator packaging anchor; must align with Hex + preflight after publish.

**Pattern to replicate:** Replace lag paragraph with Hex serves **0.6.0**; see adoption-pilot Distribution preflight for maintainer attestation. Preserve **0.5.0** elsewhere for upgrade semver narrative.

---

### 3.8 `.planning/phases/122-release-distribution-truth/122-VERIFICATION.md` — **CREATE**

**Role:** Maintainer-facing DIST-01 record; GSD audit trail without network in `mix test`.

**Closest analog — Phase 114 verification (packaging passed; publish deferred):**

```1:31:.planning/milestones/v1.25-phases/114-release-0-6-0-packaging/114-VERIFICATION.md
---
status: passed
phase: 114-release-0-6-0-packaging
verified: 2026-05-27
score: 4/4
---

# Phase 114 Verification Report
...
## Human Verification

None required — release packaging is fully machine-verified. Maintainer tag/publish remains manual follow-up per plan 114-03.
```

**Phase 122 delta:** Human verification **is required** — tag `v0.6.0`, successful `hex-publish.yml` run URL, redacted `mix hex.info threadline` excerpt with line containing **0.6.0**.

**Pattern to replicate:**

```markdown
---
status: passed
phase: 122-release-distribution-truth
verified: YYYY-MM-DD
requirements: DIST-01, DIST-02, DIST-03
---

# Phase 122 Verification Report

## Registry publish (DIST-01)
- Tag: `v0.6.0`
- Workflow: <successful hex-publish.yml run URL>
- Registry: `mix hex.info threadline` excerpt (redacted) showing **0.6.0** in releases

## Adopter surfaces (DIST-02)
- adoption-pilot Hex row: OK with dated evidence
- evaluating-threadline: no stale 0.5.0-as-latest caveat

## CHANGELOG (DIST-03)
- `[0.6.0]` four-lane bullet + doc contract green
```

CONTRIBUTING remains procedure SSOT — not sufficient alone for DIST-01 “recorded” (D-02).

---

### 3.9 Planning closeout files (Wave 3)

**Role:** Requirement traceability and phase state.

**Closest analog — unchecked DIST requirements:**

```16:18:.planning/REQUIREMENTS.md
- [ ] **DIST-01**: Maintainer publishes **`threadline` 0.6.0** to hex.pm via tag **`v0.6.0`** and CI `hex-publish.yml`; post-publish verification recorded (adoption-pilot or milestone closeout note).
- [ ] **DIST-02**: `guides/adoption-pilot-backlog.md` **Published** row and distribution preflight reflect **0.6.0** on hex.pm (not stale 0.5.0-only narrative).
- [ ] **DIST-03**: `CHANGELOG.md` 0.6.0 entry mentions **four-lane** adopter matrix including **`phx-gen-auth-reference`** (v1.26 carry-forward for evaluator honesty).
```

**Pattern to replicate:** Tick all three after Wave 3; update `STATE.md` Hex distribution line; mark Phase 122 complete in `ROADMAP.md` success criteria.

---

### 3.10 `CONTRIBUTING.md` — optional cross-link (Wave 3)

**Role:** Maintainer publish procedure SSOT.

**Closest analog — existing tag/publish sequence:**

```120:133:CONTRIBUTING.md
**Tag-triggered publish:** pushing an annotated SemVer tag matching **`vMAJOR.MINOR.PATCH`** runs [`.github/workflows/hex-publish.yml`](.github/workflows/hex-publish.yml). It checks that **`GITHUB_REF_NAME`** (e.g. `v0.6.0`) matches **`@version`** in `mix.exs` (e.g. `0.6.0`), then runs **`mix hex.publish --yes`** with **`HEX_API_KEY`**.

1. Add repository secret **`HEX_API_KEY`** ...
2. Run `mix verify.release` from a clean working tree ...
...
5. Watch the **Hex publish** workflow on the Actions tab; confirm with **`mix hex.info threadline`** after the registry updates.
```

**Optional one-liner (D-16 discretion):** “DIST-01 proof = adoption-pilot OK row + `122-VERIFICATION.md`.”

---

### 3.11 Reference-only — `hex-publish.yml` (no change)

**Role:** Event-triggered registry publish; tag ↔ `@version` gate.

```31:49:.github/workflows/hex-publish.yml
      - name: Confirm tag matches mix.exs @version
        run: |
          set -euo pipefail
          TAG="${GITHUB_REF_NAME}"
          ...
          if [[ "$MIX_VER" != "$VER" ]]; then
            echo "Tag $TAG implies version $VER but mix.exs has @version \"$MIX_VER\"" >&2
            exit 1
          fi
          echo "Publishing version $VER for tag $TAG"
```

---

## 4. Patterns to replicate (cross-cutting)

### 4.1 Doc contracts — prose shape, not registry truth

From OSS DNA (`prompts/threadline-elixir-oss-dna.md` §2–3):

- **Doc contract tests** lock README ↔ guides ↔ CHANGELOG prose shape.
- **Version SSOT** is `mix.exs`; registry alignment happens **after tag**, not via per-PR hex.pm polling.
- **Three-layer model** (Phase 114 → 122): local `mix verify.release` → contributor `mix ci.all` → human/registry publish + attestation files.

| Layer | Phase 122 artifact |
|-------|-------------------|
| Source | `mix verify.release`, `release_artifact_contract_test.exs` |
| CI | `verify-release-shape`, `verify-hex-package`, `mix ci.all` |
| Registry | `hex-publish.yml` on tag `v0.6.0` |
| Human | `mix hex.info threadline` |
| Record | `122-VERIFICATION.md` + adoption-pilot OK row |

### 4.2 Honest Pending

- Pre-publish: Hex row **Pending** with “latest is **0.5.0**” + unblock tag narrative.
- Conditional tests **pass** while Pending; anti-stale refutes activate only when row is **OK**.
- Never auto-assert `| OK |` from `@version == "0.6.0"` (inverts honesty model).

### 4.3 Four-lane SSOT chain

```
upgrade-path.md (matrix SSOT)
    ↑ link only
CHANGELOG.md [0.6.0] (four ID names)
    ↑ doc contract
release_distribution_doc_contract_test.exs
    ↑ canonical order from
readme_doc_contract_test.exs / upgrade_path_doc_contract_test.exs
```

CHANGELOG must **not** duplicate the matrix table (D-10).

### 4.4 Maintainer gate checklist (Wave 2 — 122-02-PLAN)

Execute **after** Wave 1 PR merges and `main` is green:

1. `git status --porcelain` — empty tree
2. `mix verify.release` on commit to tag
3. Green CI on `main` (branch protection jobs)
4. `git tag -a v0.6.0 -m "Release v0.6.0"` && `git push origin v0.6.0`
5. Watch **Hex publish** workflow — job “Publish package and docs”
6. `mix hex.info threadline` — Recent releases includes **0.6.0**; config reflects `~> 0.6`
7. Capture workflow run URL + redacted hex.info excerpt for Wave 3 (`122-VERIFICATION.md`)

**Phase complete only when:** Waves 2 + 3 done — not Wave 1 PR merged alone (D-12, D-14).

### 4.5 Wave 3 maintainer gate checklist

Before merging OK row:

1. Confirm registry shows **0.6.0** (`mix hex.info`)
2. Update adoption-pilot Hex row → **OK** with D-05 evidence cell
3. Trim evaluating-threadline lag caveat
4. Write `122-VERIFICATION.md`
5. Tick DIST-01–03 in `REQUIREMENTS.md`; update `STATE.md` / `ROADMAP.md`
6. `mix verify.doc_contract` + `mix ci.all` green (conditional tests now enforce anti-stale)

### 4.6 Verification commands (cite in PLAN.md)

```bash
# Wave 1
mix test test/threadline/release_distribution_doc_contract_test.exs
mix test test/threadline/adoption_pilot_doc_contract_test.exs
mix test test/threadline/evaluating_threadline_doc_contract_test.exs
mix verify.doc_contract
mix ci.all

# Wave 2 (maintainer)
mix verify.release
git tag -a v0.6.0 -m "Release v0.6.0"
git push origin v0.6.0
mix hex.info threadline

# Wave 3
mix verify.doc_contract
# Manual: adoption-pilot OK row + 122-VERIFICATION.md present
```

### 4.7 Explicit rejections (do not replicate)

| Pattern | Why rejected |
|---------|--------------|
| CI job polling hex.pm on every PR | Flake, lag, false reds (D-04) |
| `assert \| OK \|` when `@version` is 0.6.0 | Inverts three-layer model (D-03) |
| Full `mix hex.info` paste in backlog | Noisy, churn (D-05) |
| CHANGELOG matrix duplication | SSOT is `upgrade-path.md` (D-10) |
| `phx-gen-auth-reference` under `### Added` for 0.6.0 | Mis-timelines v1.26 lane work (D-10) |

---

## PATTERN MAPPING COMPLETE
