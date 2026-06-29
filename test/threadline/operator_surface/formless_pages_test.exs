defmodule Threadline.OperatorSurface.FormlessPagesTest do
  @moduledoc """
  Regression guard locking the verified COMP-05 conclusion that the operator
  surface's display-only pages are genuinely formless.

  Phase 174 gap analysis confirmed the form components are already adopted
  everywhere a `<form>` legitimately exists (start_live, timeline_live,
  row_history_component, surface_header). The pages below render data and
  must NOT grow a `<form>`, `<input>`, `<select>`, or `<textarea>` — any such
  control belongs behind the `UI.field` / `UI.field_group` components and a real
  form page, not bolted onto a viewer.

  Scanning each page module's OWN source naturally excludes the shared
  `surface_header` component (defined in a separate module), whose hidden
  `<input type="hidden" name="_csrf_token">` and theme-picker `<form>` are a
  legitimate exception. We deliberately do not read surface_header.ex here,
  so its raw markup never trips this guard.

  `retention_history_live` is intentionally NOT in this list as of Phase 176
  (DATA-04 / D-20): the destructive "Prune now" action is a server-enforced
  type-to-confirm flow whose modal hosts a single `<form phx-submit="prune_now">`
  + text `<input>` (the operator types the policy name to confirm). That form is
  the ONE legitimate, security-mandated exception on that page — the page is no
  longer display-only.

  `coverage_live` is intentionally NOT in this list as of Phase 185 (COV-01 /
  COV-03): the page now has a native schema selector form that owns
  `/audit/coverage?schema=NAME` URL state. `policy_redaction_live` stays
  formless (read-only diff table, redact deferred per the Phase 176 checkpoint).
  """

  use ExUnit.Case, async: true

  @live_dir Path.join([
              File.cwd!(),
              "lib",
              "threadline",
              "operator_surface",
              "live"
            ])

  # The display-only pages confirmed formless by grep (0 form controls each).
  # retention_history_live is excluded as of Phase 176 — it now hosts the
  # security-mandated T3 prune-confirmation form (see @moduledoc).
  # coverage_live is excluded as of Phase 185 — it now hosts the native
  # selected-schema URL-state form (see @moduledoc).
  @formless_pages ~w(
    actor_live
    evidence_live
    export_status_live
    policy_redaction_live
    row_history_live
    transaction_live
  )

  @form_control_tokens ["<input", "<select", "<textarea", "<form"]

  describe "display-only operator-surface pages stay formless" do
    for page <- @formless_pages do
      @tag page: page
      test "#{page}.ex contains no <input>/<select>/<textarea>/<form>" do
        page = unquote(page)
        path = Path.join(@live_dir, page <> ".ex")
        source = File.read!(path)

        offenders =
          Enum.filter(@form_control_tokens, fn token ->
            String.contains?(source, token)
          end)

        assert offenders == [],
               "#{page}.ex must stay formless but contains form control(s): " <>
                 "#{inspect(offenders)}. Display-only pages must not add forms; " <>
                 "use UI.field/UI.field_group on a real form page instead. " <>
                 "(The hidden _csrf_token and theme-picker form live in the " <>
                 "separate surface_header component and are intentionally excluded.)"
      end
    end
  end
end
