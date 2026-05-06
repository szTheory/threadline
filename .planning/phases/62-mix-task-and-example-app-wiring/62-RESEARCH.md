# Phase 62 Architectural Research & Recommendations

**Phase:** 62 - Mix Task & Example-app Wiring
**Context:** This research fulfills the deep, cohesive, one-shot recommendation mandate for Phase 62. It addresses the gray areas of `mix threadline.incident` CLI design and canonical `phx.gen.auth` admin pipeline wiring.

## 1. Mix Task Design (`mix threadline.incident`)

### Goal
Provide a no-LiveView operator path that renders `Threadline.incident_bundle/2` in a human-readable console layout, and supports `--json` for pipeable downstream tooling (CLI-01).

### Architectural Recommendation

**Approach:** Build a standard `Mix.Task` that leverages `OptionParser`, strictly controls standard output (`stdout`), and safely boots the OTP application without polluting the output stream (crucial for `--json`).

#### Pros/Cons/Tradeoffs
*   **Pro:** Native Elixir CLI experience; no extra dependencies required for argument parsing.
*   **Pro:** `--json` allows easy piping into `jq` for advanced operators, mirroring best-in-class CLI tools (like `kubectl` or `aws-cli`).
*   **Con:** Formatting tables/trees in the terminal can be tedious without a dependency like `TableRex`. *Mitigation:* Use simple, structured indented text with `IO.ANSI` colors (like `git log` or `mix deps.tree`) rather than full grid tables to keep dependencies zero.
*   **Tradeoff:** Booting the app (`Mix.Task.run("app.start")`) often prints Telemetry or Logger info. This breaks `--json` pipeability. *Recommendation:* We must dynamically adjust logger levels to `:warning` or `:error` when `--json` is passed, or ensure the JSON is strictly written to stdout while logs go to stderr.

### Idiomatic Elixir / Ecosystem Lessons
*   **Oban & Ecto CLI:** Ecto's `mix ecto.migrate` and Oban's CLI tasks are prime examples. They parse arguments simply, boot the app explicitly (`app.start`), and handle connection pooling.
*   **Footgun (Logging vs stdout):** A major footgun in Elixir CLIs returning JSON is that `Logger` defaults to printing to stdout. If an Ecto query logs, the JSON is corrupted.
*   **UX / Ergonomics:**
    *   Fail fast with clear messaging: "Usage: mix threadline.incident <transaction_id> [--json]" if arguments are missing.
    *   Use `IO.ANSI.format/1` for human-readable mode to highlight Actor, Timestamp, and Changes, adhering to the Principle of Least Surprise (it should feel like `mix test` output).

### Implementation Details
*   **Parser:** `OptionParser.parse(args, switches: [json: :boolean])`.
*   **JSON Mode:** If `--json` is present, encode the `incident_bundle/2` map using `Jason.encode!` (assuming Jason is available via Ecto/Phoenix) and `IO.puts()`. Force `Logger.configure(level: :error)` at the top of the `run/1` function.
*   **Human-readable Mode:** Iterate through the bundle and `IO.puts` formatted strings. E.g., `[IO.ANSI.green(), "Actor: ", IO.ANSI.reset(), actor_id]`.

---

## 2. Canonical Example App Wiring (SURF-04)

### Goal
Demonstrate how to mount the `threadline_operator_surface` macro behind a standard `phx.gen.auth` admin pipeline in `examples/threadline_phoenix`, populating `:actor_fn` and `:authorize_fn`.

### Architectural Recommendation

**Approach:** Use a dedicated Phoenix pipeline in `router.ex` that authenticates the user, checks admin privileges, and leverages the mount macro.

#### Pros/Cons/Tradeoffs
*   **Pro:** Mirrors how 90% of Phoenix apps secure `LiveDashboard` and `Oban Web`. It's the most recognized pattern.
*   **Pro:** Keeps Threadline completely agnostic of the host's User/Admin schema.
*   **Tradeoff:** We must define what a "fail closed" default looks like in our macro (AUTH-02) versus what the host does. The host's `router.ex` is the ultimate arbiter of access.

### Idiomatic Elixir / Ecosystem Lessons
*   **LiveDashboard & Oban Web:** LiveDashboard uses `import Phoenix.LiveDashboard.Router` and `live_dashboard "/dashboard", metrics: ..., on_mount: [...]`. We are providing `:actor_fn` and `:authorize_fn` directly to the macro.
*   **Footgun (Silent Fail Open):** Mounting a dashboard in the root scope without `pipe_through :browser` or an auth pipeline. Threadline's AUTH-02 requires the macro to fail closed if not in a `pipe_through` or without an `authorize_fn`.
*   **UX / Ergonomics:** Provide a clear, copy-pasteable block in the README/Guides.

### Implementation Details in `examples/threadline_phoenix`
1.  **Pipeline / Plug:**
    Assuming `phx.gen.auth` is generated, we add a plug `require_authenticated_admin/2` in `ThreadlinePhoenixWeb.UserAuth`.
    ```elixir
    def require_authenticated_admin(conn, _opts) do
      if conn.assigns[:current_user] && conn.assigns[:current_user].is_admin do
        conn
      else
        conn
        |> put_flash(:error, "You must be an admin to access this page.")
        |> redirect(to: ~p"/")
        |> halt()
      end
    end
    ```
2.  **Router Wiring:**
    ```elixir
    scope "/audit", ThreadlinePhoenixWeb do
      pipe_through [:browser, :require_authenticated_user, :require_authenticated_admin]

      threadline_operator_surface "/",
        actor_fn: &my_actor_fn/1,
        authorize_fn: &my_authorize_fn/1
    end

    defp my_actor_fn(%Plug.Conn{} = conn), do: %{id: conn.assigns.current_user.id, type: "user"}
    defp my_authorize_fn(_conn_or_socket), do: :ok # Already guaranteed by pipeline
    ```
    *Self-Correction on `authorize_fn`:* If the pipeline already halts unauthorized users, the `authorize_fn` can simply return `:ok`. However, to show a robust example, the `authorize_fn` should redundantly check or return a scope: `{:ok, %{tenant_id: current_user.tenant_id}}` if tenancy was a thing, or simply `:ok`.

## Synthesis

This approach creates a robust, Unix-philosophy-aligned CLI tool that avoids log-pollution for JSON pipes, and provides a canonically secure `phx.gen.auth` router integration that exactly mimics the industry-standard `LiveDashboard` placement. Both solutions maximize developer ergonomics while enforcing fail-closed security.
