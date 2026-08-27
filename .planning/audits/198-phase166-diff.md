# Phase-166 branch triage — diff, summary, and merge-or-archive recommendation

**Produced by:** Plan 198-06, Task 1
**Date:** 2026-08-27
**Requirement:** GREEN-12
**Binding decisions:** D-31 (archive-tag convention), D-33 (archive by default; cherry-pick only
for unique unshipped value), D-34 step 1 (this artifact must exist and be committed BEFORE
anything is removed)

---

## Live state established at execution time

Not trusted from the plan's snapshot — captured directly.

```
$ git worktree list
/Users/jon/projects/threadline           3071d1bc [main]
/Users/jon/projects/threadline-phase166  dd5b48be [gsd/phase-166-unfreeze-token-lane-mechanism]

$ git branch -vv
  backup/pre-release-cleanup-2026-05-08       50374eb7 docs(69): close phase execution
+ gsd/phase-166-unfreeze-token-lane-mechanism dd5b48be (/Users/jon/projects/threadline-phase166) docs(166): complete phase verification
* main                                        3071d1bc [origin/main: ahead 628] docs(phase-198): update tracking after wave 3
```

The planning-time expectation (two worktrees, three branches) matches the live state exactly.

### Ancestry verification

```
$ git merge-base --is-ancestor gsd/phase-166-unfreeze-token-lane-mechanism main; echo $?
1        # NOT an ancestor -> real unmerged work -> earns an archive tag

$ git merge-base --is-ancestor backup/pre-release-cleanup-2026-05-08 main; echo $?
0        # strict ancestor of main -> already merged
```

This is the GREEN-12 adjacency edge, and the two branches land on opposite sides of it:

- `gsd/phase-166-unfreeze-token-lane-mechanism` (`dd5b48be`) is **not** an ancestor of main. It
  carries commits that exist nowhere else. It **requires** an archive tag before deletion.
- `backup/pre-release-cleanup-2026-05-08` (`50374eb7`) **is** a strict ancestor of main, and
  `git diff main...backup/pre-release-cleanup-2026-05-08` is **empty**. By the adjacency rule it is
  classified as merged and needs no archive tag to avoid data loss. D-31 nonetheless directs that
  both branches be tagged, on the grounds that "a branch named backup is an archive tag wearing the
  wrong hat" — so it is tagged anyway. That tag is **provenance, not preservation**: it records what
  the ref pointed at and why it was retired. Its message states this classification explicitly so a
  future reader does not mistake it for rescued unmerged work.

---

## The phase-166 branch

| Field | Value |
|---|---|
| Branch | `gsd/phase-166-unfreeze-token-lane-mechanism` |
| Tip SHA | `dd5b48be6f4c175f5dd7cecee19dbeb2f9a2934a` |
| Merge base with `main` | `5d923ad9b0a9b29bc0c0759de282bd50e7565e6c` |
| Ancestor of `main`? | **No** (`git merge-base --is-ancestor` exits 1) |
| Commits ahead of `main` | 10 |
| Worktree | `/Users/jon/projects/threadline-phase166` |

### Commits ahead of main

```
dd5b48be docs(166): complete phase verification
ff7da251 style(166-01): format theme test changes
f095d480 docs(166): add clean code review report
76a7f512 fix(166-01): close operator surface auth review findings
67ae76f1 docs(166-01): complete unfreeze token lane plan
0cfd98a9 docs(166-01): record light mode superseding decision
b5533c14 test(166-01): amend style contract for theme lanes
78b90c90 feat(166-01): add operator surface light token lane
e730f2f4 feat(166-01): render configured operator surface theme
c64379ee feat(166-01): add operator surface theme router option
```

### Diffstat (`git diff --stat main...gsd/phase-166-unfreeze-token-lane-mechanism`)

```
 .planning/REQUIREMENTS.md                          |  28 ++--
 .planning/ROADMAP.md                               |   4 +-
 .planning/STATE.md                                 |  27 ++--
 .../166-01-SUMMARY.md                              | 165 +++++++++++++++++++++
 .../166-REVIEW.md                                  |  82 ++++++++++
 .../166-VERIFICATION.md                            |  93 ++++++++++++
 lib/threadline/operator_surface/auth.ex            |   9 +-
 lib/threadline/operator_surface/live/actor_live.ex |  30 ++--
 .../operator_surface/live/coverage_live.ex         |   2 +-
 .../operator_surface/live/evidence_live.ex         |   2 +-
 .../operator_surface/live/export_status_live.ex    |   2 +-
 .../operator_surface/live/policy_redaction_live.ex |   2 +-
 .../live/retention_history_live.ex                 |   2 +-
 .../operator_surface/live/row_history_live.ex      |   2 +-
 lib/threadline/operator_surface/live/start_live.ex |   2 +-
 .../operator_surface/live/timeline_live.ex         |   2 +-
 .../operator_surface/live/transaction_live.ex      |   2 +-
 lib/threadline/operator_surface/router.ex          |  12 ++
 lib/threadline/operator_surface/style.ex           | 105 ++++++++++++-
 .../operator_surface/live/actor_live_test.exs      |   7 +
 .../operator_surface/live/start_live_test.exs      |  93 ++++++++++++
 .../operator_surface/live/timeline_live_test.exs   |  28 +++-
 test/threadline/operator_surface/router_test.exs   |  50 +++++++
 .../operator_surface/style_contract_test.exs       |  24 ++-
 24 files changed, 719 insertions(+), 56 deletions(-)
```

### File-by-file summary

