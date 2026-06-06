# Phase 153 Research: Verification + Closeout

## User Constraints

### Verification Scope

- **D-01:** Treat `BRAND-QA-02` as a milestone-level verification and closeout lane, not another revision pass.
- **D-02:** Re-run the concrete artifact checks already proven in Phase 150 and Phase 152: `brandbook/tokens.json` JSON parse, all brandbook SVG XML parse, direct-open `brandbook/index.html`, desktop/mobile browser screenshots, file-type inventory, binary exclusion, and total file-size discipline.
- **D-03:** Include the Phase 152 historical-frame scan or an equivalent copy-regression check so the final brandbook remains current brand truth rather than refresh/audit backstory.
- **D-04:** Browser evidence should use local file rendering for `brandbook/index.html`; do not introduce a build pipeline, hosting setup, bundler, external dependency, or image export batch just to verify the artifact.

### Closeout Record

- **D-05:** The closeout should explicitly state what v1.33 approves now: the reviewed brandbook direction, the light-surface primary logo role, and the targeted copy cleanup.
- **D-06:** The closeout should explicitly preserve deferred rollout items for future phases: root README rollout, HexDocs brand treatment, landing page, social-card PNG export, and legal/trademark review.
- **D-07:** Final evidence may reference temporary screenshots under `/tmp`; screenshots do not need to be committed unless a later public-surface phase requires durable raster outputs.

### Scope Boundaries

- **D-08:** Do not change `brandbook/` visuals unless verification finds a concrete blocker in the existing artifact set.
- **D-09:** Do not bridge `brandbook/` static tokens into runtime operator-surface tokens in this phase; the static brandbook token lane and runtime UI token lane remain separate.

### the agent's Discretion

- Choose exact verification command order and whether to reuse or refresh Phase 152 evidence paths, as long as the final verification record contains current-tree evidence.
- Choose whether Phase 153 needs a small PLAN file or can be planned as a verification-only closeout slice, as long as GSD artifacts stay internally consistent.

### Deferred Ideas

- Root README/GitHub brand rollout belongs to a future public rollout phase.
- HexDocs brand treatment belongs to a future docs/ExDoc phase after docs IA is stable.
- Landing page implementation belongs to a future information-architecture/content phase.
- Social-card PNG export should wait until a platform requires it.
- Legal/trademark clearance remains human-owned and outside GSD automation.

## Project Constraints

- No root `AGENTS.md` exists for this project, so there are no additional root-level agent directives for Phase 153. [VERIFIED: `find .. -name AGENTS.md -print`]
- No project-local `.codex/skills/` or `.agents/skills/` directories with `SKILL.md` files were found. [VERIFIED: `find .codex .agents -maxdepth 3 -type f -name SKILL.md`]
- Phase 153 is mapped to requirement `BRAND-QA-02`. [VERIFIED: `.planning/ROADMAP.md`; `.planning/REQUIREMENTS.md`]

## Standard Stack

- Use the existing shell-based verification stack: `jq`, `xmllint`, `agent-browser`, `file`, `wc`, and `rg`. These commands are available in the current environment. [VERIFIED: `command -v jq xmllint agent-browser file wc rg`]
- Do not add npm packages, a bundler, a web server, image export tooling, or a build pipeline for this phase. The brandbook is designed to open directly from disk. [VERIFIED: `153-CONTEXT.md`; `brandbook/README.md`]
- The current `brandbook/` artifact set is HTML, Markdown text, JSON, CSS, and SVG only. [VERIFIED: `find brandbook -type f -maxdepth 3 -print0 | xargs -0 file`]
- The current total `brandbook/` source size is `95512` bytes. [VERIFIED: `find brandbook -type f -maxdepth 3 -print | sort | xargs wc -c`]

## Architecture Patterns

- Plan Phase 153 as a verification-only closeout slice. The expected execution output is a current-tree `153-VERIFICATION.md` and any GSD closeout/status updates required by the workflow, not brandbook redesign work. [VERIFIED: `153-CONTEXT.md`; `152-SUMMARY.md`]
- Refresh evidence against the current working tree rather than relying only on Phase 150 or Phase 152 evidence. Prior evidence is a command template and comparison point. [VERIFIED: `150-VERIFICATION.md`; `152-VERIFICATION.md`]
- Keep browser evidence local-file based: open `file:///Users/jon/projects/threadline/brandbook/index.html` and capture desktop/mobile screenshots under `/tmp`. [VERIFIED: `150-VERIFICATION.md`; `152-VERIFICATION.md`; `153-CONTEXT.md`]
- Treat screenshots as evidence paths in the verification record, not committed binary outputs. [VERIFIED: `153-CONTEXT.md`; `brandbook/README.md`]
- Preserve static brand token and runtime operator token separation. The plan should not touch `lib/threadline/operator_surface/style.ex` or runtime UI token wiring. [VERIFIED: `153-CONTEXT.md`; `brandbook/README.md`]

## Validation Architecture

The planner should require one automated verification task that refreshes these checks and records exact command output in `153-VERIFICATION.md`.

