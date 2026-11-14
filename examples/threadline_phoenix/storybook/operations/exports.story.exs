defmodule ThreadlinePhoenixWeb.Storybook.Operations.ExportsStory do
  use PhoenixStorybook.Story, :page
  import ThreadlinePhoenixWeb.Storybook.Wrapper
  alias ThreadlinePhoenixWeb.Storybook.Fixtures
  alias Threadline.OperatorSurface.Live.ExportStatusLive
  alias Threadline.OperatorSurface.UI

  def doc do
    """
    Static production Export composition: route.exports / job.operator-export-status,
    source-exports-6, proof-exports-1 and proof-exports-2. Ordinary identity is
    scenario.acme-4521-investigation; failed delivery is separately projected as
    scenario.state-export-failed / fixture.state-export-failed.1.
    Static examples do not establish permissions, query results, file availability,
    downloads, persistence or reconnect safety. Example navigation uses the host's
    /audit routes and requires its real authorization and files. Rendering creates
    no file or job. The ordinary completed projection has no expiry value; this is
    illustrative metadata, not the persisted seed-run TTL. Theme support uses
    threadline_preview; error/denied/pending and long references are separate cases.
    """
  end

  def render(assigns) do
    assigns =
      assign(
        assigns,
        :scenes,
        Enum.map(Fixtures.operation_cases(), &Fixtures.operations_exports/1)
      )

    ~H"""
    <.threadline_preview theme="dark">
      <.preview_section title="Static Operations Export" description="Static examples do not establish permissions, query results, downloads, persistence or reconnect safety. Example links use the actual host routes; they require real host access and files.">
        <UI.Display.stack gap="section">
          <section :for={scene <- @scenes} aria-label={"Export #{scene.scene} static example"}>
            <h3 class="tl-detail-header__title"><%= scene.scene %> — static example</h3>
            <p :if={scene.scene == :loading} role="status">Pending projection — no new read has completed.</p>
            <UI.Data.empty_state :if={scene.scene in [:empty, :zero]}><:title>No export jobs</:title>Start an export from Timeline to see its status here.</UI.Data.empty_state>
            <UI.Data.error_state :if={scene.scene == :error}><:title>Export history could not be loaded</:title>Your saved jobs are unchanged; try refreshing this page. Static error projection.</UI.Data.error_state>
            <UI.Data.data_state :if={scene.scene == :denied} reason={:unauthorized} />
            <ExportStatusLive.Components.job_history id={"operation-exports-#{scene.scene}"} :if={scene.job_groups != []} jobs_count={scene.jobs_count} default_limit={scene.default_limit} job_groups={scene.job_groups} base_path={scene.base_path} />
          </section>
        </UI.Display.stack>
      </.preview_section>
    </.threadline_preview>
    """
  end
end
