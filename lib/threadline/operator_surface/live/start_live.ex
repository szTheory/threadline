if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Live.StartLive do
    @moduledoc false

    use Phoenix.LiveView
    import Ecto.Query

    alias Threadline.Governance.ExportJob
    alias Threadline.Governance.RetentionRun
    alias Threadline.Governance.SavedView
    alias Threadline.OperatorSurface.Exports.FilterParams

    # ------------------------------------------------------------------
    # Operator Home — the orienting landing page (surface root).
    #
    # A task launcher: it lets each operator pick their job in plain
    # language (GDS "start with user needs") rather than assuming every
    # visitor wants the timeline first. Cards mirror the Find / Verify /
    # Prove nav and degrade gracefully when sections are feature-flagged
    # off. The "System health" row answers the platform-engineer's
    # standing question — "is anything wrong?" — at a glance, so problems
    # surface here instead of being hunted across four pages.
    #
    # Coverage/feature-flag assigns are populated by the Auth and
    # Coverage.OnMount hooks before this mount/3 runs. Health queries are
    # read-only and individually fail-safe: any error degrades to "no
    # signal" rather than breaking the landing page.
    # ------------------------------------------------------------------

    def mount(_params, _session, socket) do
      {:ok,
       socket
       |> assign(:base_path, nil)
       |> assign(:health, [])
       |> assign(:health_enabled, false)
       |> assign(:saved_views, [])}
    end

    def handle_params(_params, uri, socket) do
      # StartLive is mounted at the surface root, so its own path IS base_path.
      base_path = URI.parse(uri).path || ""

      {:noreply,
       socket
       |> assign(:base_path, base_path)
       |> assign(:health, health_warnings(socket))
       |> assign(:health_enabled, any_subsystem_enabled?(socket))
       |> assign(:saved_views, fetch_saved_views(socket))}
    end

    def render(assigns) do
      assigns =
        assign(
          assigns,
          :prove_enabled,
          assigns[:threadline_evidence_enabled] || assigns[:threadline_policy_enabled] ||
            assigns[:threadline_exports_enabled]
        )

      ~H"""
      <div class="threadline-ui">
        <Threadline.OperatorSurface.Style.css />
        <Threadline.OperatorSurface.Components.SurfaceHeader.surface_header
          coverage={@threadline_coverage}
          base_path={@base_path}
          error={@threadline_coverage_error}
          coverage_enabled={@threadline_coverage_enabled}
          policy_enabled={@threadline_policy_enabled}
          evidence_enabled={@threadline_evidence_enabled}
          exports_enabled={@threadline_exports_enabled}
          current={:start}
        />

        <main id="tl-main" class="tl-page tl-home">
          <header class="tl-home__hero">
            <p class="tl-home__eyebrow">Threadline</p>
            <h1 class="tl-home__headline">Follow what happened.</h1>
            <p class="tl-home__lede">
              Every change is connected to the action, context, and story around it.
              Pick where you want to start.
            </p>
            <div :if={@health_enabled} class="tl-home__health" role="status" aria-label="System health">
              <span class="tl-home__health-label">System health</span>
              <%= if @health == [] do %>
                <span class="tl-chip tl-chip--success">All systems healthy</span>
              <% else %>
                <a :for={signal <- @health} class="tl-chip tl-chip--warning" href={"#{@base_path}#{signal.path}"}>
                  <%= signal.label %>
                </a>
              <% end %>
            </div>
          </header>

          <ul class="tl-home__cards">
            <li class="tl-home__card tl-home__card--primary">
              <span class="tl-home__card-kicker">Find</span>
              <h2 class="tl-home__card-title">What changed?</h2>
              <p class="tl-home__card-body">
                Search captured changes by time, table, actor, or correlation id — then open the
                transaction and row history to see exactly who did it and why.
              </p>
              <a href={"#{@base_path}/timeline"} class="tl-button tl-button--primary">
                Open the timeline
              </a>
            </li>

            <li :if={@threadline_coverage_enabled} class="tl-home__card">
              <span class="tl-home__card-kicker">Verify</span>
              <h2 class="tl-home__card-title">Is everything captured?</h2>
              <p class="tl-home__card-body">
                Confirm every table you rely on is actually audited. Close coverage gaps before you
                trust the timeline to be complete.
              </p>
              <a href={"#{@base_path}/coverage"} class="tl-button tl-button--secondary">
                Check coverage
              </a>
            </li>

            <li :if={@prove_enabled} class="tl-home__card">
              <span class="tl-home__card-kicker">Prove</span>
              <h2 class="tl-home__card-title">Prove and export</h2>
              <p class="tl-home__card-body">
                Produce defensible answers for auditors and legal: evidence proofs, retention runs,
                redaction status, and downloadable exports.
              </p>
              <div class="tl-home__card-links">
                <a :if={@threadline_evidence_enabled} href={"#{@base_path}/evidence"} class="tl-button tl-button--secondary tl-button--compact">Evidence</a>
                <a :if={@threadline_policy_enabled} href={"#{@base_path}/policy/redaction"} class="tl-button tl-button--secondary tl-button--compact">Redaction</a>
                <a :if={@threadline_policy_enabled} href={"#{@base_path}/policy/retention"} class="tl-button tl-button--secondary tl-button--compact">Retention</a>
                <a :if={@threadline_exports_enabled} href={"#{@base_path}/exports"} class="tl-button tl-button--secondary tl-button--compact">Exports</a>
              </div>
            </li>
          </ul>

          <section :if={@saved_views != []} class="tl-home__resume" aria-label="Saved searches">
            <h2 class="tl-home__section-title">Pick up where you left off</h2>
            <p class="tl-home__section-lede">Reopen a saved timeline search.</p>
            <ul class="tl-home__views">
              <li :for={view <- @saved_views}>
                <.link navigate={saved_view_path(@base_path, view)} class="tl-chip tl-chip--accent tl-home__view">
                  <%= view.name %>
                </.link>
              </li>
            </ul>
          </section>
        </main>
      </div>
      """
    end

    # ------------------------------------------------------------------
    # Health aggregation (read-only, individually fail-safe)
    # ------------------------------------------------------------------

    defp any_subsystem_enabled?(socket) do
      !!(socket.assigns[:threadline_coverage_enabled] ||
           socket.assigns[:threadline_exports_enabled] ||
           socket.assigns[:threadline_policy_enabled])
    end

    defp health_warnings(socket) do
      coverage_warning(socket) ++ exports_warning(socket) ++ retention_warning(socket)
    end

    defp coverage_warning(socket) do
      coverage = socket.assigns[:threadline_coverage]

      if socket.assigns[:threadline_coverage_enabled] && coverage &&
           coverage.uncovered_count > 0 do
        [%{label: "#{coverage.uncovered_count} tables need audit coverage", path: "/coverage"}]
      else
        []
      end
    end

    defp exports_warning(socket) do
      with true <- !!socket.assigns[:threadline_exports_enabled],
           n when is_integer(n) and n > 0 <- failed_export_count(socket) do
        unit = if n == 1, do: "export", else: "exports"
        [%{label: "#{n} failed #{unit}", path: "/exports"}]
      else
        _ -> []
      end
    end

    defp retention_warning(socket) do
      if socket.assigns[:threadline_policy_enabled] && latest_retention_failed?(socket) do
        [%{label: "Latest retention run failed", path: "/policy/retention"}]
      else
        []
      end
    end

    defp failed_export_count(socket) do
      actor_ref = socket.assigns[:threadline_actor_ref]
      repo = resolve_repo(socket)

      if actor_ref && repo do
        try do
          repo.aggregate(
            from(j in ExportJob, where: j.status == "failed" and j.actor_ref == ^actor_ref),
            :count
          )
        rescue
          _ -> nil
        end
      end
    end

    defp latest_retention_failed?(socket) do
      repo = resolve_repo(socket)

      if repo do
        try do
          case repo.one(from(r in RetentionRun, order_by: [desc: r.started_at], limit: 1)) do
            %{status: "failed"} -> true
            _ -> false
          end
        rescue
          _ -> false
        end
      else
        false
      end
    end

    defp resolve_repo(socket) do
      socket.assigns[:threadline_repo] ||
        Application.get_env(:threadline, :ecto_repos, []) |> List.first()
    end

    # ------------------------------------------------------------------
    # Recent/saved fast-path (A4) — returning operators skip re-filtering.
    # Read-only and fail-safe: any error degrades to "no saved views".
    # ------------------------------------------------------------------

    defp fetch_saved_views(socket) do
      actor_ref = socket.assigns[:threadline_actor_ref]
      repo = resolve_repo(socket)

      if actor_ref && repo do
        try do
          repo.all(
            from(v in SavedView,
              where: v.actor_ref == ^actor_ref,
              order_by: [desc: v.inserted_at],
              limit: 6
            )
          )
        rescue
          _ -> []
        end
      else
        []
      end
    end

    defp saved_view_path(base_path, view) do
      case FilterParams.canonical_query(view.filters || %{}) do
        "" -> "#{base_path}/timeline"
        query -> "#{base_path}/timeline?#{query}"
      end
    end
  end
end
