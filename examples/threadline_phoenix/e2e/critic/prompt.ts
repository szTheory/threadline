/**
 * prompt.ts — Three-strata cached prefix builder for the adversarial critic.
 *
 * Architecture (D-11):
 *   Stratum 1 — system prompt (frozen, shared across all lenses and all calls):
 *     Adversarial framing: role = adversarial critic, default verdict = FAIL,
 *     evidence law (CRITIC-05), judge gestalt only never re-measure, no praise.
 *
 *   Stratum 2 — cached prefix (per-lens, byte-stable per rubric_version):
 *     rubric/<lens>.md text + reference-bar prose + 2 pole exemplar IMAGES
 *     with cache_control:{type:"ephemeral"} on the LAST block (after pole images).
 *     Must exceed 4,096 tokens (Opus 4.8 cache floor — poles are load-bearing padding).
 *
 *   Stratum 3 — uncached suffix (per-call, volatile):
 *     target screenshot + mechanical evidence lines + aria snapshot (if any) +
 *     persona pass-condition clause (LAST — never in the cached prefix).
 *
 * Anti-patterns avoided:
 *   - Persona clause inside cached prefix (= 5× distinct prefixes, cache misses)
 *   - cache_control on every block (only LAST prefix block gets it)
 *   - Detail knob (Anthropic API has no detail parameter)
 *   - Date.now() or UUIDs in committed prefix text (cache invalidation)
 */