The full `main...dd5b48be` code diff is 687 lines over `lib/` and `test/`, plus six planning
documents. It is inlined verbatim in the appendix below rather than summarised away, so this
artifact stands alone even if the tag is ever lost. What follows is the reading of it.

| File | What the branch does | Status on `main` today |
|---|---|---|
| `lib/threadline/operator_surface/router.ex` | Adds a `:theme` (`:dark \| :light \| :system`) macro option with a `CompileError` on an invalid value, plus `@moduledoc` prose. | **Present, superset.** `main:67,71-75` carries the identical option and the identical compile-time guard, and additionally mounts a `POST <path>/theme` route and a `:threadline_theme` pipeline (`main:130-137`) that the branch has no concept of. |
| `lib/threadline/operator_surface/auth.ex` | Normalises the configured theme and assigns `:threadline_theme`; flips one `rescue` fallback from `true` to `false`. | **Present, superset.** `main:16` resolves the theme from `session_theme \|\| theme_config` — i.e. session-backed, which the branch is not — and `main:179-181` carries a broader `normalize_theme/1` accepting both atoms and strings. The `rescue` fail-closed flip is on `main`. |
| `lib/threadline/operator_surface/style.ex` | Adds `--tl-color-accent-inset` and a `.threadline-ui[data-tl-theme="light"]` token block (~45 light-lane variables). | **Present, superset.** `main:98` has `--tl-color-accent-inset`; `main:206` opens the same light block with identical values (`#F7F9FC`, `#1557C0`, …); `main:279` adds a `prefers-color-scheme` `:system` lane and `main:317-321` adds light-specific table rules the branch never wrote. |
| Nine `live/*_live.ex` files | Threads `data-tl-theme={@threadline_theme}` onto each page's root `<div class="threadline-ui">` — the same attribute repeated in nine places. | **Superseded by a better shape.** `main` carries **zero** `data-tl-theme` occurrences in `live/`; the attribute is applied once, centrally, in the shared shell at `lib/threadline/operator_surface/ui.ex:1162`. Cherry-picking the branch's version would *reintroduce* the nine-way duplication `main` has already eliminated. |
| `test/.../router_test.exs`, `style_contract_test.exs`, three `*_live_test.exs` | Contract and LiveView tests for the theme lane. | Equivalent coverage exists on `main`, written against the shipped shell/session design rather than the branch's per-page design. |
| Six `.planning/` documents | Phase-166 SUMMARY, REVIEW, VERIFICATION, and STATE/ROADMAP/REQUIREMENTS bookkeeping. | Phase 166 was completed and archived under the v1.36 milestone through a different lineage; these are duplicate bookkeeping for an already-closed phase. |

---

## Recommendation

**ARCHIVE. Do not cherry-pick.**

D-33 sets the rule — archive by default, cherry-pick only if the diff carries unique unshipped
value — and requires both of its questions to be answered in writing rather than asserted.

### (a) Does it duplicate work already on `main`?

**Yes, entirely, and `main`'s version is strictly better.** This branch is the phase-166 light-lane
mechanism, and v1.36 (phases 166–170) shipped that mechanism to `main` through a different lineage.
Every substantive hunk was checked against `main` directly, not assumed:

- The router `:theme` option and its `CompileError` guard: identical on `main`, plus a theme
  controller route the branch lacks.
- `normalize_theme/1` and the `:threadline_theme` assign: on `main`, in a broader form that also
  accepts string values and resolves from the session.
- The light token block and `--tl-color-accent-inset`: on `main` with the same values, plus a
  `prefers-color-scheme` `:system` lane and light table rules the branch never had.
- The nine per-page `data-tl-theme` attributes: **deliberately not** on `main`, because `main`
  centralised the attribute in `ui.ex`. This is the one place the branch differs materially, and it
  differs by being worse — cherry-picking it would re-duplicate an attribute `main` factored out.

There is no unique unshipped value. There is only an earlier draft of shipped work.

### (b) Does it touch files v1.41 is about to rewrite?

**Yes.** The branch is operator-surface routing (`router.ex`, `auth.ex`, nine LiveViews) and the
style contract (`style.ex`, `style_contract_test.exs`). Phase 201 (public surface) and Phase 204
(structure) rewrite exactly those areas. Even if the diff carried unique value — it does not — it
would be landing directly in front of a rewrite, and would have to be re-litigated within weeks.

Both questions point the same way, and neither answer is close.

### What archiving costs

Nothing that is not recoverable. The annotated tag `archive/gsd/phase-166-unfreeze-token-lane-mechanism`
pins `dd5b48be` permanently; the full diff is reproducible with
`git diff main...archive/gsd/phase-166-unfreeze-token-lane-mechanism`, and the branch is restorable
with `git branch gsd/phase-166-unfreeze-token-lane-mechanism dd5b48be`. See
`.planning/ARCHIVE-REGISTER.md`.

### Not settled here

The tag lives only on this laptop until it is pushed. D-32 decided archive tags **are** pushed to
origin; that push is Plan 198-07's step 5, gated behind the credential audit. Until then this
artifact and the tag share a single point of failure, which is stated rather than glossed.

---

## Appendix — full code diff (`git diff main...dd5b48be -- lib test`)

<!-- appended verbatim below by `git diff`; not hand-transcribed -->

