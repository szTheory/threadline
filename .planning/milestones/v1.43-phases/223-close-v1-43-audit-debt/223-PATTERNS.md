# Phase 223: Close v1.43 Audit Debt - Pattern Map

**Mapped:** 2026-09-29
**Files analyzed:** 7 (modified — no new files; this phase is pure extension/hardening of existing files)
**Analogs found:** 7 / 7 (every file being modified is itself its own best analog: this
phase extends existing conventions in place rather than introducing new files or new
architectural shapes)

## File Classification

| Modified File | Role | Data Flow | Closest Analog (in-file or sibling) | Match Quality |
|----------------|------|-----------|--------------------------------------|---------------|
| `.github/workflows/release.yml` (3 checkout steps: lines 63, 481, 646) | config (CI workflow) | request-response (CI job step) | same file, lines 144-149 & 161-164 & 468-473 (already-compliant `persist-credentials: false` checkouts) | exact |
| `test/threadline/release_control_plane_contract_test.exs` (extend ~143-181 block) | test (contract) | transform (text/regex over YAML) | same file's own `bootstrap_guard_errors/1` (236-255) and the `sync-release-pr-pins` per-checkout counting block (143-161) | exact |
| `test/threadline/ci_token_permissions_contract_test.exs` (read-only pattern source, not modified) | test (contract) | transform | n/a — this is the analog, not a target | — |
| `test/threadline/ci_workflow_parity_contract_test.exs` (read-only pattern source, not modified) | test (contract) | transform | n/a — this is the analog, not a target | — |
| `bin/verify-repo-hygiene` (6 sub-fixes: allowlist validation loop ~304-380, matcher family 6 ~280, newline pre-scan, self-test block ~112-236) | utility (bash+Perl guard script) | batch (tree scan) | same file's own existing validation-loop / matcher-family / self-test conventions | exact |
| `test/threadline/repo_hygiene_guard_test.exs` (extend "six cases" assertion ~574-577) | test (unit, shells out to the guard) | transform | same file | exact |
| `test/threadline/repo_hygiene_contract_test.exs` (extend IN-01 assertion ~403, placeholder auto-coverage ~285-397) | test (contract, doc/script parity) | transform | same file | exact |
| `CONTRIBUTING.md` (§"Writing about machine-local paths" 108-144, §"Ongoing releases" 985-988) | config (docs) | transform (prose) | same file, existing placeholder block and release-runbook sections | exact |
| `.planning/phases/217-repo-hygiene/217-REVIEW-DISPOSITION.md` (hand-edit frontmatter + table) | config (planning artifact) | CRUD (status field update) | same file's own already-`fixed` R1-* rows (frontmatter lines ~5-24 above) | exact |

