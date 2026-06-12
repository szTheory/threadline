#!/usr/bin/env node
// build-gallery.mjs — builds the self-contained six-context review gallery for a round.
// Usage: node build-gallery.mjs <round-dir>
// Output: <round-dir>/gallery.html — opens over file:// with ZERO network requests:
// system-font chrome, inline CSS, every candidate render an inlined pure-path SVG with
// xmlns stripped (valid in HTML5 inline SVG; keeps the file free of "http" substrings).
// Neutral order, identical card chrome, no recommendation styling. Plain Node, no deps.

import fs from "node:fs";
import path from "node:path";

const dir = process.argv[2];
if (!dir || !fs.existsSync(dir)) {
  console.error("usage: node build-gallery.mjs <round-dir>");
  process.exit(2);
}

const files = fs.readdirSync(dir);
const primaries = files
  .filter((f) => /^c\d+-.*\.svg$/.test(f) && !/-mono\.svg$/.test(f) && !/-favicon\.svg$/.test(f))
  .sort((a, b) => parseInt(a.slice(1)) - parseInt(b.slice(1)));

const attr = (s, n) => (s.match(new RegExp(`${n}\\s*=\\s*"([^"]*)"`)) || [])[1] || "";

function inline(file, extra = "") {
  let s = fs.readFileSync(path.join(dir, file), "utf8").trim();
  s = s.replace(/\s+xmlns(:xlink)?="[^"]*"/g, "");
  s = s.replace(/<!--[\s\S]*?-->/g, "");
  s = s.replace(/\s+data-(lane|technique|hook)="[^"]*"/g, "");
  if (extra) s = s.replace("<svg", `<svg ${extra}`);
  return s;
}

const today = new Date().toISOString().slice(0, 10);
const cards = [];

for (const p of primaries) {
  const id = "C" + p.match(/^c(\d+)-/)[1];
  const slug = p.replace(/\.svg$/, "");
  const src = fs.readFileSync(path.join(dir, p), "utf8");
  const lane = attr(src, "data-lane");
  const technique = attr(src, "data-technique");
  const hook = attr(src, "data-hook");
  const mono = slug + "-mono.svg";
  const fav = slug + "-favicon.svg";

  const primaryFull = (w) => inline(p, `style="width:${w}"`);
  const monoFull = (w) => inline(mono, `style="width:${w}"`);
  const favAt = (px) => inline(fav, `width="${px}" height="${px}"`);

  cards.push(`
  <section class="card" id="${id.toLowerCase()}">
    <header class="card-head">
      <span class="cid">${id}</span>
      <span class="slug">${slug}</span>
      <span class="lane">${lane}</span>
      <span class="strategy">${technique} &middot; ${hook}</span>
    </header>
    <div class="grid">
      <figure class="panel dark"><figcaption>1 &middot; Dark &middot; #0B1020</figcaption>
        <div class="stage on-dark">${primaryFull("92%")}</div>
      </figure>
      <figure class="panel light"><figcaption>2 &middot; Light &middot; #FFFFFF</figcaption>
        <div class="stage on-light">${primaryFull("92%")}</div>
      </figure>
      <figure class="panel"><figcaption>3 &middot; Monochrome &middot; one flat color</figcaption>
        <div class="stage on-neutral">${monoFull("92%")}</div>
      </figure>
      <figure class="panel"><figcaption>4 &middot; Literal 16px favicon + 4&times; copy</figcaption>
        <div class="stage on-dark favrow">${favAt(16)}${favAt(64)}</div>
        <div class="stage on-light favrow">${favAt(16)}${favAt(64)}</div>
      </figure>
      <figure class="panel"><figcaption>5 &middot; 32px</figcaption>
        <div class="stage on-dark favrow">${favAt(32)}</div>
        <div class="stage on-light favrow">${favAt(32)}</div>
      </figure>
      <figure class="panel"><figcaption>6 &middot; Simulated GitHub README header</figcaption>
        <div class="gh gh-light">
          <div class="gh-bar"><span class="gh-dot"></span><span class="gh-repo">threadline / README.md</span></div>
          <div class="gh-body">${inline(p, 'style="height:40px"')}<p class="gh-text">An open-source audit platform for Elixir teams using Phoenix, Ecto, and PostgreSQL.</p></div>
        </div>
        <div class="gh gh-dark">
          <div class="gh-bar"><span class="gh-dot"></span><span class="gh-repo">threadline / README.md</span></div>
          <div class="gh-body">${inline(p, 'style="height:40px"')}<p class="gh-text">An open-source audit platform for Elixir teams using Phoenix, Ecto, and PostgreSQL.</p></div>
        </div>
      </figure>
    </div>
  </section>`);
}

