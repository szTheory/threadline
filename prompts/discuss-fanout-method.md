# Discuss fan-out method

How the maintainer wants every GSD decision point resolved, discuss-phase
included. Read it before you propose any architectural, API, UX, scope or
dependency choice. The rule summary lives in CLAUDE.md under "GSD / local
planning"; this file is the full method.

## Fan out per decision point

- Dispatch one deep researcher per decision cluster, all in parallel, and
  do it before any question reaches the maintainer.
- Keep enumerating decision points, including angles the roadmap did not
  name, until returns diminish.
- Give each researcher two things in its prompt:
  - **Reading:** `prompts/`, starting with the domain model and the OSS DNA.
    Read the newest brand book only when UI is in scope.
  - **Coherence:** the sibling decisions its answer has to fit with.

Each researcher covers breadth and depth.

- **Weighing.** Pros, cons and trade-offs, with concrete examples.
- **Patterns.** Patterns and anti-patterns, best practice, footguns, and
  lessons learned.
- **Prior art.** What peer libraries and products got right and wrong. Look
  in Elixir/Plug/Phoenix/Ecto first, then other languages and ecosystems
  where the comparison teaches something.
- **Lenses.** Every relevant stakeholder role, named for the domain:
  software architect, DevOps/SRE, security, release engineering, semver and
  API stability, product, DX, and design. Add any specialty the decision
  touches.
- **Adversarial pass.** Argue against the leading option before you
  recommend it.
- **UI/UX work.** For a UI/UX decision, focus on existing patterns,
  conventions, the principle of least surprise and elegant design. Don't get
  distracted beyond that.

## Sources

- Prefer reputable primary sources: official docs, upstream source code,
  release notes, maintainers' own writing.
- Research online when it adds insight.
- Think independently as well. Don't just collect opinions.

## Dependencies

"Another copy and paste is better than another dep." A small, flat
dependency tree is more secure and avoids pulling in abstractions the
project doesn't need. Add a dependency only when it is truly needed, and say
why.

## Synthesis

- Return one coherent, one-shot recommendation set across all decision
  points. Each pick must reinforce the others and the project's goals.
  Cross-decision coherence beats optimizing each decision alone.
- Give every pick its rationale and the trade-off it accepts, so the
  maintainer can read it once and override it if they choose.
- **Auto-follow the set.** Escalate to the maintainer only for a major,
  architect-level call where the research found no clear winner. Also hand
  over anything that needs secrets, spend, a Hex publish approval, or a
  scope cut.