There are no genuinely new files in this phase and no cross-codebase analog search was
needed — CONTEXT.md/RESEARCH.md already pin every target file and exact line anchor, and in
every case the best pattern to copy is the *sibling instance already in the same file*
(e.g. copy the already-compliant checkout block's shape onto the two/three checkouts that
lack it; copy an existing self-test case's fixture-concatenation convention for a new case).

## Pattern Assignments

### `.github/workflows/release.yml` — checkouts at lines 63, 481, 646 (config, request-response)

**Analog:** same file, lines 157-164 (the `sync-release-pr-pins` job's already-compliant
target-ref checkout, immediately preceded by its own explanatory comment)

**Comment + flag pattern to copy** (lines 157-164, verbatim):
```yaml
      # persist-credentials: false keeps the token out of .git/config. The steps
      # below fetch and COMPILE every dependency (`mix release.pins` is a Mix task),
      # and any dependency's compile-time code could otherwise read a persisted
      # credential. The token is supplied to the push step alone.
      - uses: actions/checkout@v5
        with:
          ref: release-please--branches--main
          persist-credentials: false
```

**Apply this shape, with a comment citing "216 CR-01" (per D-12), to:**
- Line 63 (`release-please` job, no `ref:`, no `mix`) — add just the flag plus a short
  comment; D-07/Pitfall 2 requires it even though this job runs no `mix`:
  ```yaml
      # persist-credentials: false — 216 CR-01: this checkout needs no git auth
      # (release-please-action supplies its own token), so the token must not
      # be left in .git/config for anything else in this job to read.
      - uses: actions/checkout@v5
        with:
          fetch-depth: 0
          persist-credentials: false
  ```
- Line 481 (`publish-hex`, `ref: needs.release-ref.outputs.checkout_ref`, runs `mix
  deps.get`/`mix hex.build`/`mix hex.info`/`mix hex.publish`):
  ```yaml
      # persist-credentials: false — 216 CR-01: the steps below COMPILE every
      # dependency and build/publish the Hex package; a persisted token would be
      # readable by that compile-time code.
      - uses: actions/checkout@v5
        with:
          ref: ${{ needs.release-ref.outputs.checkout_ref }}
          persist-credentials: false
  ```
- Line 646 (`smoke-published`, same `ref:`, runs `mix verify.hex_evaluator`): identical
  shape to the 481 fix, same comment style.

**Non-target for comparison (already-compliant sparse-checkout style, lines 144-149 / 468-473 / 633-638):**
```yaml
      - name: Read the toolchain pin from this workflow's commit
        uses: actions/checkout@v5
        with:
          path: .toolchain-pin
          sparse-checkout: .tool-versions
          sparse-checkout-cone-mode: false
          persist-credentials: false
```
These three are already correct — do not touch them; they establish the flag's placement
convention (always the last key under `with:`).

**Do NOT add the flag to** (D-07's exactly-two-entry allowlist):
- `dispatch-bootstrap` job's checkout (line ~247, `token: secrets.RELEASE_PLEASE_TOKEN ||
  secrets.GITHUB_TOKEN`, bare `git push origin "$tag"`)
- `distribution-sync` job's checkout (line 681, `ref: main`, bare `git push -u origin
  "$BRANCH"`)

---

### `test/threadline/release_control_plane_contract_test.exs` (test, transform)

**Analog:** the file's own `bootstrap_guard_errors/1` (lines 236-255) for error shape, and
its own per-checkout counting block (lines 143-161) for the mechanism to generalize.

**Error-tuple shape to copy** (lines 236-255, verbatim — D-09 says implement the three new
rules in exactly this shape, not the `rule=` string style of the sibling file):
```elixir
defp bootstrap_guard_errors(block) do
  [
    {block =~ ~r/^    permissions:\n      actions: write$/m,
     "bootstrap-release-pr-ci must keep `actions: write`, or the no-PAT dispatch " <>
       "fails and the release PR gets no CI at all (ECON-03)."},
    ...
  ]
  |> Enum.reject(fn {ok, _message} -> ok end)
end
```

**Per-checkout counting idiom to generalize repo-wide** (lines 143-161, verbatim):
```elixir
checkout_count = fn job -> length(Regex.scan(~r/uses: actions\/checkout@/, job)) end
credential_free = fn job -> length(Regex.scan(~r/^\s+persist-credentials: false$/m, job)) end

assert checkout_count.(sync) == credential_free.(sync),
       "every checkout in sync-release-pr-pins must set persist-credentials: false. ..."

mutated =
  String.replace(
    sync,
    "ref: release-please--branches--main\n          persist-credentials: false\n",
    "ref: release-please--branches--main\n"
  )

refute mutated == sync, "the credential-free checkout control did not change the input"
refute checkout_count.(mutated) == credential_free.(mutated),
       "dropping the flag from the release-branch checkout must make the counts diverge"
```
D-10 directs extending this exact block: keep the `sync-release-pr-pins`-specific asserts,
then add a repo-wide (all `release.yml` jobs) allowlist-aware version using the two helper
functions from `job_block!/2` (below) and the allowlist idiom (next section).

**`job_block!/2` isolation helper to reuse** (lines 261-271, verbatim):
```elixir
defp job_block!(yaml, id) do
  case String.split(yaml, "\n  #{id}:\n", parts: 2) do
    [_, tail] ->
      tail
      |> String.split(~r/\n  [A-Za-z0-9_-]+:\n/, parts: 2)
      |> hd()

    _ ->
      flunk("could not find a \"  #{id}:\" job in .github/workflows/release.yml")
  end
end
```

---

### `test/threadline/ci_token_permissions_contract_test.exs` — Shared Pattern Source Only

**Not modified.** Read-only source for two idioms D-09/D-11 direct the planner to borrow:

**Allowlist + stale-entry idiom** (lines 358-372, verbatim):
```elixir
defp stale_errors(_docs, [_ | _]), do: []

defp stale_errors(docs, []) do
  present = for {path, _text, doc} <- docs, {job_id, _} <- parsed_jobs(doc), do: {path, job_id}

  for {name, allowlist} <- [
        {"@job_write_grants", @job_write_grants},
        ...
      ],
      {path, jobs} <- allowlist,
      {job_id, _} <- jobs,
      {path, job_id} not in present do
    "#{path} job=#{job_id} rule=job-write-allowlisted: stale #{name} entry, no such job"
  end
end
```
For D-07's `dispatch-bootstrap`/`distribution-sync` allowlist, model it as a `%{job_id =>
reason}` map (D-07's own wording: "a reasoned allowlist `@persisted_checkout_jobs` — a
`%{job => reason}` map"), then reuse this "present jobs vs allowlist keys" stale-check shape.

**Mutation-control data-driven `for` block idiom** (lines 378-450, verbatim excerpt):
```elixir
defp mutate!(texts, path, from, to) do
  original = Map.fetch!(texts, path)
  assert String.contains?(original, from),
         "control anchor not found in #{path}: #{inspect(from)}"
  Map.put(texts, path, String.replace(original, from, to, global: false))
end

for {label, path, from, to, rule} <- [
      {"missing top-level block", @release, @release_top, "# No workflow-level",
       "permissions-declared"},
      ...
    ] do
  test "#{label} fires rule=#{rule}", %{texts: texts} do
    mutated = mutate!(texts, unquote(path), unquote(from), unquote(to))
    refute mutated == texts, "the control did not change the input"
    errors = token_errors(mutated)
    assert rule_fired?(errors, unquote(rule)),
           "expected rule=#{unquote(rule)} to fire, got #{inspect(errors)}"
  end
end
```
D-11's six B-workstream mutation cases (strip flag from publish-hex, strip from
smoke-published, strip from sync ref:, add `mix deps.get` to distribution-sync, rename an
allowlisted job, positive control on an allowlisted job) map directly onto this
`{label, path, from, to, rule}` tuple-list shape.

---

### `test/threadline/ci_workflow_parity_contract_test.exs` — Shared Pattern Source Only

**Not modified.** Read-only source for step-splitting/value-extraction helpers D-10 directs
borrowing for the step-level (not job-level) split:

**`job_steps/1`** (lines 3153-3158, verbatim):
```elixir
defp job_steps(block) do
  case Regex.split(~r/^(?=      - )/m, block) do
    [_header | steps] -> steps
    [] -> []
  end
end
```

**`yaml_value/2`** (lines 3691-3696, verbatim):
```elixir
defp yaml_value(step, key) do
  case Regex.run(~r/^\s*#{Regex.escape(key)}:[ \t]*(.*?)[ \t]*$/m, step) do
    [_, value] -> value
    nil -> nil
  end
end
```
Use `job_steps/1` to split a `job_block!/2` result into individual `- uses: ...` /
`- name: ...` step chunks, then check each `actions/checkout` step chunk for the
`persist-credentials` value with `yaml_value/2` — this gives the required *per-step* (not
per-job) counting D-08 mandates, closing the exact vacuous-pass gap that let CR-01 escape.

---

### `bin/verify-repo-hygiene` (utility, batch tree-scan)

**Analog:** the script's own existing conventions — self-test fixture-concatenation
(lines 121-129), matcher family list (lines 271-282), allowlist structural-validation loop
(lines 304-380), self-test summary line (line 234).

**D-13 (`literal_too_broad`) — insert into the structural validation loop** (lines 341-352
is the existing `problem=""` chain to extend, verbatim current shape):
```bash
  problem=""
  if [ -z "$scope" ]; then
    problem="empty scope"
  elif [ "${scope:0:1}" = "/" ]; then
    problem="scope has a leading /"
  elif case "$scope" in *['*?[]']*) true ;; *) false ;; esac; then
    problem="scope contains a glob character"
  elif [ -z "$literal" ]; then
    problem="empty literal"
  elif [ "${#reason}" -lt 20 ]; then
    problem="reason is shorter than 20 characters"
  fi
```
Add an `elif` branch here (before the duplicate-entry check that follows at lines 354-362)
that tests `literal` against the family-root list from `217-REVIEW.md:71-79`'s own proposed
fix (translate its Elixir illustration into bash string comparisons using
`_word_users`/`_word_home` — already built by concatenation at lines 265-266 — so the new
code never contains a literal matchable by its own scan):
```
roots = ["/Users/", "/home/", "-Users-", "\\/Users\\/", "\\/home\\/", "/var/folders/", "/private/var/folders/"]
# a literal that is itself a prefix of (or equal to) any root is "too broad"
```

**D-14 (family-6 left-anchor) — matcher family list, line 280 (current, no boundary):**
```perl
qr{(-\Q$users\E-[A-Za-z0-9._]+)},
```
Analog for the fix is the *other six families in the same array* (lines 275-281), all of
which already use a `(?<![A-Za-z0-9._-])` lookbehind — and `217-REVIEW.md:101`'s own
proposed three-branch replacement (RESEARCH.md's Open Question #1 recommends defaulting to
this three-branch form):
```perl
qr{(?:(?<![A-Za-z0-9._-])|(?<=[A-Za-z]-)|(?<=[A-Za-z]--))(-\Q$users\E-[A-Za-z0-9._]+)},
```

**D-15 (newline pre-scan) — insert before the tree scan begins** (the tree scan itself
starts at line 384 `coarse_pattern=...`; insert a `git ls-files -z` check immediately
before it, in the same `die`-on-exit-2 style already used at lines 99-102 and 242-246):
```bash
die() {
  printf 'verify-repo-hygiene: %s\n' "$*" >&2
  exit 2
}
```
Reuse this existing `die` helper verbatim for the new check's exit-2 path.

**D-16 (Linux-encoded family) — same matcher array, insert alongside line 280** (analog is
line 280 itself, the family-6 entry, now left-anchored per D-14):
```perl
qr{(?<![A-Za-z0-9._-])(-\Q$home\E-[A-Za-z0-9._]+)},
```

**D-17 (self-test fixture pattern to copy for any new case)** — lines 121-129, verbatim
convention every new fixture must follow:
```bash
    # Every fixture literal is built by concatenation, exactly like the
    # matcher above, so this script's own text stays clean of the words it
    # detects.
    st_word_users="Us""ers"
    st_word_home="ho""me"
    st_fake_macos="/${st_word_users}/self-test-user"
    st_fake_linux="/${st_word_home}/self-test-user"
    st_fake_tilde="~""/""self-test-cache"
```
And the existing case-f pattern (lines 220-233) is the closest full-case analog for any new
self-test case (build fixture → write file → git add → run script with
`REPO_HYGIENE_ROOT`/`REPO_HYGIENE_ALLOWLIST` env seams → assert exit code → assert `HIT`
substring in output):
```bash
    make_repo "$case_f"
    st_fake_claude_single="-${st_word_users}-self-test"
    printf 'x /foo/%s/bar\n' "$st_fake_claude_single" >"$case_f/family6.md"
    (cd "$case_f" && git add -- family6.md)
    allow_f="$self_test_dir/allow_f.tsv"
    header_allowlist "$allow_f"

    set +e
    out_f="$(REPO_HYGIENE_ROOT="$case_f" REPO_HYGIENE_ALLOWLIST="$allow_f" "$0" 2>&1)"
    status_f=$?
    set -e
    [ "$status_f" -eq 1 ] || die "self-test (f): single-segment family-6 fixture did not exit 1: $out_f"
    printf '%s' "$out_f" | grep -q 'HIT family6.md' || die "self-test (f): missing family6 HIT: $out_f"
```

**D-19 (self-test count) — line 234, verbatim current text to bump:**
```bash
    printf 'verify-repo-hygiene self-test: ok (6 cases)\n'
```
Change `6` to the final case count (self-test currently has cases through `(f)`; D-13/D-14/
D-15/D-16 each add at least one new case, per CONTEXT's own naming — `(g)`, `(g')`, `(h)`,
`(i)`).

**Line 537 — the exact IN-01 hint line D-17 (of the CONTEXT decisions, distinct from the
D-17 self-test numbering above) directs asserting against, verbatim:**
```bash
    printf '%s\n' 'verify-repo-hygiene: describing a path shape in prose? write the user segment as a placeholder, see CONTRIBUTING.md "Writing about machine-local paths"' >&2
```

---

### `test/threadline/repo_hygiene_guard_test.exs` (test, transform)

**Analog:** the file's own existing "six cases" assertion (grep-verified at lines 574-577
per RESEARCH.md). Bump the literal count and the test name to match D-19's new total,
mirroring the exact same numeric-literal-plus-name-string pattern already in the file (no
structural change — same assertion shape, new integer).

