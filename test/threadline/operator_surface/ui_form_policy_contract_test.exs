defmodule Threadline.OperatorSurface.UIFormPolicyContractTest do
  @moduledoc """
  GREEN-05 / D-07: every operator-surface LiveView page self-declares whether it
  is display-only, and the declaration lives in the page file itself.

  This supersedes `formless_pages_test.exs`, which drove the same check from an
  allowlist of six page names held in the test file. That shape had three defects,
  all of which this contract closes:

    1. **A new page could be silently unguarded.** Membership was opt-in, so a page
       nobody remembered to add was simply never checked. `stress_live.ex` was in no
       list at all. Here the roster is derived from the directory, so a page that
       declares nothing fails.
    2. **The fix landed in the wrong diff.** Adding a form meant editing an allowlist
       in `test/`, far from the change. The declaration is now co-located with the
       markup, so the guard fails in the same diff as the change that breaks it —
       GREEN-05 verbatim.
    3. **Reverse drift went unnoticed.** A page that keeps a stale exemption after its
       form is removed, or that grows a form while still listed as formless, was
       invisible. `policy_redaction_live.ex` was in exactly that state: still on the
       allowlist after gaining a host-schema picker.

  `row_history_component.ex` is excluded by construction rather than by list — the
  glob targets `*_live.ex`, and a component is not a page. Likewise `surface_header.ex`
  is not under `live/` at all, so its legitimate hidden CSRF input and theme-picker
  form never reach this scan.

  The has-forms value carries a reason string on purpose. It is an unconditional pass,
  so it is the one route by which a page could exempt itself; requiring a stated reason
  in the page file keeps that exemption visible and reviewable in the diff that adds it.
  """

  use ExUnit.Case, async: true

  @live_dir Path.join([
              File.cwd!(),
              "lib",
              "threadline",
              "operator_surface",
              "live"
            ])

  # The same token list the superseded formless_pages_test.exs used.
  @form_control_tokens ["<input", "<select", "<textarea", "<form"]

  defp live_page_files, do: Path.wildcard(Path.join(@live_dir, "*_live.ex"))

  defp module_for(path) do
    path
    |> Path.basename(".ex")
    |> String.split("_")
    |> Enum.map_join(&String.capitalize/1)
    |> then(&Module.concat(Threadline.OperatorSurface.Live, &1))
  end

  test "every operator-surface live page self-declares @ui_form_policy" do
    files = live_page_files()

    assert files != [],
           "no *_live.ex files found under #{@live_dir} — the glob is broken. A broken " <>
             "glob would let this guard pass vacuously while every operator-surface page " <>
             "went unchecked."

    for path <- files do
      relative = Path.relative_to_cwd(path)
      module = module_for(path)

      assert Code.ensure_loaded?(module),
             "#{relative} did not resolve to a loaded module (#{inspect(module)}). The " <>
               "guard derives the module from the filename, so a page whose module name " <>
               "does not match its filename must be renamed or the derivation updated."

      policy = module.__info__(:attributes)[:ui_form_policy]

      assert policy != nil,
             "#{relative} has no @ui_form_policy declaration. Every operator-surface page " <>
               "must self-declare one of:\n" <>
               "    Module.register_attribute(__MODULE__, :ui_form_policy, persist: true)\n" <>
               "    @ui_form_policy :formless\n" <>
               "or, when the page legitimately hosts a form:\n" <>
               "    @ui_form_policy {:has_forms, \"short reason\"}\n" <>
               "The declaration is persisted, so `persist: true` is required."

      case policy do
        [:formless] ->
          source = File.read!(path)
          offenders = Enum.filter(@form_control_tokens, &String.contains?(source, &1))

          assert offenders == [],
                 "#{relative} declares @ui_form_policy :formless but contains form " <>
                   "control(s): #{inspect(offenders)}. Either move the control behind " <>
                   "UI.field / UI.field_group on a real form page, or change this page's " <>
                   "declaration to {:has_forms, \"reason\"} in this same diff."

        [{:has_forms, reason}] when is_binary(reason) and reason != "" ->
          :ok

        other ->
          flunk(
            "#{relative} declares an invalid @ui_form_policy #{inspect(other)}. " <>
              "Valid values are :formless or {:has_forms, reason} where reason is a " <>
              "non-empty string explaining why the page hosts a form."
          )
      end
    end
  end
end