import { readFileSync, existsSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import type { ScorecardBundle } from "./bundle.js";
import type { LensName } from "./schema.js";

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(here, "../../../..");
const scorecardsDir = resolve(repoRoot, ".planning/scorecards");
const rubricDir = resolve(here, "rubrics");
const artifactsRoot = resolve(
  repoRoot,
  "examples/threadline_phoenix/e2e/artifacts/tier-a",
);

// Persona definitions (D-06): JTBD + pass-condition clause (goes in uncached suffix)
export const PERSONA_CLAUSES: Record<string, string> = {
  p1: `You are scoring this page for P1 — the Incident Responder on-call. Their primary task is: locate the exact actor, action, and timestamp for the alert they were paged about in under 60 seconds. Pass only if the primary audit event data achieves immediate visual dominance at cold glance, with no competing chrome delaying time-to-locate.`,
  p2: `You are scoring this page for P2 — the Compliance Reviewer preparing an audit artifact. Their primary task is: verify completeness of a compliance scope — every relevant row is present, properly attributed, and exportable. Pass only if the page's information hierarchy makes completeness self-evident without manual counting or re-reading.`,
  p3: `You are scoring this page for P3 — the Developer debugging a missing event. Their primary task is: prove a specific action either happened or did not happen, with enough context to identify the code path. Pass only if technical evidence (correlation ID, metadata, payload diff) is accessible and legible without navigating away.`,
  p4: `You are scoring this page for P4 — the Security Auditor validating the integrity of the audit trail. Their primary task is: confirm the audit record is tamper-evident and complete (no gaps, no anomalies in actor attribution, timestamps coherent). Pass only if the integrity signals (full attribution chain, timestamp ordering, change sequence) are visually inspectable at a glance.`,
  p5: `You are scoring this page for P5 — the Operator configuring audit scope and retention. Their primary task is: understand current configuration, change a setting, and confirm the change was applied. Pass only if the configuration state and the action affordances are colocated and unambiguous.`,
  all: `You are scoring this page on behalf of all operator personas. Apply the most demanding standard across all JTBDs: a page that serves one persona but fails another must FAIL this criterion unless the persona-specific trade-off is explicitly documented in the rubric.`,
};

// Frozen adversarial system prompt (shared across all lenses and all personas).
// DO NOT modify — any change invalidates the cache across all sessions.
export const FROZEN_ADVERSARIAL_SYSTEM_PROMPT = `You are an adversarial design critic for the Threadline audit platform operator UI.

Your role is to find failures, not to confirm passes. Your default verdict on every dimension is FAIL. You must actively attempt to fail each dimension before you may pass it. A finding that cannot be located in the screenshot or DOM is discarded — you may not assert a pass or fail without citing a specific region, CSS selector, or mechanical measurement line.

Core rules:
1. Evidence first, verdict second. For every dimension: locate the relevant element first, then pass or fail based on what you found. The evidence.locator field must be populated before you assign a score. A score without a located citation is invalid and will be rejected.
2. Judge gestalt only. The mechanical layer already validates pixel values, contrast ratios, token conformance, card nesting depth, and type size counts. You are not re-measuring pixels or re-running contrast math — you are judging whether the OUTCOME of those mechanical inputs reads as coherent, legible, and purposeful.
3. No praise. Do not validate, encourage, or approve design choices that are merely adequate. An adequate page is not an exemplary one. Reserve high scores for genuinely exceptional execution.
4. Cite the worst failure. If multiple elements fail the same criterion, cite the single most significant failure. Enumerating every instance is not required; finding the worst one is.
5. Personas are different objective functions. When you see a persona pass-condition clause in the message below, score against THAT persona's objective only — not a generic "good UI" standard.`.trim();

/**
 * Load a pole exemplar image as base64 PNG.
 * Poles are loaded from the committed scorecard artifact path.
 */
function loadPoleImage(cellId: string): string {
  const screenshotPath = resolve(artifactsRoot, cellId, "screenshot.png");
  if (!existsSync(screenshotPath)) {
    throw new Error(
      `Pole exemplar screenshot not found: ${screenshotPath}\n` +
        `The pole cell "${cellId}" must have a committed artifact.\n` +
        `Run \`npm run capture:tier-a\` to regenerate.`,
    );
  }
  return readFileSync(screenshotPath).toString("base64");
}

/**
 * Extract the anchor cell IDs from a rubric file.
 * Looks for "**Pass pole:**" and "**Fail pole:**" lines.
 */
function extractPoleIds(rubricText: string): { pass: string; fail: string } {
  const passMatch = rubricText.match(/\*\*Pass pole:\*\*\s*`([^`]+)`/);
  const failMatch = rubricText.match(/\*\*Fail pole:\*\*\s*`([^`]+)`/);
  if (!passMatch || !failMatch) {
    throw new Error(
      `Rubric is missing required anchor pole cell IDs.\n` +
        `Expected "**Pass pole:** \`cell_id\`" and "**Fail pole:** \`cell_id\`" lines.`,
    );
  }
  return { pass: passMatch[1], fail: failMatch[1] };
}

/**
 * Extract the reference bar section from a rubric file.
 */
function extractReferenceBar(rubricText: string): string {
  const match = rubricText.match(/## Reference bar\n([\s\S]*?)(?=\n##|\s*$)/);
  if (!match) return "";
  return match[1].trim();
}

export interface PromptStrata {
  system: string;
  messages: Array<{
    role: "user";
    content: Array<AnthropicContentBlock>;
  }>;
}

type AnthropicContentBlock =
  | { type: "text"; text: string; cache_control?: { type: "ephemeral" } }
  | {
      type: "image";
      source: { type: "base64"; media_type: "image/png"; data: string };
      cache_control?: { type: "ephemeral" };
    };

/**
 * Build the full three-strata prompt for one (lens, dimension, persona) call.
 *
 * @param lens - The critic lens (e.g. "hierarchy")
 * @param dimension - The rubric dimension name (e.g. "entry_point_clarity")
 * @param personaKey - Persona key ("p1".."p5" or "all")
 * @param bundle - The Tier-B scorecard bundle for this cell
 * @returns {system, messages} suitable for client.messages.parse()
 */
export function buildPrompt(
  lens: LensName,
  dimension: string,
  personaKey: string,
  bundle: ScorecardBundle,
): PromptStrata {
  // Load the rubric markdown for this lens
  const rubricPath = resolve(rubricDir, `${lens}.md`);
  if (!existsSync(rubricPath)) {
    throw new Error(`Rubric not found for lens "${lens}": ${rubricPath}`);
  }
  const rubricText = readFileSync(rubricPath, "utf8");

  // Extract pole cell IDs from the rubric
  const poles = extractPoleIds(rubricText);

  // Load pole images (load-bearing cache prefix padding — D-04 / D-05)
  // Poles MUST be in the cached prefix to pad above the 4,096-token floor.
  const passImage = loadPoleImage(poles.pass);
  const failImage = loadPoleImage(poles.fail);

  // Extract reference bar for the prefix
  const referenceBar = extractReferenceBar(rubricText);

  // Build the cached prefix text (lens-level, NOT persona-specific)
  const prefixText = [
    `# ${lens.charAt(0).toUpperCase() + lens.slice(1).replace("_", " ")} Rubric`,
    "",
    rubricText,
    "",
    "---",
    "",
    "## Reference Bar",
    "",
    referenceBar,
    "",
    "---",
    "",
    `## Pole Exemplars for ${lens}`,
    "",
    `The FIRST image above is the PASS pole (cell: \`${poles.pass}\`).`,
    `The SECOND image above is the FAIL pole (cell: \`${poles.fail}\`).`,
    "",
    `For this call you are scoring the DIMENSION: **${dimension}**`,
    "",
    "Only score the dimension named above. Do not cross-score other dimensions.",
  ].join("\n");

  // Build the uncached suffix (per-call, volatile: target screenshot + mechanical + persona)
  const personaClause =
    PERSONA_CLAUSES[personaKey] ??
    `You are scoring this page for persona "${personaKey}". Apply the most demanding standard.`;

  const mechanicalBlock =
    bundle.mechanicalLines.length > 0
      ? `## Mechanical Evidence Lines\n\n${bundle.mechanicalLines.map((l) => `- ${l}`).join("\n")}\n\nThese are the committed deterministic measurements for this cell. You may cite them as \`mechanical_line\` evidence.`
      : "";

  const ariaBlock = bundle.ariaSnapshot
    ? `## ARIA Snapshot\n\`\`\`\n${bundle.ariaSnapshot}\n\`\`\``
    : "";

  const suffixParts = [
    `## Target Cell: \`${bundle.cellId}\``,
    "",
    "(Target screenshot is attached as the last image.)",
    "",
    mechanicalBlock,
    ariaBlock,
    "",
    "---",
    "",
    "## Scoring context",
    "",
    personaClause,
  ].filter(Boolean).join("\n");

  // Assemble the content blocks:
  //
  // Cached prefix (byte-stable per rubric_version + poles):
  //   [pass-pole image] [fail-pole image] [prefix text with cache_control on LAST block]
  //
  // Uncached suffix (per-call volatile):
  //   [target screenshot] [suffix text]
  //
  // cache_control:{type:"ephemeral"} goes on the LAST block of the cached prefix (D-11).
  // The persona clause is LAST in the uncached suffix (D-11 anti-pattern 2 prevention).

  const content: AnthropicContentBlock[] = [
    // Pole images (load-bearing padding to exceed 4,096-token cache floor)
    {
      type: "image",
      source: { type: "base64", media_type: "image/png", data: passImage },
    },
    {
      type: "image",
      source: { type: "base64", media_type: "image/png", data: failImage },
    },
    // Rubric + reference-bar + pole anchor text — LAST cached prefix block gets cache_control
    {
      type: "text",
      text: prefixText,
      cache_control: { type: "ephemeral" },
    },
    // ↑ cache boundary — everything above is cached; everything below is uncached ↑
    // Target screenshot (uncached, per-call)
    {
      type: "image",
      source: {
        type: "base64",
        media_type: "image/png",
        data: bundle.screenshotBase64,
      },
    },
    // Mechanical evidence + aria + persona clause (uncached, per-call, persona LAST)
    {
      type: "text",
      text: suffixParts,
    },
  ];

  return {
    system: FROZEN_ADVERSARIAL_SYSTEM_PROMPT,
    messages: [{ role: "user", content }],
  };
}