---

### `test/threadline/repo_hygiene_contract_test.exs` (test, transform)

**Analog:** its own `placeholder_forms/1` parser (lines ~285-300) and "concretized
placeholder forms are HITs" mutation-control test (lines ~359-397), which auto-picks up any
new CONTRIBUTING.md bullet containing `<user>` — **no test-file edit needed for D-16's
placeholder**, only the CONTRIBUTING bullet itself (see below).

**D-17 (IN-01 hint assertion, ~line 403)** — tighten to assert the *exact* printf line
(quoted above from `bin/verify-repo-hygiene:537`) is present verbatim in the script text,
plus a mutation control that deletes that line and asserts the assertion then fails —
mirroring the `mutate!`/`refute mutated == texts` idiom shown above from
`ci_token_permissions_contract_test.exs`.

---

### `CONTRIBUTING.md` (docs)

**Analog:** the file's own existing placeholder block (verbatim, lines 122-134, inside the
`<!-- repo-hygiene-placeholders:start -->` / `:end` markers that `repo_hygiene_contract_test.exs`
parses):
```markdown
<!-- repo-hygiene-placeholders:start -->
- `<home>/<path>`: any home directory, when the platform does not matter
- `/Users/<user>/<path>`: a macOS home directory
- `/home/<user>/<path>`: a Linux home directory
- `C:\Users\<user>\<path>`: a Windows home directory
- `~/<path>`: a home-relative path
- `/var/folders/<xx>/<path>`: the macOS per-user temp root
- `-Users-<user>-<project>`: a Claude-encoded project directory name
- `<claude-projects-dir>/<encoded-project>/`: the Claude projects directory
- `\/Users\/<user>\/<path>`: a JSON-escaped home directory
<!-- repo-hygiene-placeholders:end -->
```
D-16 adds one new bullet inside this block, in the same `` `-shape`: description `` form:
```markdown
- `-home-<user>-<project>`: a Linux-encoded Claude-project directory name
```

