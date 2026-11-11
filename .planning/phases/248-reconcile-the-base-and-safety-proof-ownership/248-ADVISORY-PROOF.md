# Phase 248 Advisory Proof

## Source and live issue identity

- Candidate source at executor start: `ad8ac45be26be7b284c1807ca21f4c76ff4b60dc` on `worktree-agent-p248-03-1794364341`.
- The three pre-change lock identities were captured before resolution:

  | Lockfile | SHA-256 before change |
  |---|---|
  | `mix.lock` | `314eed89ed27ff919afdd2436c2805a16b99811eef88b7678e3ba7b02acef3ee` |
  | `bench/mix.lock` | `73ae2b2474cee204454fe11eb23ea4b11b61e95c0abd09a289b094115d5e6927` |
  | `examples/threadline_phoenix/mix.lock` | `66a8373dab6c4adb546a57d4b4cfd99c4d08b4c31d360e0b10060e0a7e7bbd38` |

- A read-only GitHub issue fetch on 2026-11-10 returned [issue #61](https://github.com/szTheory/threadline/issues/61) as **open**, updated `2026-11-10T08:08:11Z`, with 21 comments. Its latest report still names root Ecto 3.14.2 and Phoenix.HTML 4.3.0 as blocking and reports bench/example advisories. This local remediation does not close or update the issue; the next scheduled clean dependency-health receipt remains required.
- Primary records confirm Ecto GHSA-cxjx-vmm2-qr8r is fixed in 3.14.3, Phoenix.HTML CVE-2026-117645 is fixed in 4.4.0, and the Bandit request-body advisory GHSA-pxjf-g536-7r93 is fixed in 1.14.1: [Ecto GHSA](https://github.com/elixir-ecto/ecto/security/advisories/GHSA-cxjx-vmm2-qr8r), [Phoenix.HTML CVE record](https://cna.erlef.org/cves/CVE-2026-117645.html), [Phoenix.HTML 4.4.0 changelog](https://hex.pm/packages/phoenix_html/4.4.0/changelog), [Bandit GHSA-jwh3-j29h-qfmw](https://github.com/mtrudel/bandit/security/advisories/GHSA-jwh3-j29h-qfmw), [Bandit GHSA-pxjf-g536-7r93](https://github.com/mtrudel/bandit/security/advisories/GHSA-pxjf-g536-7r93).

## Task 1 — root lock

### Baseline and constraints

- Before: root `ecto` 3.14.2, `ecto_sql` 3.14.0 and `phoenix_html` 4.3.0. Root declares `ecto_sql ~> 3.10`; Phoenix.HTML is `~> 4.0` and optional. The existing `ecto_sql` lock metadata accepts Ecto `~> 3.14.0`.
- The planned `mix deps.update ecto phoenix_html` resolved the target versions but exited 1 with `Unknown dependency ecto for environment dev`: Ecto is transitive in this project. That interrupted attempt left an incomplete `ecto` build-manager field and was not accepted as a lock result. `mix deps.update ecto_sql phoenix_html` exited 0 but did not repair that transitive lock metadata. Following Mix's documented targeted unlock/get path, `mix deps.unlock ecto && mix deps.get` with `HEX_HOME` set to the supplied temporary Hex home exited 0 and regenerated a valid `ecto` entry (`[:mix]`) and checksums from Hex. No checksum was edited or fabricated. This is a Rule 3 execution adjustment for Mix's direct-dependency requirement.
- Final root lock diff contains exactly two package tuple changes: Ecto 3.14.2 → 3.14.3 and Phoenix.HTML 4.3.0 → 4.4.0. No other root tuple changed; `mix.exs`, support floors, optional/runtime classifications and package version remain unchanged. Final root lock SHA-256: `00e6393a22730830470a8253a3cbbd49ca4adc8fd8768573516f58e592502e00`.

### Compatibility and current checks

- The fetched Ecto 3.14.3 package declares `elixir: "~> 1.14"`; Phoenix.HTML 4.4.0 declares `elixir: "~> 1.7"`. Neither package declares an OTP floor in its Mix project metadata. These declarations are compatible with the repository floor Elixir 1.15.8 / OTP 26.2.5.21.
- Current toolchain is Elixir/Mix 1.17.3 on OTP 27.3.4.15 (`.tool-versions`: Elixir 1.17.3-OTP-27, Erlang 27.3.4.15). `mix compile --warnings-as-errors` in `MIX_ENV=dev` exited **0** and compiled Threadline. Fresh dependency compilation printed two existing Phoenix 1.8.13 warnings in `phoenix/code_reloader/server.ex` at lines 301 and 414; Phoenix was not part of the lock diff. This is current-toolchain evidence only. The minimum Elixir/OTP lane was not run here.
- `mix verify.deps_audit` after the root change exited **0** with Hex 2.6.0. Root reported no findings. The command still reported all **15** non-blocking findings from the unchanged bench/example locks below; therefore this interim audit is not the final all-lock acceptance.

Raw audit output for the interim root-updated graph:

```text
Found packages with security advisories
deps-audit-finding tier=non-blocking dir=bench kind=advisory package=ecto id=EEF-CVE-2026-118391
::warning::ecto is only in bench/mix.lock; not shipped in the Hex package: advisory ecto EEF-CVE-2026-118391
Found packages with security advisories
deps-audit-finding tier=non-blocking dir=examples/threadline_phoenix kind=advisory package=bandit id=EEF-CVE-2026-111101
::warning::bandit is only in examples/threadline_phoenix/mix.lock; not shipped in the Hex package: advisory bandit EEF-CVE-2026-111101
deps-audit-finding tier=non-blocking dir=examples/threadline_phoenix kind=advisory package=bandit id=EEF-CVE-2026-114216
::warning::bandit is only in examples/threadline_phoenix/mix.lock; not shipped in the Hex package: advisory bandit EEF-CVE-2026-114216
deps-audit-finding tier=non-blocking dir=examples/threadline_phoenix kind=advisory package=bandit id=EEF-CVE-2026-114213
::warning::bandit is only in examples/threadline_phoenix/mix.lock; not shipped in the Hex package: advisory bandit EEF-CVE-2026-114213
deps-audit-finding tier=non-blocking dir=examples/threadline_phoenix kind=advisory package=bandit id=EEF-CVE-2026-113436
::warning::bandit is only in examples/threadline_phoenix/mix.lock; not shipped in the Hex package: advisory bandit EEF-CVE-2026-113436
deps-audit-finding tier=non-blocking dir=examples/threadline_phoenix kind=advisory package=bandit id=EEF-CVE-2026-110499
::warning::bandit is only in examples/threadline_phoenix/mix.lock; not shipped in the Hex package: advisory bandit EEF-CVE-2026-110499
deps-audit-finding tier=non-blocking dir=examples/threadline_phoenix kind=advisory package=bandit id=EEF-CVE-2026-111103
::warning::bandit is only in examples/threadline_phoenix/mix.lock; not shipped in the Hex package: advisory bandit EEF-CVE-2026-111103
deps-audit-finding tier=non-blocking dir=examples/threadline_phoenix kind=advisory package=bandit id=EEF-CVE-2026-115269
::warning::bandit is only in examples/threadline_phoenix/mix.lock; not shipped in the Hex package: advisory bandit EEF-CVE-2026-115269
deps-audit-finding tier=non-blocking dir=examples/threadline_phoenix kind=advisory package=bandit id=EEF-CVE-2026-108525
::warning::bandit is only in examples/threadline_phoenix/mix.lock; not shipped in the Hex package: advisory bandit EEF-CVE-2026-108525
deps-audit-finding tier=non-blocking dir=examples/threadline_phoenix kind=advisory package=bandit id=EEF-CVE-2026-116078
::warning::bandit is only in examples/threadline_phoenix/mix.lock; not shipped in the Hex package: advisory bandit EEF-CVE-2026-116078
deps-audit-finding tier=non-blocking dir=examples/threadline_phoenix kind=advisory package=bandit id=EEF-CVE-2026-109584
::warning::bandit is only in examples/threadline_phoenix/mix.lock; not shipped in the Hex package: advisory bandit EEF-CVE-2026-109584
deps-audit-finding tier=non-blocking dir=examples/threadline_phoenix kind=advisory package=bandit id=EEF-CVE-2026-108529
::warning::bandit is only in examples/threadline_phoenix/mix.lock; not shipped in the Hex package: advisory bandit EEF-CVE-2026-108529
deps-audit-finding tier=non-blocking dir=examples/threadline_phoenix kind=advisory package=bandit id=EEF-CVE-2026-110314
::warning::bandit is only in examples/threadline_phoenix/mix.lock; not shipped in the Hex package: advisory bandit EEF-CVE-2026-110314
deps-audit-finding tier=non-blocking dir=examples/threadline_phoenix kind=advisory package=ecto id=EEF-CVE-2026-118391
::warning::ecto is only in examples/threadline_phoenix/mix.lock; not shipped in the Hex package: advisory ecto EEF-CVE-2026-118391
deps-audit-finding tier=non-blocking dir=examples/threadline_phoenix kind=advisory package=phoenix_html id=EEF-CVE-2026-117645
::warning::phoenix_html is only in examples/threadline_phoenix/mix.lock; not shipped in the Hex package: advisory phoenix_html EEF-CVE-2026-117645
verify-deps-audit: 3 lockfile(s) audit clean (Hex 2.6.0; 15 non-blocking finding(s))
```

These bench/example findings were owned by Task 2 and kept pending here. The bench Ecto finding is non-blocking for the library package; the example findings block this phase's example-host acceptance until cleared. The audit exit code alone does not clear these reports.

