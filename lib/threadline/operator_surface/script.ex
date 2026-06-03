if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Script do
    @moduledoc """
    Embeds a tiny, dependency-free copy-to-clipboard helper for the operator
    surface. Rendered once per page alongside `Threadline.OperatorSurface.Style.css/1`.

    Self-contained vanilla JS — no npm dependency, no host asset pipeline, and
    no LiveSocket hook registration. It binds a single delegated `click` listener
    (idempotent via a `window.__tlCopyBound` guard, so re-mounts don't double-bind)
    on `[data-tl-copy]` elements: it copies the attribute value to the clipboard
    and toggles `.is-copied` on the trigger for the confirmation pulse + chip.

    Hosts with a strict Content-Security-Policy that forbids inline scripts can
    disable it with `config :threadline, operator_surface_embed_scripts: false`
    (the copy buttons then fall back to native text selection of the ids).
    """

    import Phoenix.Component

    @doc "Renders the embedded copy helper `<script>` (no-op when disabled)."
    def js(assigns) do
      assigns = assign(assigns, :script_html, script_html())

      ~H"""
      {@script_html}
      """
    end

    @doc """
    Whether the embedded copy helper is active. LiveViews gate the copy
    affordances on this so a disabled-script (CSP-strict) deployment shows the
    ids for native selection instead of an inert button.
    """
    def enabled?, do: embed_scripts?()

    defp script_html do
      if embed_scripts?() do
        Phoenix.HTML.raw(["<script>", script_body(), "</script>"])
      else
        Phoenix.HTML.raw("")
      end
    end

    defp embed_scripts? do
      Application.get_env(:threadline, :operator_surface_embed_scripts, true)
    end

    defp script_body do
      """
      (function () {
        if (window.__tlCopyBound) return;
        window.__tlCopyBound = true;
        function fallbackCopy(text) {
          try {
            var ta = document.createElement("textarea");
            ta.value = text;
            ta.setAttribute("readonly", "");
            ta.style.position = "fixed";
            ta.style.opacity = "0";
            document.body.appendChild(ta);
            ta.select();
            var ok = document.execCommand("copy");
            document.body.removeChild(ta);
            return ok;
          } catch (e) { return false; }
        }
        document.addEventListener("click", function (e) {
          var btn = e.target.closest("[data-tl-copy]");
          if (!btn) return;
          var text = btn.getAttribute("data-tl-copy");
          if (!text) return;
          function flash() {
            btn.classList.add("is-copied");
            window.setTimeout(function () { btn.classList.remove("is-copied"); }, 1200);
          }
          if (navigator.clipboard && navigator.clipboard.writeText) {
            navigator.clipboard.writeText(text).then(flash, function () { if (fallbackCopy(text)) flash(); });
          } else if (fallbackCopy(text)) {
            flash();
          }
        });
      })();
      """
    end
  end
end