**D-18 — exact current line 141 text to edit (verbatim):**
```markdown
The allowlist (`.github/repo-hygiene-allowlist.tsv`) is only for runner, cache
and tool-install paths that carry no username. It is never for prose, and no
file or directory is exempt from the scan.
```
Change the final clause to: "and no file or directory is exempt from the scan other than
the allowlist's own literal column."

**D-06 — new sentence's home** (the "Ongoing releases (0.6.1+)" section, verbatim lines
985-988):
```markdown
### Ongoing releases (0.6.1+)

1. Merge conventional commits to **`main`** — Release Please opens/updates a Release PR
   (`release-please-config.json`, manifest `.release-please-manifest.json`). ...
2. Merge the Release PR when CI is green — Release Please tags, then the same publish +
   distribution sync chain runs.
```

---

### `.planning/phases/217-repo-hygiene/217-REVIEW-DISPOSITION.md` (planning artifact, CRUD)

**Analog:** the file's own already-`fixed` R1-* frontmatter rows (verbatim excerpt,
lines ~5-24), which is the exact shape every R2-* row must be hand-edited to match:
```yaml
  - id: R1-CR-01
    severity: critical
    disposition: fixed
    title: "Family-6 \"Claude-encoded project dir\" regex misses a real, plausible path shape (false negative)"
```
Current R2-* rows to flip (verbatim, currently `disposition: open`):
```yaml
  - id: R2-WR-01
    severity: warning
    disposition: open
    title: "`forbidden_home_literal?/1` passes ancestor-prefix literals that blanket-cover every home directory"
  - id: R2-WR-02
    severity: warning
    disposition: open
    title: "Widened family-6 regex has no left boundary and flags ordinary TitleCase kebab words"
  - id: R2-WR-03
    severity: warning
    disposition: open
    title: "A newline in a tracked filename still mis-scopes the hit, and a phantom scope can cover it"
  - id: R2-WR-04
    severity: warning
    disposition: open
```
Per D-20: set each to `disposition: fixed`, set the file's own `open: 0` / `total: 11`
summary fields and `recorded:` timestamp, and update each table row's Source cell to
`223-NN Task N <sha>`. Do this by hand-edit (Edit tool) — never run the automated
gsd-core code-review-disposition step (Pitfall 3 / precedent commit `f169cb91`).