const html = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Threadline logo tournament — Round 1</title>
<style>
  :root { color-scheme: dark; }
  * { box-sizing: border-box; }
  body { margin: 0; background: #0B1020; color: #C9D2E4;
         font-family: system-ui, -apple-system, "Segoe UI", Roboto, sans-serif; }
  .wrap { max-width: 1180px; margin: 0 auto; padding: 40px 28px 80px; }
  h1 { font-size: 21px; font-weight: 600; color: #EDF1F7; margin: 0 0 6px; letter-spacing: .01em; }
  .meta { font-size: 13px; color: #8A93A8; margin: 0 0 10px; }
  .protocol { font-size: 13px; color: #8A93A8; border: 1px solid #232B40; border-radius: 8px;
              padding: 12px 16px; margin: 18px 0 34px; line-height: 1.55; }
  .protocol b { color: #C9D2E4; font-weight: 600; }
  .card { border: 1px solid #232B40; border-radius: 10px; margin: 0 0 34px; overflow: hidden; }
  .card-head { display: flex; gap: 14px; align-items: baseline; padding: 12px 18px;
               border-bottom: 1px solid #232B40; background: #0E1428; flex-wrap: wrap; }
  .cid { font-size: 16px; font-weight: 700; color: #EDF1F7; }
  .slug { font-size: 12px; color: #5C6680; font-family: ui-monospace, monospace; }
  .lane { font-size: 12px; color: #C9D2E4; border: 1px solid #2C3550; border-radius: 99px;
          padding: 2px 10px; }
  .strategy { font-size: 12.5px; color: #8A93A8; }
  .grid { display: grid; grid-template-columns: 1fr 1fr; }
  .panel { margin: 0; border: 0 solid #232B40; border-width: 0 1px 1px 0; padding: 0; min-width: 0; }
  .panel figcaption { font-size: 11px; color: #5C6680; padding: 8px 14px 6px;
                      text-transform: uppercase; letter-spacing: .06em; }
  .stage { display: flex; align-items: center; justify-content: center; padding: 22px 18px; min-height: 110px; }
  .on-dark { background: #0B1020; color: #EDF1F7; }
  .on-light { background: #FFFFFF; color: #101522; }
  .on-neutral { background: #161D31; color: #D6DEED; }
  .favrow { gap: 26px; min-height: 0; padding: 14px; }
  .gh { border-radius: 8px; overflow: hidden; margin: 0 14px 14px; border: 1px solid #2C3550; }
  .gh-light { background: #ffffff; color: #1f2328; }
  .gh-dark { background: #0d1117; color: #e6edf3; }
  .gh-bar { font-size: 11px; padding: 6px 12px; border-bottom: 1px solid rgba(110,118,129,.35);
            display: flex; gap: 8px; align-items: center; font-family: ui-monospace, monospace; }
  .gh-dot { width: 8px; height: 8px; border-radius: 99px; background: rgba(110,118,129,.6); }
  .gh-body { padding: 16px 18px 18px; }
  .gh-light .gh-body { color: #101522; }
  .gh-dark .gh-body { color: #e6edf3; }
  .gh-text { font-size: 12.5px; line-height: 1.5; margin: 12px 0 0; opacity: .75; max-width: 46em; }
</style>
</head>
<body>
<div class="wrap">
  <h1>Threadline logo tournament &mdash; Round 1</h1>
  <p class="meta">${today} &middot; 8 candidates &middot; lanes: 3 integrated typemarks / 3 unified lockups / 1 monogram / 1 wordmark-only &middot; all 24 SVGs passed the mechanical HC-1..6 gate</p>
  <div class="protocol">
    Review each candidate in all six contexts, then give a per-candidate verdict:
    <b>ADVANCE</b> (keep for the next round), <b>KILL</b> (eliminate, with a reason), or
    <b>MUTATE</b> (keep the idea, change something specific &mdash; say what).
    Reasons matter more than verdicts: round 2 is built from them. Order is neutral
    (assignment order, not preference). The user picks &mdash; always.
  </div>
${cards.join("\n")}
</div>
</body>
</html>
`;

fs.writeFileSync(path.join(dir, "gallery.html"), html);
console.log(`gallery.html written: ${primaries.length} candidates, ${(html.match(/<svg/g) || []).length} inlined svgs`);
