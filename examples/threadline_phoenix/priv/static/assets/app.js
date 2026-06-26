import { Socket } from "./phoenix.mjs";
import { LiveSocket } from "./phoenix_live_view.esm.js";

const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  ?.getAttribute("content");

const liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
});

liveSocket.connect();

window.liveSocket = liveSocket;
window.Phoenix = { Socket };

const demoCopyStatusTimers = new WeakMap();

function fallbackCopy(text) {
  try {
    const textarea = document.createElement("textarea");
    textarea.value = text;
    textarea.setAttribute("readonly", "");
    textarea.style.position = "fixed";
    textarea.style.opacity = "0";
    document.body.appendChild(textarea);
    textarea.select();
    const copied = document.execCommand("copy");
    document.body.removeChild(textarea);
    return copied;
  } catch (_error) {
    return false;
  }
}

function flashDemoCopy(trigger, label) {
  const group = trigger.closest(".rd-demo-creds");
  const status =
    group?.querySelector("[data-demo-copy-status]") ||
    document.querySelector("[data-demo-copy-status]");

  group?.querySelectorAll(".is-copied").forEach((node) => {
    if (node !== trigger) node.classList.remove("is-copied");
  });

  trigger.classList.add("is-copied");
  window.setTimeout(() => trigger.classList.remove("is-copied"), 1200);

  if (status) {
    status.textContent = `Copied ${label}`;
    status.classList.add("is-visible");

    const previousTimer = demoCopyStatusTimers.get(status);
    if (previousTimer) window.clearTimeout(previousTimer);

    demoCopyStatusTimers.set(
      status,
      window.setTimeout(() => {
        status.classList.remove("is-visible");
        demoCopyStatusTimers.delete(status);
      }, 1600),
    );
  }
}

async function copyDemoCredential(trigger) {
  const text = trigger.getAttribute("data-demo-copy");
  const label = trigger.getAttribute("data-demo-copy-label") || "credential";

  if (!text) return;

  try {
    if (navigator.clipboard?.writeText) {
      await navigator.clipboard.writeText(text);
      flashDemoCopy(trigger, label);
    } else if (fallbackCopy(text)) {
      flashDemoCopy(trigger, label);
    }
  } catch (_error) {
    if (fallbackCopy(text)) {
      flashDemoCopy(trigger, label);
    }
  }
}

document.addEventListener("click", (event) => {
  const trigger = event.target.closest("[data-demo-copy]");
  if (!trigger) return;
  copyDemoCredential(trigger);
});

document.addEventListener("keydown", (event) => {
  if (event.key !== "Enter" && event.key !== " ") return;

  const trigger = event.target.closest("[data-demo-copy]");
  if (!trigger) return;

  event.preventDefault();
  copyDemoCredential(trigger);
});