## Shared Patterns

### Mutation-control idiom (applies to every test file touched: B and C workstreams)
**Source:** `test/threadline/ci_token_permissions_contract_test.exs:378-450`
**Apply to:** `release_control_plane_contract_test.exs` (D-11's 6 cases),
`repo_hygiene_contract_test.exs` (D-17's control), `repo_hygiene_guard_test.exs`
(D-19's count bump has no mutation control of its own — it is a direct assertion update)
```elixir
defp mutate!(texts, path, from, to) do
  original = Map.fetch!(texts, path)
  assert String.contains?(original, from), "control anchor not found in #{path}: #{inspect(from)}"
  Map.put(texts, path, String.replace(original, from, to, global: false))
end
# then: refute mutated == texts; assert the named rule/behavior fired on `mutated`
```

### Allowlist-with-stale-entry idiom (applies to D-07..D-09's `@persisted_checkout_jobs`)
**Source:** `test/threadline/ci_token_permissions_contract_test.exs:354-372`
**Apply to:** the new checkout-credential-free rule set in
`release_control_plane_contract_test.exs`
```elixir
defp stale_errors(docs, []) do
  present = for {path, _text, doc} <- docs, {job_id, _} <- parsed_jobs(doc), do: {path, job_id}
  for {name, allowlist} <- [...], {path, jobs} <- allowlist, {job_id, _} <- jobs,
      {path, job_id} not in present do
    "#{path} job=#{job_id} rule=...-allowlisted: stale ... entry, no such job"
  end
end
```

### `die`-on-exit-2 idiom (applies to every new `bin/verify-repo-hygiene` config-error path: D-13, D-15)
**Source:** `bin/verify-repo-hygiene:99-102`
```bash
die() {
  printf 'verify-repo-hygiene: %s\n' "$*" >&2
  exit 2
}
```

### Fixture-by-concatenation idiom (applies to every new self-test case: D-13, D-14, D-15, D-16)
**Source:** `bin/verify-repo-hygiene:122-129`
```bash
st_word_users="Us""ers"
st_word_home="ho""me"
```
Never write `/Users/<user>/<path>` or `-home-<user>-<project>` etc. as a plain literal string in the script — it
would make the guard flag its own source file (Pitfall 1).

## No Analog Found

None. Every file in this phase's scope is a targeted extension of an existing, already-
established convention in the same file (or, for the test-helper borrows, an adjacent
sibling test file explicitly named by CONTEXT.md/RESEARCH.md). There is no new
architectural shape, new role, or new data-flow pattern introduced by this phase.

## Metadata

**Analog search scope:** `.github/workflows/release.yml`, `test/threadline/*_contract_test.exs`,
`test/threadline/repo_hygiene_guard_test.exs`, `bin/verify-repo-hygiene`, `CONTRIBUTING.md`,
`.planning/phases/217-repo-hygiene/217-REVIEW-DISPOSITION.md`
**Files scanned:** 7 target files + 2 shared-pattern-source sibling test files (read in full
or by targeted offset/limit this session)
**Pattern extraction date:** 2026-09-29
**Note:** All line-number anchors were independently re-verified by direct `Read`/`grep`
this session (not solely inherited from RESEARCH.md's own verification pass); no drift found.