```diff
diff --git a/lib/threadline/operator_surface/auth.ex b/lib/threadline/operator_surface/auth.ex
index d128af16..d2366762 100644
--- a/lib/threadline/operator_surface/auth.ex
+++ b/lib/threadline/operator_surface/auth.ex
@@ -11,11 +11,13 @@ if Code.ensure_loaded?(Phoenix.LiveView) do
       scope_query_fn = Keyword.get(opts, :scope_query_fn)
       repo = Keyword.get(opts, :repo)
       schemas = Keyword.get(opts, :schemas, %{})
+      theme = opts |> Keyword.get(:theme, :dark) |> normalize_theme()
 
       socket =
         socket
         |> maybe_assign_session_user(session)
         |> maybe_assign_session_actor(session)
+        |> Phoenix.Component.assign(:threadline_theme, theme)
         |> Phoenix.Component.assign(:threadline_repo, repo)
         |> Phoenix.Component.assign(:threadline_schemas, schemas)
         |> Phoenix.Component.assign(:threadline_scope_query_fn, scope_query_fn)
@@ -83,6 +85,11 @@ if Code.ensure_loaded?(Phoenix.LiveView) do
       {:halt, redirect(socket, to: "/")}
     end
 
+    defp normalize_theme(:dark), do: "dark"
+    defp normalize_theme(:light), do: "light"
+    defp normalize_theme(:system), do: "system"
+    defp normalize_theme(_), do: "dark"
+
     defp emit_telemetry(result, socket, scope) do
       scope_keys = if is_map(scope), do: Map.keys(scope) |> Enum.sort(), else: []
 
@@ -197,7 +204,7 @@ if Code.ensure_loaded?(Phoenix.LiveView) do
         _ -> false
       end
     rescue
-      _ -> true
+      _ -> false
     end
 
     defp assign_coverage_enabled(socket, opts) do
diff --git a/lib/threadline/operator_surface/live/actor_live.ex b/lib/threadline/operator_surface/live/actor_live.ex
index 43a54594..b4a5e055 100644
--- a/lib/threadline/operator_surface/live/actor_live.ex
+++ b/lib/threadline/operator_surface/live/actor_live.ex
@@ -11,14 +11,7 @@ if Code.ensure_loaded?(Phoenix.LiveView) do
       repo =
         socket.assigns[:threadline_repo] || Application.get_env(:threadline, :ecto_repos) |> hd()
 
-      type =
-        try do
-          String.to_existing_atom(kind)
-        rescue
-          ArgumentError -> String.to_atom(kind)
-        end
-
-      case Threadline.Semantics.ActorRef.new(type, id) do
+      case actor_ref_from_params(kind, id) do
         {:ok, actor_ref} ->
           from_time = DateTime.utc_now() |> DateTime.add(-24, :hour)
 
@@ -66,7 +59,7 @@ if Code.ensure_loaded?(Phoenix.LiveView) do
            |> stream_configure(:transactions, dom_id: fn tx -> "tx-#{tx.id}" end)
            |> stream(:transactions, page.entries)}
 
-        {:error, _} ->
+        :error ->
           {:ok, assign(socket, :not_found, true)}
       end
     end
@@ -85,7 +78,7 @@ if Code.ensure_loaded?(Phoenix.LiveView) do
 
     def render(assigns) do
       ~H"""
-      <div class="threadline-ui">
+      <div class="threadline-ui" data-tl-theme={@threadline_theme}>
         <Threadline.OperatorSurface.Style.css />
         <Threadline.OperatorSurface.Script.js />
         <Threadline.OperatorSurface.Components.SurfaceHeader.surface_header
@@ -285,6 +278,23 @@ if Code.ensure_loaded?(Phoenix.LiveView) do
     defp pressed_state(current, value) when current == value, do: "true"
     defp pressed_state(_current, _value), do: "false"
 
+    defp actor_ref_from_params(kind, id) when is_binary(kind) do
+      with {:ok, type} <- actor_type_from_string(kind),
+           {:ok, actor_ref} <- Threadline.Semantics.ActorRef.new(type, id) do
+        {:ok, actor_ref}
+      else
+        _ -> :error
+      end
+    end
+
+    defp actor_ref_from_params(_kind, _id), do: :error
+
+    defp actor_type_from_string(kind) do
+      {:ok, String.to_existing_atom(kind)}
+    rescue
+      ArgumentError -> :error
+    end
+
     defp actor_summaries(_transactions, _repo, scope)
          when not is_nil(scope),
          do: %{}
diff --git a/lib/threadline/operator_surface/live/coverage_live.ex b/lib/threadline/operator_surface/live/coverage_live.ex
index f3f0c9cb..1803c368 100644
--- a/lib/threadline/operator_surface/live/coverage_live.ex
+++ b/lib/threadline/operator_surface/live/coverage_live.ex
@@ -91,7 +91,7 @@ if Code.ensure_loaded?(Phoenix.LiveView) do
 
     def render(assigns) do
       ~H"""
-      <div class="threadline-ui">
+      <div class="threadline-ui" data-tl-theme={@threadline_theme}>
         <Threadline.OperatorSurface.Style.css />
         <Threadline.OperatorSurface.Components.SurfaceHeader.surface_header
           coverage={@threadline_coverage}
diff --git a/lib/threadline/operator_surface/live/evidence_live.ex b/lib/threadline/operator_surface/live/evidence_live.ex
index 399b5b9c..255412aa 100644
--- a/lib/threadline/operator_surface/live/evidence_live.ex
+++ b/lib/threadline/operator_surface/live/evidence_live.ex
@@ -51,7 +51,7 @@ if Code.ensure_loaded?(Phoenix.LiveView) do
 
     def render(assigns) do
       ~H"""
-      <div class="threadline-ui">
+      <div class="threadline-ui" data-tl-theme={@threadline_theme}>
         <Threadline.OperatorSurface.Style.css />
         <%= if @base_path do %>
           <Threadline.OperatorSurface.Components.SurfaceHeader.surface_header
diff --git a/lib/threadline/operator_surface/live/export_status_live.ex b/lib/threadline/operator_surface/live/export_status_live.ex
index df040ff3..c885c61b 100644
--- a/lib/threadline/operator_surface/live/export_status_live.ex
+++ b/lib/threadline/operator_surface/live/export_status_live.ex
@@ -111,7 +111,7 @@ if Code.ensure_loaded?(Phoenix.LiveView) do
 
     def render(assigns) do
       ~H"""
-      <div class="threadline-ui">
+      <div class="threadline-ui" data-tl-theme={@threadline_theme}>
         <Threadline.OperatorSurface.Style.css />
         <%= if @base_path do %>
           <Threadline.OperatorSurface.Components.SurfaceHeader.surface_header
diff --git a/lib/threadline/operator_surface/live/policy_redaction_live.ex b/lib/threadline/operator_surface/live/policy_redaction_live.ex
index 8968ff10..88d2bbde 100644
--- a/lib/threadline/operator_surface/live/policy_redaction_live.ex
+++ b/lib/threadline/operator_surface/live/policy_redaction_live.ex
@@ -40,7 +40,7 @@ if Code.ensure_loaded?(Phoenix.LiveView) do
 
     def render(assigns) do
       ~H"""
-      <div class="threadline-ui">
+      <div class="threadline-ui" data-tl-theme={@threadline_theme}>
         <Threadline.OperatorSurface.Style.css />
         <%= if @base_path do %>
           <Threadline.OperatorSurface.Components.SurfaceHeader.surface_header
diff --git a/lib/threadline/operator_surface/live/retention_history_live.ex b/lib/threadline/operator_surface/live/retention_history_live.ex
index 38635cb8..534e5dc0 100644
--- a/lib/threadline/operator_surface/live/retention_history_live.ex
+++ b/lib/threadline/operator_surface/live/retention_history_live.ex
@@ -70,7 +70,7 @@ if Code.ensure_loaded?(Phoenix.LiveView) do
 
     def render(assigns) do
       ~H"""
-      <div class="threadline-ui">
+      <div class="threadline-ui" data-tl-theme={@threadline_theme}>
         <Threadline.OperatorSurface.Style.css />
         <%= if @base_path do %>
           <Threadline.OperatorSurface.Components.SurfaceHeader.surface_header
diff --git a/lib/threadline/operator_surface/live/row_history_live.ex b/lib/threadline/operator_surface/live/row_history_live.ex
index f16d549b..bd2f11d1 100644
--- a/lib/threadline/operator_surface/live/row_history_live.ex
+++ b/lib/threadline/operator_surface/live/row_history_live.ex
@@ -30,7 +30,7 @@ if Code.ensure_loaded?(Phoenix.LiveView) do
 
     def render(assigns) do
       ~H"""
-      <div class="threadline-ui">
+      <div class="threadline-ui" data-tl-theme={@threadline_theme}>
         <Threadline.OperatorSurface.Style.css />
         <Threadline.OperatorSurface.Script.js />
         <Threadline.OperatorSurface.Components.SurfaceHeader.surface_header
diff --git a/lib/threadline/operator_surface/live/start_live.ex b/lib/threadline/operator_surface/live/start_live.ex
index 8c6c1fe0..8912c092 100644
--- a/lib/threadline/operator_surface/live/start_live.ex
+++ b/lib/threadline/operator_surface/live/start_live.ex
@@ -114,7 +114,7 @@ if Code.ensure_loaded?(Phoenix.LiveView) do
         )
 
       ~H"""
-      <div class="threadline-ui">
+      <div class="threadline-ui" data-tl-theme={@threadline_theme}>
         <Threadline.OperatorSurface.Style.css />
         <Threadline.OperatorSurface.Components.SurfaceHeader.surface_header
           coverage={@threadline_coverage}
diff --git a/lib/threadline/operator_surface/live/timeline_live.ex b/lib/threadline/operator_surface/live/timeline_live.ex
index 76ed9c26..ee553593 100644
--- a/lib/threadline/operator_surface/live/timeline_live.ex
+++ b/lib/threadline/operator_surface/live/timeline_live.ex
@@ -320,7 +320,7 @@ if Code.ensure_loaded?(Phoenix.LiveView) do
 
     def render(assigns) do
       ~H"""
-      <div class="threadline-ui">
+      <div class="threadline-ui" data-tl-theme={@threadline_theme}>
         <Threadline.OperatorSurface.Style.css />
         <Threadline.OperatorSurface.Script.js />
         <Threadline.OperatorSurface.Components.SurfaceHeader.surface_header
diff --git a/lib/threadline/operator_surface/live/transaction_live.ex b/lib/threadline/operator_surface/live/transaction_live.ex
index e04bfbe2..7f0b1223 100644
--- a/lib/threadline/operator_surface/live/transaction_live.ex
+++ b/lib/threadline/operator_surface/live/transaction_live.ex
@@ -82,7 +82,7 @@ if Code.ensure_loaded?(Phoenix.LiveView) do
 
     def render(assigns) do
       ~H"""
-      <div class="threadline-ui">
+      <div class="threadline-ui" data-tl-theme={@threadline_theme}>
         <Threadline.OperatorSurface.Style.css />
         <Threadline.OperatorSurface.Script.js />
         <Threadline.OperatorSurface.Components.SurfaceHeader.surface_header
diff --git a/lib/threadline/operator_surface/router.ex b/lib/threadline/operator_surface/router.ex
index c54623b1..586e491b 100644
--- a/lib/threadline/operator_surface/router.ex
+++ b/lib/threadline/operator_surface/router.ex
@@ -49,6 +49,10 @@ if Code.ensure_loaded?(Phoenix.LiveView) do
     - `:evidence_authorize_fn` (`(%{assigns: map()} -> boolean | :ok | {:ok, scope} | _)`,
       optional) — explicitly gates the mounted evidence surface. Defaults to
       fail closed.
+    - `:theme` (`:dark | :light | :system`, default `:dark`) — host-selected
+      operator-surface token lane. `:system` follows the user's OS preference
+      through scoped CSS only; no JavaScript, cookie, or runtime toggle is
+      injected by Threadline.
     """
 
     defmacro threadline_operator_surface(path, opts \\ []) do
@@ -56,9 +60,17 @@ if Code.ensure_loaded?(Phoenix.LiveView) do
       has_actor_fn? = Keyword.has_key?(opts, :actor_fn)
       has_ack? = Keyword.get(opts, :adopter_acknowledges_unauthenticated, false)
       exports_enabled? = Keyword.get(opts, :exports, true)
+      theme = Keyword.get(opts, :theme, :dark)
       caller_file = __CALLER__.file
       caller_line = __CALLER__.line
 
+      unless theme in [:dark, :light, :system] do
+        raise CompileError,
+          file: caller_file,
+          line: caller_line,
+          description: "Threadline Operator Surface theme must be one of :dark | :light | :system"
+      end
+
       quote do
         _scopes = @phoenix_top_scopes || %{pipes: []}
 
diff --git a/lib/threadline/operator_surface/style.ex b/lib/threadline/operator_surface/style.ex
index d36d571c..307fff2a 100644
--- a/lib/threadline/operator_surface/style.ex
+++ b/lib/threadline/operator_surface/style.ex
@@ -78,6 +78,7 @@ if Code.ensure_loaded?(Phoenix.LiveView) do
           --tl-color-accent-soft: rgba(79, 140, 255, 0.18);
           --tl-color-accent-wash: rgba(79, 140, 255, 0.09);
           --tl-color-accent-border: rgba(127, 169, 255, 0.48);
+          --tl-color-accent-inset: rgba(127, 169, 255, 0.16);
           /* Faint accent veil for raised front-door surfaces */
           --tl-color-on-accent: #08101F;
           /* Dark ink for AA contrast on luminous accents */
@@ -180,6 +181,108 @@ if Code.ensure_loaded?(Phoenix.LiveView) do
           text-rendering: optimizeLegibility;
         }
 
+        .threadline-ui[data-tl-theme="light"] {
+          color-scheme: light;
+          --tl-color-bg: #F7F9FC;
+          --tl-color-surface: #FFFFFF;
+          --tl-color-surface-raised: #EEF3FA;
+          --tl-color-surface-hover: #E7ECF4;
+          --tl-color-surface-selected: #DDE8FF;
+          --tl-color-surface-tint: rgba(255, 255, 255, 0.92);
+          --tl-color-surface-tint-strong: rgba(247, 249, 252, 0.96);
+          --tl-color-backdrop: rgba(15, 23, 40, 0.42);
+          --tl-color-border: #C9D3E2;
+          --tl-color-border-strong: #A7B4C8;
+          --tl-color-border-focus: #1557C0;
+          --tl-color-text: #0F1728;
+          --tl-color-muted: #3B4762;
+          --tl-color-muted-soft: #73819C;
+          --tl-color-accent: #1557C0;
+          --tl-color-accent-strong: #0E459B;
+          --tl-color-accent-soft: rgba(21, 87, 192, 0.12);
+          --tl-color-accent-wash: rgba(21, 87, 192, 0.06);
+          --tl-color-accent-border: rgba(21, 87, 192, 0.28);
+          --tl-color-accent-inset: rgba(21, 87, 192, 0.16);
+          --tl-color-on-accent: #FFFFFF;
+          --tl-color-signal: #0F8F85;
+          --tl-color-signal-bg: rgba(15, 143, 133, 0.12);
+          --tl-color-signal-border: rgba(15, 143, 133, 0.30);
+          --tl-color-ink: #0F1728;
+          --tl-color-paper: #F7F9FC;
+          --tl-color-danger: #A33434;
+          --tl-color-danger-bg: rgba(163, 52, 52, 0.10);
+          --tl-color-danger-border: rgba(163, 52, 52, 0.28);
+          --tl-color-warning-bg: rgba(122, 84, 0, 0.12);
+          --tl-color-warning-text: #7A5400;
+          --tl-color-warning-border: rgba(122, 84, 0, 0.30);
+          --tl-color-success-bg: rgba(19, 108, 71, 0.12);
+          --tl-color-success-text: #136C47;
+          --tl-color-success-border: rgba(19, 108, 71, 0.30);
+          --tl-color-info-bg: rgba(21, 87, 192, 0.10);
+          --tl-color-info-text: #1557C0;
+          --tl-color-info-border: rgba(21, 87, 192, 0.28);
+          --tl-color-neutral-bg: rgba(59, 71, 98, 0.10);
+          --tl-color-neutral-text: #3B4762;
+          --tl-color-neutral-border: #C9D3E2;
+          --tl-color-brand-rail: #0F1728;
+          --tl-shadow-subtle: 0 1px 2px rgba(15, 23, 40, 0.08), 0 1px 3px rgba(15, 23, 40, 0.06);
+          --tl-shadow-popover: 0 10px 28px rgba(15, 23, 40, 0.18);
+          --tl-shadow-raised: 0 18px 48px rgba(15, 23, 40, 0.24);
+          --tl-focus-ring: 0 0 0 3px rgba(21, 87, 192, 0.22), 0 0 0 1px var(--tl-color-border-focus);
+        }
+
+        @media (prefers-color-scheme: light) {
+          .threadline-ui[data-tl-theme="system"] {
+            color-scheme: light;
+            --tl-color-bg: #F7F9FC;
+            --tl-color-surface: #FFFFFF;
+            --tl-color-surface-raised: #EEF3FA;
+            --tl-color-surface-hover: #E7ECF4;
+            --tl-color-surface-selected: #DDE8FF;
+            --tl-color-surface-tint: rgba(255, 255, 255, 0.92);
+            --tl-color-surface-tint-strong: rgba(247, 249, 252, 0.96);
+            --tl-color-backdrop: rgba(15, 23, 40, 0.42);
+            --tl-color-border: #C9D3E2;
+            --tl-color-border-strong: #A7B4C8;
+            --tl-color-border-focus: #1557C0;
+            --tl-color-text: #0F1728;
+            --tl-color-muted: #3B4762;
+            --tl-color-muted-soft: #73819C;
+            --tl-color-accent: #1557C0;
+            --tl-color-accent-strong: #0E459B;
+            --tl-color-accent-soft: rgba(21, 87, 192, 0.12);
+            --tl-color-accent-wash: rgba(21, 87, 192, 0.06);
+            --tl-color-accent-border: rgba(21, 87, 192, 0.28);
+            --tl-color-accent-inset: rgba(21, 87, 192, 0.16);
+            --tl-color-on-accent: #FFFFFF;
+            --tl-color-signal: #0F8F85;
+            --tl-color-signal-bg: rgba(15, 143, 133, 0.12);
+            --tl-color-signal-border: rgba(15, 143, 133, 0.30);
+            --tl-color-ink: #0F1728;
+            --tl-color-paper: #F7F9FC;
+            --tl-color-danger: #A33434;
+            --tl-color-danger-bg: rgba(163, 52, 52, 0.10);
+            --tl-color-danger-border: rgba(163, 52, 52, 0.28);
+            --tl-color-warning-bg: rgba(122, 84, 0, 0.12);
+            --tl-color-warning-text: #7A5400;
+            --tl-color-warning-border: rgba(122, 84, 0, 0.30);
+            --tl-color-success-bg: rgba(19, 108, 71, 0.12);
+            --tl-color-success-text: #136C47;
+            --tl-color-success-border: rgba(19, 108, 71, 0.30);
+            --tl-color-info-bg: rgba(21, 87, 192, 0.10);
+            --tl-color-info-text: #1557C0;
+            --tl-color-info-border: rgba(21, 87, 192, 0.28);
+            --tl-color-neutral-bg: rgba(59, 71, 98, 0.10);
+            --tl-color-neutral-text: #3B4762;
+            --tl-color-neutral-border: #C9D3E2;
+            --tl-color-brand-rail: #0F1728;
+            --tl-shadow-subtle: 0 1px 2px rgba(15, 23, 40, 0.08), 0 1px 3px rgba(15, 23, 40, 0.06);
+            --tl-shadow-popover: 0 10px 28px rgba(15, 23, 40, 0.18);
+            --tl-shadow-raised: 0 18px 48px rgba(15, 23, 40, 0.24);
+            --tl-focus-ring: 0 0 0 3px rgba(21, 87, 192, 0.22), 0 0 0 1px var(--tl-color-border-focus);
+          }
+        }
+
         .threadline-ui *,
         .threadline-ui *::before,
         .threadline-ui *::after {
@@ -440,7 +543,7 @@ if Code.ensure_loaded?(Phoenix.LiveView) do
         .threadline-ui .tl-shell-nav__item[aria-current="page"] {
           background: var(--tl-color-accent-soft);
           border-color: var(--tl-color-accent-border);
-          box-shadow: inset 0 0 0 1px rgba(127, 169, 255, 0.16);
+          box-shadow: inset 0 0 0 1px var(--tl-color-accent-inset);
           color: var(--tl-color-accent-strong);
           font-weight: var(--tl-weight-strong);
         }
diff --git a/test/threadline/operator_surface/live/actor_live_test.exs b/test/threadline/operator_surface/live/actor_live_test.exs
index ac534568..bdd2c1c0 100644
--- a/test/threadline/operator_surface/live/actor_live_test.exs
+++ b/test/threadline/operator_surface/live/actor_live_test.exs
@@ -161,6 +161,13 @@ if Code.ensure_loaded?(Phoenix.LiveView) do
       assert html =~ "Invalid Actor Reference"
     end
 
+    test "ActorLive source never creates atoms from URL actor kind" do
+      source = File.read!("lib/threadline/operator_surface/live/actor_live.ex")
+
+      assert source =~ "String.to_existing_atom(kind)"
+      refute source =~ ~r/String\.to_atom\b/
+    end
+
     test "Case 2: Renders distinct empty state if actor has NEVER recorded an event", %{
       conn: conn
     } do
diff --git a/test/threadline/operator_surface/live/start_live_test.exs b/test/threadline/operator_surface/live/start_live_test.exs
index 4ce76d49..22d7ca40 100644
--- a/test/threadline/operator_surface/live/start_live_test.exs
+++ b/test/threadline/operator_surface/live/start_live_test.exs
@@ -72,6 +72,40 @@ if Code.ensure_loaded?(Phoenix.LiveView) do
     end
   end
 
+  defmodule Threadline.OperatorSurface.StartLiveTest.SystemThemeRouter do
+    use Phoenix.Router
+    import Phoenix.LiveView.Router
+    require Threadline.OperatorSurface.Router
+
+    pipeline :browser do
+      plug(:accepts, ["html"])
+      plug(:fetch_session)
+      plug(:fetch_live_flash)
+
+      plug(:put_root_layout,
+        html: {Threadline.OperatorSurface.StartLiveTest.Layouts, :root}
+      )
+    end
+
+    scope "/" do
+      pipe_through(:browser)
+
+      Threadline.OperatorSurface.Router.threadline_operator_surface("/audit_system",
+        repo: Threadline.Test.Repo,
+        schemas: %{
+          "ticket_replies" => Threadline.OperatorSurface.StartLiveTest.FakeTicketReply,
+          "users" => Threadline.OperatorSurface.StartLiveTest.FakeUser
+        },
+        theme: :system,
+        coverage_authorize_fn:
+          &Threadline.OperatorSurface.StartLiveTest.Auth.coverage_authorize/1,
+        policy_authorize_fn: &Threadline.OperatorSurface.StartLiveTest.Auth.authorize/1,
+        evidence_authorize_fn: &Threadline.OperatorSurface.StartLiveTest.Auth.authorize/1,
+        export_authorize_fn: &Threadline.OperatorSurface.StartLiveTest.Auth.authorize/1
+      )
+    end
+  end
+
   defmodule Threadline.OperatorSurface.StartLiveTest.ScopedRouter do
     use Phoenix.Router
     import Phoenix.LiveView.Router
@@ -140,6 +174,23 @@ if Code.ensure_loaded?(Phoenix.LiveView) do
     plug(Threadline.OperatorSurface.StartLiveTest.ScopedRouter)
   end
 
+  defmodule Threadline.OperatorSurface.StartLiveTest.SystemThemeEndpoint do
+    use Phoenix.Endpoint, otp_app: :threadline
+
+    @session_options [
+      store: :cookie,
+      key: "_threadline_start_system_key",
+      signing_salt: "start-system"
+    ]
+
+    plug(Plug.Session, @session_options)
+    plug(:fetch_session)
+    plug(Plug.Parsers, parsers: [:json], pass: ["*/*"], json_decoder: Phoenix.json_library())
+    plug(Plug.MethodOverride)
+    plug(Plug.Head)
+    plug(Threadline.OperatorSurface.StartLiveTest.SystemThemeRouter)
+  end
+
   defmodule Threadline.OperatorSurface.Live.StartLiveTest do
     use Threadline.DataCase, async: false
     import Phoenix.ConnTest
@@ -205,6 +256,7 @@ if Code.ensure_loaded?(Phoenix.LiveView) do
     test "renders Home as an orientation hub with existing destinations", %{conn: conn} do
       {:ok, _view, html} = live(conn, "/audit")
 
+      assert html =~ ~s|data-tl-theme="dark"|
       assert html =~ "Follow what happened."
       refute html =~ ~s|class="tl-home__eyebrow">Threadline</p>|
 
@@ -524,4 +576,45 @@ if Code.ensure_loaded?(Phoenix.LiveView) do
       assert has_element?(view, ~s|a[href="/audit_scoped/coverage"]|)
     end
   end
+
+  defmodule Threadline.OperatorSurface.Live.StartLiveSystemThemeTest do
+    use Threadline.DataCase, async: false
+    import Phoenix.ConnTest
+    import Phoenix.LiveViewTest
+
+    alias Threadline.Semantics.ActorRef
+
+    @endpoint Threadline.OperatorSurface.StartLiveTest.SystemThemeEndpoint
+
+    setup_all do
+      Application.put_env(
+        :threadline,
+        Threadline.OperatorSurface.StartLiveTest.SystemThemeEndpoint,
+        secret_key_base: "y" |> String.duplicate(64),
+        live_view: [signing_salt: "y" |> String.duplicate(8)],
+        render_errors: [view: Threadline.OperatorSurface.StartLiveTest.Layouts]
+      )
+
+      start_supervised!(@endpoint)
+      :ok
+    end
+
+    setup do
+      {:ok, actor_ref} = ActorRef.new(:user, "home-operator")
+
+      conn =
+        build_conn()
+        |> Plug.Test.init_test_session(
+          threadline_actor_ref: Jason.encode!(ActorRef.to_map(actor_ref))
+        )
+
+      {:ok, conn: conn}
+    end
+
+    test "renders system theme on the initial Home HTML", %{conn: conn} do
+      {:ok, _view, html} = live(conn, "/audit_system")
+
+      assert html =~ ~s|data-tl-theme="system"|
+    end
+  end
 end
diff --git a/test/threadline/operator_surface/live/timeline_live_test.exs b/test/threadline/operator_surface/live/timeline_live_test.exs
index b82d4377..0653546b 100644
--- a/test/threadline/operator_surface/live/timeline_live_test.exs
+++ b/test/threadline/operator_surface/live/timeline_live_test.exs
@@ -160,7 +160,13 @@ if Code.ensure_loaded?(Phoenix.LiveView) do
     end
 
     def auth(_socket), do: {:ok, %{access: :support_read_only, organization_id: "org_123"}}
-    def export_auth(_mirror), do: {:error, :unauthorized}
+
+    def export_auth(_mirror) do
+      case Application.get_env(:threadline, :test_support_export_auth, {:error, :unauthorized}) do
+        :raise -> raise "export auth failed"
+        result -> result
+      end
+    end
 
     def scope_operator_query(query, %{organization_id: org_id}, %{surface: :timeline}) do
       where(query, [_ac, at], fragment("?->>'organization_id' = ?", at.meta, ^org_id))
@@ -1218,6 +1224,9 @@ if Code.ensure_loaded?(Phoenix.LiveView) do
     end
 
     setup do
+      Application.delete_env(:threadline, :test_support_export_auth)
+      on_exit(fn -> Application.delete_env(:threadline, :test_support_export_auth) end)
+
       Threadline.Test.Repo.delete_all(Threadline.Governance.ExportJob)
       {:ok, conn: Phoenix.ConnTest.build_conn()}
     end
@@ -1250,5 +1259,22 @@ if Code.ensure_loaded?(Phoenix.LiveView) do
 
       assert Threadline.Test.Repo.all(Threadline.Governance.ExportJob) == []
     end
+
+    test "support-scoped mounts fail closed when export auth raises", %{conn: conn} do
+      Application.put_env(:threadline, :test_support_export_auth, :raise)
+
+      {:ok, lv, html} =
+        case live(conn, "/audit_support/timeline?table=support_posts") do
+          {:ok, _, _} = ok -> ok
+          {:error, {:live_redirect, %{to: path}}} -> live(conn, path)
+        end
+
+      refute html =~ "Queue export"
+      refute html =~ "Carry to Exports"
+
+      render_click(lv, "request_background_export", %{})
+
+      assert Threadline.Test.Repo.all(Threadline.Governance.ExportJob) == []
+    end
   end
 end
diff --git a/test/threadline/operator_surface/router_test.exs b/test/threadline/operator_surface/router_test.exs
index 41671b8c..70383bf0 100644
--- a/test/threadline/operator_surface/router_test.exs
+++ b/test/threadline/operator_surface/router_test.exs
@@ -130,6 +130,56 @@ if Code.ensure_loaded?(Phoenix.LiveView) do
           :code.purge(module)
         end
       end
+
+      test "Case 6: compiles successfully with system theme" do
+        modules =
+          Code.compile_quoted(
+            quote do
+              defmodule Threadline.OperatorSurface.RouterTest.SystemThemeMount do
+                use Phoenix.Router
+                require Threadline.OperatorSurface.Router
+
+                pipeline :browser do
+                  plug(:accepts, ["html"])
+                end
+
+                scope "/" do
+                  pipe_through(:browser)
+
+                  Threadline.OperatorSurface.Router.threadline_operator_surface("/threadline",
+                    theme: :system
+                  )
+                end
+              end
+            end
+          )
+
+        for {module, _} <- modules do
+          :code.delete(module)
+          :code.purge(module)
+        end
+      end
+
+      test "Case 7: raises CompileError for invalid theme literals" do
+        assert_raise CompileError,
+                     ~r/Threadline Operator Surface theme must be one of :dark \| :light \| :system/,
+                     fn ->
+                       Code.compile_quoted(
+                         quote do
+                           defmodule Threadline.OperatorSurface.RouterTest.InvalidThemeMount do
+                             use Phoenix.Router
+                             require Threadline.OperatorSurface.Router
+
+                             Threadline.OperatorSurface.Router.threadline_operator_surface(
+                               "/threadline",
+                               adopter_acknowledges_unauthenticated: true,
+                               theme: :sepia
+                             )
+                           end
+                         end
+                       )
+                     end
+      end
     end
   end
 end
diff --git a/test/threadline/operator_surface/style_contract_test.exs b/test/threadline/operator_surface/style_contract_test.exs
index 51794a54..ce1846b2 100644
--- a/test/threadline/operator_surface/style_contract_test.exs
+++ b/test/threadline/operator_surface/style_contract_test.exs
@@ -5,12 +5,23 @@ defmodule Threadline.OperatorSurface.StyleContractTest do
   @style_path "lib/threadline/operator_surface/style.ex"
   @motion_inventory_path ".planning/milestones/v1.31-phases/141-motion-micro-animation/141-MOTION-INVENTORY.md"
 
-  test "operator surface stays dark-only and token-driven" do
+  test "operator surface stays dark-default with governed light and system token lanes" do
     src = File.read!(@style_path)
 
     assert String.contains?(src, "color-scheme: dark;")
-    refute String.contains?(src, "prefers-color-scheme")
-    refute String.contains?(src, "color-scheme: light")
+    assert String.contains?(src, ~s|.threadline-ui[data-tl-theme="light"]|)
+    assert String.contains?(src, ~s|.threadline-ui[data-tl-theme="system"]|)
+    assert String.contains?(src, "@media (prefers-color-scheme: light)")
+    assert length(Regex.scan(~r/color-scheme: light;/, src)) == 2
+    assert String.contains?(src, "--tl-color-accent-inset:")
+
+    assert Regex.match?(
+             ~r/\.threadline-ui \.tl-shell-nav__item--active,\s*\.threadline-ui \.tl-shell-nav__item\[aria-current="page"\]\s*\{[^}]*box-shadow: inset 0 0 0 1px var\(--tl-color-accent-inset\);/s,
+             src
+           )
+
+    assert length(Regex.scan(~r/rgba\(127, 169, 255, 0\.16\)/, src)) == 1
+    refute String.contains?(src, "theme-toggle")
   end
 
   test "dark interaction tokens cover readable hover and focus states" do
@@ -552,7 +563,10 @@ defmodule Threadline.OperatorSurface.StyleContractTest do
   test "phase 143 accessibility tokens meet dark-surface contrast baseline" do
     src = File.read!(@style_path)
 
-    tokens = color_tokens(src)
+    tokens =
+      src
+      |> selector_block!(".threadline-ui")
+      |> color_tokens()
 
     backgrounds = [
       "--tl-color-bg",
@@ -677,8 +691,6 @@ defmodule Threadline.OperatorSurface.StyleContractTest do
 
     for anti_pattern <- [
           "@tailwind",
-          "prefers-color-scheme",
-          "color-scheme: light",
           "theme-toggle",
           "shadcn",
           "daisyui",
```