| Check | Command pattern | Expected result |
|---|---|---|
| Token JSON parse | `jq empty brandbook/tokens.json && echo tokens-json-ok` | Exit 0 and `tokens-json-ok`. |
| SVG XML parse | `find brandbook -name '*.svg' -print0 | xargs -0 xmllint --noout && echo svg-xml-ok` | Exit 0 and `svg-xml-ok`. |
| HTML parser exit | `xmllint --html --noout brandbook/index.html; printf 'xmllint-html-exit=%s\n' $?` | Exit 0. Old parser warnings for HTML5 tags are acceptable if exit code is 0. |
| Historical-frame scan | `rg -n "original|refresh|before|rework|one-shot|reverted|v1\\.32|Phase|milestone|execution-incomplete|current brand direction|churn|pressure-tested|what changed|under-specified|lacked|needed|critical audit|tightened" brandbook` | No regression matches outside expected CSS selector text such as `::before`. |
| Binary exclusion | `find brandbook -type f \( -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' -o -name '*.pdf' -o -name '*.woff' -o -name '*.woff2' -o -name '.DS_Store' \) -print` | No output. |
| File types | `find brandbook -type f -maxdepth 3 -print0 | xargs -0 file` | HTML, ASCII text, JSON, and SVG only. |
| File size | `find brandbook -type f -maxdepth 3 -print | sort | xargs wc -c` | Total remains source-control friendly; current baseline is `95512 total` bytes. |
| Browser direct-open | `agent-browser open file:///Users/jon/projects/threadline/brandbook/index.html` | Opens with title `Threadline Brandbook`. |
| Desktop screenshot | `agent-browser set viewport 1440 1000`; `agent-browser screenshot /tmp/threadline-v133-brandbook-phase153-desktop.png` | Screenshot saved. |
| Mobile screenshot | `agent-browser set viewport 390 844`; `agent-browser screenshot /tmp/threadline-v133-brandbook-phase153-mobile.png` | Screenshot saved. |

## Closeout Evidence Requirements

- The verification record must explicitly mark `BRAND-QA-02` as satisfied only if JSON parsing, SVG parsing, direct-open HTML rendering, desktop/mobile screenshot evidence, file-type boundaries, and file-size discipline pass. [VERIFIED: `.planning/REQUIREMENTS.md`; `.planning/ROADMAP.md`]
- The closeout record must state that v1.33 approves the reviewed brandbook direction, the `logo-primary-light.svg` role for README/GitHub/light docs, and the Phase 152 targeted copy cleanup. [VERIFIED: `153-CONTEXT.md`; `150-REVIEW-PACKET.md`; `152-SUMMARY.md`]
- The closeout record must preserve future rollout items: root README rollout, HexDocs brand treatment, landing page, social-card PNG export, and legal/trademark review. [VERIFIED: `153-CONTEXT.md`; `.planning/REQUIREMENTS.md`]

## Don't Hand-Roll

- Do not write a custom parser for JSON, SVG, HTML, or file type detection; use `jq`, `xmllint`, and `file`. [VERIFIED: prior phase command evidence]
- Do not create a screenshot/export pipeline; use `agent-browser` directly and keep screenshots in `/tmp`. [VERIFIED: `150-VERIFICATION.md`; `152-VERIFICATION.md`]
- Do not create public README, HexDocs, landing page, runtime UI, token bridge, alternate logo concept, or legal/trademark artifacts in Phase 153. [VERIFIED: `153-CONTEXT.md`; `.planning/REQUIREMENTS.md`]

## Common Pitfalls

- `xmllint --html` may print warnings for modern HTML5 elements while still exiting 0; the exit code is the meaningful pass/fail signal for the existing brandbook check. [VERIFIED: `150-VERIFICATION.md`; `152-VERIFICATION.md`]
- Zsh can fail unmatched globs; use `find ... -print0 | xargs -0 ...` for artifact inventory and parser checks. [VERIFIED: local shell behavior during UI-SPEC probe]
- The historical-frame scan from Phase 152 can match CSS `::before`; classify expected selector matches separately instead of treating them as copy regressions. [VERIFIED: `152-VERIFICATION.md`]
- Do not interpret "desktop/mobile screenshots" as a requirement to commit PNGs. Phase context explicitly allows `/tmp` evidence paths. [VERIFIED: `153-CONTEXT.md`]
- The plan-phase UI detector flags this phase because the roadmap mentions screenshots and review surfaces. That is a workflow gate issue, not evidence that Phase 153 should redesign UI. If planning continues without a UI design contract, rerun with `--skip-ui` so the plan remains verification-only. [VERIFIED: `gsd-sdk query roadmap.get-phase 153 | grep -iE ...`; no `153-UI-SPEC.md`]

## Security Domain

- Phase 153 does not add runtime code, network endpoints, authentication flows, database writes, or external services. [VERIFIED: `153-CONTEXT.md`; `.planning/ROADMAP.md`]
- The main security-relevant risk is evidence integrity: the final record must cite current-tree command output and must not approve deferred public-surface or legal/trademark work. [VERIFIED: `153-CONTEXT.md`; `.planning/REQUIREMENTS.md`]
- A planner threat model can mark application threats as not applicable while still naming tampering/misrepresentation risks for the closeout evidence. [ASSUMED]

## Confidence Summary

- HIGH confidence: required command set, current artifact inventory, prior evidence patterns, scope boundaries, and closeout requirements. These are all grounded in current repository artifacts and local command checks.
- MEDIUM confidence: exact final closeout file shape, because GSD workflow conventions may decide whether closeout lives only in `153-VERIFICATION.md`, `153-SUMMARY.md`, or additional milestone archive artifacts.
- LOW confidence: none identified for planning Phase 153. No external dependency or current third-party API behavior is needed.

