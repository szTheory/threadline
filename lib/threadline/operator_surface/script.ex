if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Script do
    @moduledoc false

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
      [script_open(), status_helpers(), copy_activation()] |> IO.iodata_to_binary()
    end

    defp script_open do
      """
      (function () {
        if (window.__tlCopyBound) return;
        window.__tlCopyBound = true;
        var statusTimers = new WeakMap();
        var feedbackTimers = new WeakMap();
        var activationSelections = new WeakMap();
      """
    end

    defp status_helpers do
      """
        function statusFor(control) {
          var owner = control.closest(".tl-ref") || control.parentElement;
          if (!owner) return null;
          var status = owner.querySelector("[data-tl-copy-status]");
          if (status) return status;

          status = document.createElement("span");
          status.className = "tl-copy-status";
          status.setAttribute("data-tl-copy-status", "");
          status.setAttribute("role", "status");
          status.setAttribute("aria-live", "polite");
          status.setAttribute("aria-atomic", "true");
          owner.appendChild(status);
          return status;
        }

        function announce(control, message, state) {
          var status = statusFor(control);
          if (!status) return;
          var timer = statusTimers.get(status);
          if (timer) window.clearTimeout(timer);
          status.textContent = message;
          if (state) status.setAttribute("data-state", state);
          else status.removeAttribute("data-state");

          if (state !== "pending") {
            statusTimers.set(status, window.setTimeout(function () {
              status.textContent = "";
              status.removeAttribute("data-state");
              statusTimers.delete(status);
            }, 4000));
          } else {
            statusTimers.delete(status);
          }
        }

        function feedbackTarget(control) {
          if (control.matches("button.tl-copy")) return control;
          var group = control.closest(".tl-ref");
          return group ? group.querySelector("button.tl-copy") : null;
        }

        function clearFeedback(control) {
          var target = feedbackTarget(control);
          if (!target) return;
          target.classList.remove("is-copied");
          var timer = feedbackTimers.get(target);
          if (timer) window.clearTimeout(timer);
          feedbackTimers.delete(target);
        }

        function complete(control) {
          announce(control, "Copied.", "success");
          var target = feedbackTarget(control);
          if (!target) return;
          target.classList.add("is-copied");
          var timer = feedbackTimers.get(target);
          if (timer) window.clearTimeout(timer);
          feedbackTimers.set(target, window.setTimeout(function () {
            target.classList.remove("is-copied");
            feedbackTimers.delete(target);
          }, 1200));
        }

        function fail(control) {
          announce(control, "Copy failed. Select the value and copy it manually.", "error");
        }
      """
    end

    defp copy_activation do
      """
        function selectionSnapshot() {
          var selection = window.getSelection();
          if (!selection) return null;
          var ranges = [];
          for (var i = 0; i < selection.rangeCount; i++) ranges.push(selection.getRangeAt(i).cloneRange());
          return { selection: selection, ranges: ranges };
        }

        function eventControl(e) {
          var target = e.target instanceof Element ? e.target : e.target && e.target.parentElement;
          return target && target.closest("[data-tl-copy]");
        }

        document.addEventListener("pointerdown", function (e) {
          var control = eventControl(e);
          if (control && !control.matches(":disabled, [aria-disabled='true']")) {
            activationSelections.set(control, selectionSnapshot());
          }
        }, true);

        function fallbackCopy(text, priorSelection) {
          var active = document.activeElement;
          var saved = priorSelection || selectionSnapshot();
          var selection = saved && saved.selection;
          var ranges = saved ? saved.ranges : [];
          var ta = document.createElement("textarea");
          ta.setAttribute("readonly", "");
          ta.setAttribute("data-tl-copy-fallback", "");
          ta.value = text;
          ta.style.position = "fixed";
          ta.style.top = "0";
          ta.style.left = "0";
          ta.style.opacity = "0";
          var copied = false;
          try {
            document.body.appendChild(ta);
            ta.focus({ preventScroll: true });
            ta.select();
            copied = document.execCommand("copy") === true;
          } catch (e) {
            copied = false;
          } finally {
            if (ta.parentNode) ta.parentNode.removeChild(ta);
            try {
              if (active && typeof active.focus === "function") active.focus({ preventScroll: true });
            } catch (e) {}
            if (selection) {
              window.setTimeout(function () {
                try {
                  selection.removeAllRanges();
                  ranges.forEach(function (range) { selection.addRange(range); });
                } catch (e) {}
              }, 0);
            }
          }
          return copied;
        }

        document.addEventListener("click", function (e) {
          var control = eventControl(e);
          if (!control || control.matches(":disabled, [aria-disabled='true']")) return;
          var text = control.getAttribute("data-tl-copy");
          if (text === null || text === "") return;
          var priorSelection = activationSelections.get(control);
          activationSelections.delete(control);

          clearFeedback(control);
          announce(control, "Copying…", "pending");
          function fallback() {
            if (fallbackCopy(text, priorSelection)) complete(control);
            else fail(control);
          }

          try {
            var clipboard = navigator.clipboard;
            if (clipboard && typeof clipboard.writeText === "function") {
              Promise.resolve(clipboard.writeText(text)).then(function () { complete(control); }, fallback);
            } else {
              fallback();
            }
          } catch (e) {
            fallback();
          }
        });
      })();
      """
    end
  end
end
