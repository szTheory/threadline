/**
 * label_web.ts — Local web labeling surface for the golden-set oracle.
 *
 * A standalone Node http server (no Phoenix, no new deps) that reads the committed
 * queue + round files and on-disk screenshots and serves ONE always-current, clean
 * image at a time with verdict buttons + a required evidence field. Solves the
 * external-viewer confusion of the keystroke CLI (you always see the current image).
 *
 * Masking is preserved: the browser only ever sees an opaque token; token→cell_id
 * mapping stays server-side. Round files are written in the same shape the keystroke
 * CLI uses, so `--reconcile` reads them unchanged. Blind r2 holds by construction —
 * this server reads only the queue + the current round file, never r1 during r2.
 */

import { createServer, IncomingMessage, ServerResponse } from "node:http";
import { existsSync, readFileSync, mkdirSync } from "node:fs";
import { resolve } from "node:path";
import { execFileSync } from "node:child_process";
import type { LensName } from "./schema.js";
import {
  atomicWriteFile,
  DEFAULT_OPERATOR_SURFACE_PATHS,
  readRequiredJson,
  resolveContainedPath,
} from "../support/operator-surface-paths.js";

const repoRoot = DEFAULT_OPERATOR_SURFACE_PATHS.repositoryRoot;
const goldenDir = DEFAULT_OPERATOR_SURFACE_PATHS.goldenDir;
const scorecardsDir = DEFAULT_OPERATOR_SURFACE_PATHS.scorecardsDir;
const queuePath = resolve(goldenDir, "queue.json");
const roundPath = (round: "r1" | "r2") => resolve(goldenDir, "rounds", `${round}.json`);

interface QueueItem {
  id: string;
  cell_id: string;
  lens: LensName;
  kind: "single" | "pair";
  pair_with: string | null;
}
interface QueueFile { items: QueueItem[] }
interface RoundItem {
  queue_id: string;
  token: string;
  cell_id: string;
  lens: LensName;
  kind: "single" | "pair";
  pair_with: string | null;
  pair_with_token: string | null;
  verdict: string;
  margin?: "clear" | "subtle";
  evidence: string;
  labeled_at: string;
}
interface RoundFile {
  round: "r1" | "r2";
  completed: boolean;
  completed_at: string | null;
  items: RoundItem[];
}

// Per-lens plain-English guidance (kept in sync with label.ts LENS_GUIDE).
const LENS_GUIDE: Record<LensName, { q: string; good: string; bad: string }> = {
  hierarchy: { q: "does your eye land on one main content thing first?", good: "one clear anchor; the eye knows where to go", bad: "two+ things fight, or chrome (nav/filter) is loudest" },
  density: { q: "is the real data prominent — not buried in chrome or self-describing copy?", good: "the data speaks for itself; the primary task stands out", bad: "clutter / explanatory copy / chrome drowns the task" },
  rhythm: { q: "are related things grouped, with even, consistent spacing?", good: "consistent vertical rhythm; clear grouping by proximity", bad: "uneven gaps; unrelated things crammed or scattered" },
  typography: { q: "are text roles clearly distinct, and does size match importance?", good: "heading / body / label clearly differ; size tracks importance", bad: "everything similar weight & size; size doesn't signal importance" },
  color_contrast: { q: "is color a meaningful signal, accent reserved for its job, and readable?", good: "color means something; accent used sparingly; good contrast", bad: "decorative / random color; accent overused; low contrast" },
  brand_fidelity: { q: "does it feel designed in a terse, operational voice — not generically recolored?", good: "intentional design; precise, operational copy", bad: "generic / recolored; chatty, vague, or apologetic copy" },
};

const readJson = <T>(p: string): T => readRequiredJson<T>(p, {
  dataset: "critic web-label evidence",
  repositoryOnly: true,
  recoveryCommand: "npm run critic:label -- --bootstrap",
});
const writeJson = (p: string, v: unknown) => atomicWriteFile(p, `${JSON.stringify(v, null, 2)}\n`);
const esc = (s: string) => s.replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c] as string));

function screenshotPathFor(cellId: string): string | null {
  const sc = resolve(scorecardsDir, `${cellId}.json`);
  if (!existsSync(sc)) return null;
  const rel = (readJson<{ artifacts?: { screenshot?: string } }>(sc).artifacts || {}).screenshot;
  if (!rel) return null;
  const abs = resolveContainedPath(repoRoot, rel);
  return existsSync(abs) ? abs : null;
}

function consumedTokenCount(items: RoundItem[]): number {
  return items.reduce((count, item) => count + (item.kind === "pair" ? 2 : 1), 0);
}

