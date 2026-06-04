import { Socket } from "./phoenix.mjs";
import { LiveSocket } from "./phoenix_live_view.esm.js";

const csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute("content");

const liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
});

liveSocket.connect();

window.liveSocket = liveSocket;
window.Phoenix = { Socket };
