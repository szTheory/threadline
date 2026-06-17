defmodule Threadline.OperatorSurface.FormlessPagesTest do
  @moduledoc """
  Regression guard locking the verified COMP-05 conclusion that the operator
  surface's display-only pages are genuinely formless.

  Phase 174 gap analysis confirmed the form components are already adopted
  everywhere a `<form>` legitimately exists (start_live, timeline_live,
  row_history_component, surface_header). The eight pages below render data and
  must NOT grow a `<form>`, `<input>`, `<select>`, or `<textarea>` — any such
  control belongs behind the `UI.field` / `UI.field_group` components and a real
  form page, not bolted onto a viewer.

  Scanning each page module's OWN source naturally excludes the shared
  `surface_header` component (defined in a separate module), whose hidden
  `<input type="hidden" name="_csrf_token">` and theme-picker `<form>` are the
  ONE legitimate exception. We deliberately do not read surface_header.ex here,
  so its raw markup never trips this guard.
  """

  use ExUnit.Case, async: true

  @live_dir Path.join([
              File.cwd!(),
              "lib",
              "threadline",
              "operator_surface",
              "live"
            ])

  # The 8 display-only pages confirmed formless by grep (0 form controls each).
  @formless_pages ~w(
    actor_live
    coverage_live
    evidence_live
    export_status_live
    policy_redaction_live
    retention_history_live
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