export async function startWebLabeling(round: "r1" | "r2", pairs: boolean, lens?: LensName): Promise<void> {
  if (!existsSync(queuePath)) {
    console.error("[critic label --web] No queue.json. Run `npm run critic:label -- --bootstrap` first.");
    process.exit(1);
  }
  const queue = readJson<QueueFile>(queuePath);
  mkdirSync(resolve(goldenDir, "rounds"), { recursive: true });
  const rp = roundPath(round);
  const roundFile: RoundFile = existsSync(rp)
    ? readJson<RoundFile>(rp)
    : { round, completed: false, completed_at: null, items: [] };

  // Remaining queue items (respect --lens / --pairs filters, skip already-labeled).
  const labeled = new Set(roundFile.items.map((i) => i.queue_id));
  let remaining = queue.items.filter((q) => {
    if (labeled.has(q.id)) return false;
    if (lens && q.lens !== lens) return false;
    if ((q.kind === "pair") !== pairs) return false;
    return true;
  });

  if (remaining.length > 0) {
    roundFile.completed = false;
    roundFile.completed_at = null;
  }

  for (const item of remaining) {
    if (item.kind === "pair" && (!item.pair_with || item.pair_with === item.cell_id)) {
      throw new Error(`Invalid pair queue item: ${item.id}`);
    }
  }
  const total = remaining.length + roundFile.items.length;

  // Tokens identify both sides without exposing either scorecard cell ID.
  const tokenAt = (index: number) =>
    `${round === "r1" ? "A" : "B"}${String(index + 1).padStart(3, "0")}`;

  const currentTokens = () => {
    const primary = tokenAt(consumedTokenCount(roundFile.items));
    const pair = remaining[0]?.kind === "pair"
      ? tokenAt(consumedTokenCount(roundFile.items) + 1)
      : null;
    return { primary, pair };
  };

  const port = 4399;

  const server = createServer((req: IncomingMessage, res: ServerResponse) => {
    const url = new URL(req.url || "/", `http://127.0.0.1:${port}`);

    // Image route — map token→cell_id server-side; browser never sees the cell id.
    if (url.pathname.startsWith("/img/")) {
      const token = url.pathname.slice(5);
      const q = remaining[0];
      const tokens = currentTokens();
      const cellId = token === tokens.primary
        ? q?.cell_id
        : token === tokens.pair
          ? q?.pair_with
          : null;
      if (!cellId) { res.writeHead(404).end(); return; }
      const p = screenshotPathFor(cellId);
      if (!p) { res.writeHead(404).end("no screenshot"); return; }
      res.writeHead(200, { "Content-Type": "image/png", "Cache-Control": "no-store" });
      res.end(readFileSync(p));
      return;
    }

    if (req.method === "POST" && url.pathname === "/verdict") {
      let body = "";
      req.on("data", (c) => (body += c));
      req.on("end", () => {
        const form = new URLSearchParams(body);
        const verdict = form.get("verdict") || "";
        const evidence = (form.get("evidence") || "").trim();
        const margin = form.get("margin") || undefined;
        const q = remaining[0];
        const pairItem = q?.kind === "pair";
        const validVerdict = pairItem
          ? verdict === "better" || verdict === "worse"
          : ["good", "borderline", "bad", "broken"].includes(verdict);
        const validMargin = !pairItem || margin === "clear" || margin === "subtle";
        if (q && validVerdict && validMargin && evidence) {
          const tokens = currentTokens();
          roundFile.items.push({
            queue_id: q.id, token: tokens.primary, cell_id: q.cell_id, lens: q.lens,
            kind: q.kind, pair_with: q.pair_with, pair_with_token: tokens.pair, verdict,
            ...(margin ? { margin: margin as "clear" | "subtle" } : {}),
            evidence, labeled_at: new Date().toISOString(),
          });
          writeJson(rp, roundFile); // save-after-each
          remaining = remaining.slice(1);
        }
        res.writeHead(303, { Location: "/" }).end();
      });
      return;
    }

    // Current-item page (or done page).
    res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
    if (remaining.length === 0) {
      roundFile.completed = true;
      roundFile.completed_at = new Date().toISOString();
      writeJson(rp, roundFile);
      const next = round === "r1"
        ? `Commit r1, then run: npm run critic:label -- --round r2${pairs ? " --pairs" : ""} --web`
        : "Run: npm run critic:label -- --reconcile";
      res.end(`<!doctype html><meta charset=utf-8><body style="font:16px system-ui;background:#0b0b0d;color:#e7e7ea;padding:3rem">
        <h1>Round ${round.toUpperCase()} complete</h1><p>${roundFile.items.length} items labeled.</p>
        <p>Next: <code>${esc(next)}</code></p><p>You can close this tab (Ctrl+C in the terminal to stop the server).</p></body>`);
      return;
    }
    const q = remaining[0];
    const done = roundFile.items.length;
    const g = LENS_GUIDE[q.lens];
    const tokens = currentTokens();
    const buttons = q.kind === "pair"
      ? `<button name=verdict value=better data-k=b>b · LEFT better</button><button name=verdict value=worse data-k=w>w · LEFT worse</button>`
      : `<button name=verdict value=good data-k=g>g · good</button><button name=verdict value=borderline data-k=o>o · borderline</button><button name=verdict value=bad data-k=a>a · bad</button><button name=verdict value=broken data-k=x>x · broken</button>`;
    const images = q.kind === "pair" && tokens.pair
      ? `<div style="display:grid;grid-template-columns:1fr 1fr;gap:16px;width:100%">
          <figure><figcaption>LEFT · ${tokens.primary}</figcaption><img src="/img/${tokens.primary}" alt="left comparison" style="max-width:100%;border:1px solid #2a2a30;border-radius:8px"></figure>
          <figure><figcaption>RIGHT · ${tokens.pair}</figcaption><img src="/img/${tokens.pair}" alt="right comparison" style="max-width:100%;border:1px solid #2a2a30;border-radius:8px"></figure>
        </div>`
      : `<img src="/img/${tokens.primary}" alt="story" style="max-width:100%;border:1px solid #2a2a30;border-radius:8px">`;
    const guide = q.kind === "pair"
      ? `<li><b>better</b> — LEFT serves this lens better than RIGHT</li><li><b>worse</b> — LEFT is weaker than RIGHT</li>`
      : `<li><b>good</b> — ${esc(g.good)}</li>
      <li><b>borderline</b> — mostly there, one notable flaw</li>
      <li><b>bad</b> — ${esc(g.bad)}</li>
      <li><b>broken</b> — empty / error / unusable / can't tell</li>`;
    res.end(`<!doctype html><meta charset=utf-8><title>critic label ${round}</title>
<body style="font:16px system-ui;background:#0b0b0d;color:#e7e7ea;margin:0;display:grid;grid-template-columns:minmax(320px,1fr) 420px;height:100vh">
  <div style="overflow:auto;background:#141418;display:flex;align-items:flex-start;justify-content:center;padding:24px">
    ${images}
  </div>
  <form method=post action=/verdict style="padding:28px 26px;overflow:auto">
    <div style="color:#8a8a93">${done}/${total} · Token ${tokens.primary}${tokens.pair ? ` vs ${tokens.pair}` : ""} · ${q.kind}</div>
    <h1 style="margin:.3em 0;text-transform:uppercase;letter-spacing:.04em">${q.lens}</h1>
    <p style="font-size:1.05em">${esc(g.q)}</p>
    <ul style="line-height:1.6;color:#c7c7cf">
      ${guide}
    </ul>
    <p style="color:#8a8a93">Glance ~2s, trust your gut, pick one — then a few words.</p>
    <div id=btns style="display:flex;flex-wrap:wrap;gap:8px;margin:12px 0">${buttons}</div>
    ${q.kind === "pair" ? `<div style="margin:8px 0">Margin: <label><input type=radio name=margin value=clear checked> clear</label> <label><input type=radio name=margin value=subtle> subtle</label></div>` : ""}
    <input name=evidence required autofocus placeholder='what you saw (e.g. "eye hit the big action row")' style="width:100%;padding:10px;margin-top:8px;background:#1c1c22;color:#fff;border:1px solid #33333a;border-radius:6px">
    <p style="color:#8a8a93;font-size:.85em">Keys: ${q.kind === "pair" ? "b/w then Enter" : "g/o/a/x"} then Enter · Ctrl+C in terminal = stop (saved)</p>
  </form>
  <style>button{font:15px system-ui;padding:10px 14px;background:#23232a;color:#e7e7ea;border:1px solid #3a3a42;border-radius:8px;cursor:pointer}button:hover{background:#2e2e37}input:invalid{border-color:#7a3b3b}</style>
  <script>
    const f=document.forms[0]; let v='';
    document.querySelectorAll('#btns button').forEach(b=>b.addEventListener('click',e=>{v=b.value;}));
    document.addEventListener('keydown',e=>{
      if(e.target.tagName==='INPUT'&&e.key!=='Enter')return;
      const map=${q.kind === "pair" ? "{b:'better',w:'worse'}" : "{g:'good',o:'borderline',a:'bad',x:'broken'}"};
      if(map[e.key]){v=map[e.key];const el=document.querySelector('input[name=evidence]');el.focus();}
      if(e.key==='Enter'){const ev=document.querySelector('input[name=evidence]');if(!v){alert('Pick a verdict first (a key or a button).');e.preventDefault();return;}if(!ev.value.trim()){ev.focus();e.preventDefault();return;}
        const h=document.createElement('input');h.type='hidden';h.name='verdict';h.value=v;f.appendChild(h);f.submit();}
    });
  </script>
</body>`);
  });

  server.listen(port, "127.0.0.1", () => {
    const uri = `http://127.0.0.1:${port}`;
    console.log(`\n[critic label --web] Round ${round.toUpperCase()} — ${remaining.length} items to label`);
    console.log(`  Open: ${uri}   (Ctrl+C to stop — progress saves after every item)\n`);
    try { execFileSync("open", [uri], { stdio: "ignore" }); } catch { /* print-only */ }
  });
}
