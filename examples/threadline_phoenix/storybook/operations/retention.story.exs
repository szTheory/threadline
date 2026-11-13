defmodule ThreadlinePhoenixWeb.Storybook.Operations.RetentionStory do
  use PhoenixStorybook.Story, :page
  import ThreadlinePhoenixWeb.Storybook.Wrapper
  alias ThreadlinePhoenixWeb.Storybook.Fixtures
  alias Threadline.OperatorSurface.Live.RetentionHistoryLive.Components
  alias Threadline.OperatorSurface.UI

  def doc do
    """
    Read-only production history and estimate composition: route.retention /
    job.operator-retention-operations, source-retention-preview, source-retention-6,
    proof-retention-1 and proof-retention-2. Ordinary history matches the deterministic
    completed-small14-row record. scenario.offboarded-co-retention-boundary is a
    separate destructive-proof boundary, never executed by this page. The pure
    fixtures use the existing manifest identities and epoch; preview counts are
    explicit static projections, not SQL results or recorded outcomes.
    Static composition cannot establish permissions, SQL counts, persistence or
    reconnect safety. Destructive controls are absent; no confirmation target is
    constructed. All themes use threadline_preview and existing production tokens.
    """
  end

  def render(assigns) do
    assigns =
      assign(
        assigns,
        :scenes,
        Enum.map(Fixtures.operation_cases(), &Fixtures.operations_retention/1)
      )

    ~H"""
    <.threadline_preview theme="dark">
      <.preview_section title="Static Operations Retention" description="Read-only static projections. No policy authorization, SQL count, deletion, recorded run or reconnect behavior is established by these examples.">
        <UI.Display.stack gap="section">
          <section :for={scene <- @scenes} aria-label={"Retention #{scene.scene} static example"}>
            <h3 class="tl-detail-header__title"><%= scene.scene %> — static example</h3>
            <p :if={scene.scene == :loading} role="status">Pending projection — no new read has completed.</p>
            <Components.retention_preview preview={scene.preview} state={scene.preview_state} />
            <UI.Data.empty_state :if={scene.scene in [:empty, :zero]}><:title>No retention runs</:title>A run appears here after a confirmed prune or scheduled retention operation. A transient preview is not a recorded run.</UI.Data.empty_state>
            <UI.Data.error_state :if={scene.scene == :error}><:title>Retention history could not be loaded</:title>The saved runs are unchanged. Refresh to check their current status. Static error projection.</UI.Data.error_state>
            <UI.Data.data_state :if={scene.scene == :denied} reason={:unauthorized} />
            <Components.run_history :if={scene.runs != []} runs={scene.runs} runs_count={scene.runs_count} default_limit={scene.default_limit} retention_summary={scene.retention_summary} retention_actions={scene.retention_actions} streamed={scene.streamed} table_id={scene.table_id} />
          </section>
        </UI.Display.stack>
      </.preview_section>
    </.threadline_preview>
    """
  end
end
