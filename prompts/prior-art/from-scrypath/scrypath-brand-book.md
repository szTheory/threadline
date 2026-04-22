One important update before the book: exact-match web search shows an existing public brand called Scrypath at scrypath.com, positioned as a career-discovery product, so the name is not cleanly distinct on the open web. Searchkick still frames itself as “Intelligent search made easy,” Meilisearch’s official SDK page still does not list Elixir among its official client SDKs, and Typesense says its REST API can be used from any HTTP library even when no listed client exists. That means your strongest differentiation is not “another search client,” but the Ecto-native orchestration layer for search.  ￼

So: below is the full brand book assuming you still want to explore Scrypath as the working brand. My recommendation is to pair the name with a descriptor almost everywhere in public, such as “Scrypath for Phoenix & Ecto” or “Scrypath, Ecto-native search indexing.”

Phoenix’s official positioning emphasizes shipping rich apps with fewer moving parts, Ecto centers repos, schemas, queries, and changesets, and Oban explicitly emphasizes reliability, consistency, and observability. Those are the ecosystem signals Scrypath should inherit.  ￼

Scrypath brand book

Version: v1
Category: Open-source Elixir/Phoenix developer tool
Positioning: Ecto-native search indexing and search orchestration
Brand posture: open-source, trustworthy, technical, calm, slightly arcane, never gimmicky

⸻

1. Brand core

Brand idea

Scrypath makes search indexing feel native to Ecto.

The brand should communicate:
	•	declarative schemas
	•	clean sync paths from database to index
	•	reliability under change
	•	observability and control
	•	adapter flexibility across engines
	•	Phoenix-native developer happiness

Core metaphor

The brand metaphor is wayfinding through data.

Not “AI magic,” not “futuristic intelligence,” not “search engine company.”
Scrypath is about:
	•	seeing the path a record takes
	•	making index sync legible
	•	turning data changes into predictable search state
	•	revealing hidden structure without drama

“Scry” gives it a subtle sense of perception. “Path” grounds it in systems, routes, and data flow. The balance matters.

Brand promise

Declarative search, observable sync, dependable results.

Brand values
	1.	Native
Search belongs beside schemas and changesets, not in a separate universe.
	2.	Legible
Index state, sync behavior, and reindex operations should be understandable.
	3.	Dependable
Search sync should survive production reality: retries, queueing, backfills, and failures.
	4.	Composable
Adapters, schema declarations, query builders, and jobs should fit together cleanly.
	5.	Reserved
The tool should feel powerful without sounding loud.

Audience

Primary audience:
	•	Elixir/Phoenix engineers
	•	solo founders building SaaS in Phoenix
	•	teams that want Rails-grade ergonomics in the BEAM ecosystem
	•	developers who prefer operational clarity over magic

Secondary audience:
	•	maintainers evaluating search engine integrations
	•	platform engineers standardizing search indexing across apps
	•	teams moving from raw HTTP clients to higher-level abstractions

⸻

2. Positioning

One-line positioning

Scrypath is the Ecto-native search indexing library for Phoenix applications.

Expanded positioning

Scrypath connects Ecto schemas, changesets, and background jobs to modern search engines in a way that feels like part of the Elixir stack, not an external bolt-on.

What Scrypath is
	•	Ecto-native
	•	search-indexing-focused
	•	queue-aware
	•	adapter-driven
	•	documentation-heavy
	•	practical and production-minded

What Scrypath is not
	•	not an AI product
	•	not a vector database brand
	•	not a hosted SaaS company
	•	not a literal search engine
	•	not “mystical” in a fantasy sense
	•	not a glossy enterprise platform

Category language to use

Use:
	•	Ecto-native search indexing
	•	schema-integrated search
	•	adapter-based search sync
	•	declarative indexing
	•	search orchestration for Phoenix
	•	searchable schemas

Avoid:
	•	AI search platform
	•	knowledge engine
	•	intelligent data fabric
	•	cognitive search
	•	next-gen discovery layer
	•	enterprise relevance platform

⸻

3. Naming rules

Canonical name

Scrypath

Always one word.
Prefer title case in prose: Scrypath
Prefer lowercase in package/repo contexts: scrypath

Public descriptor

Because of name collision risk, use a descriptor in the first mention on every public page:

Preferred first-mention formats:
	•	Scrypath, the Ecto-native search indexing library
	•	Scrypath for Phoenix & Ecto
	•	Scrypath: declarative search indexing for Phoenix apps

Recommended package naming

Use explicit package names to reduce ambiguity:
	•	scrypath_ecto
	•	scrypath_search
	•	scrypath_meilisearch
	•	scrypath_typesense

Recommended module naming

Keep modules plain and practical:
	•	Scrypath
	•	Scrypath.Schema
	•	Scrypath.Index
	•	Scrypath.Search
	•	Scrypath.Sync
	•	Scrypath.Reindex
	•	Scrypath.Adapter.Meilisearch
	•	Scrypath.Adapter.Typesense
	•	Scrypath.MultiTenant

Avoid public API names like:
	•	Scrypath.Oracle
	•	Scrypath.Prophecy
	•	Scrypath.Grimoire
	•	Scrypath.Seer

The brand can carry a subtle mythic tone; the API should stay clear and literal.

⸻

4. Tagline system

Primary tagline

Search indexing that feels native to Ecto.

Secondary taglines
	•	Declarative search paths for Phoenix apps
	•	From schema changes to searchable records
	•	Reliable search sync for the Elixir stack
	•	Search orchestration for Ecto-backed apps
	•	Index with intent

Boilerplate project description

Scrypath is an open-source Elixir library for declarative, Ecto-native search indexing with adapter support for engines like Meilisearch and Typesense.

⸻

5. Brand personality and voice

Personality

Scrypath should sound:
	•	calm
	•	exact
	•	capable
	•	technical
	•	generous
	•	slightly enigmatic
	•	never theatrical

Tone sliders
	•	Formality: medium
	•	Warmth: medium
	•	Confidence: high
	•	Playfulness: low
	•	Mysticism: low but present as texture
	•	Marketing energy: low

Voice principles
	1.	Explain, don’t hype
	2.	Be specific
	3.	Assume engineering literacy
	4.	Sound composed under complexity
	5.	Prefer clarity over cleverness
	6.	Use metaphor sparingly

Brand voice examples

Good:
	•	“Declare searchable fields on your schema and let Scrypath keep the index in sync.”
	•	“Reindexing is a first-class workflow, not a migration-era panic.”
	•	“Adapters keep your indexing layer portable.”
	•	“Observe sync behavior, recover cleanly, move on.”

Bad:
	•	“Magical search for the modern AI era”
	•	“Unlock revolutionary relevance”
	•	“Supercharge your data discovery journey”
	•	“Next-generation cognitive indexing”

Vocabulary to favor
	•	schema
	•	sync
	•	path
	•	adapter
	•	index
	•	queue
	•	reindex
	•	backfill
	•	retry
	•	observe
	•	changeset
	•	tenant
	•	compose
	•	reliable
	•	native
	•	declarative

Vocabulary to avoid
	•	magic
	•	wizardry
	•	revolution
	•	disrupt
	•	AI-powered
	•	cutting-edge
	•	game-changing
	•	seamless everywhere
	•	enterprise-grade unless literally substantiated

⸻

6. Visual identity

6.1 Visual concept

Scrypath’s visual system should feel like:
	•	dark editors at 2 a.m.
	•	calm system diagrams
	•	map routes
	•	index topology
	•	instrument panels
	•	precise linework

It should not feel like:
	•	generic SaaS gradients
	•	bright search startup branding
	•	cyberpunk neon
	•	fantasy occultism
	•	database vendor dashboards
	•	“AI cloud” visuals

Core visual metaphor

A visible path through hidden structure.

Represent that through:
	•	routed lines
	•	nodes
	•	branching but orderly diagrams
	•	field-to-index maps
	•	directional movement
	•	quiet glow, not loud glow

⸻

6.2 Logo direction

Logo concept

The mark should be built around an S-shaped route or curved path with nodes, not a literal eye and not a magnifying glass.

Preferred symbol directions
	1.	Path-S monogram
An abstract S formed by a routed line moving through 2–3 node points.
	2.	Index trace mark
A single line bending through a structured grid, suggesting source-to-index movement.
	3.	Waypoint glyph
A small route map icon that can sit beside the wordmark.

Wordmark feel
	•	geometric but not sterile
	•	slightly custom terminals
	•	open counters
	•	subtly widened rhythm
	•	no sharp blackletter or fantasy cues

Forbidden logo motifs
	•	magnifying glass
	•	eyeball
	•	crystal ball
	•	flame/phoenix illustration
	•	database cylinder
	•	literal maze
	•	AI starburst
	•	orbital ring cliché

Logo usage rule

If using the standalone mark, keep it simple enough to render at:
	•	favicon size
	•	GitHub social preview size
	•	Hex package listing scale
	•	docs navbar scale

⸻

6.3 Color system

The palette should be distinct from common search-tool blues and greens. Scrypath’s signature is violet + copper over deep midnight neutrals.

Primary palette
	•	Night #0C0F14 — primary dark background
	•	Ink #141923 — surface
	•	Slate #2A3446 — border / structure
	•	Mist #B3BDCF — muted text on dark
	•	Paper #F4F1EA — primary text on dark / warm light neutral
	•	Violet 600 #5B4AD1 — primary action
	•	Violet 500 #6C5CE7 — primary accent / link / glow
	•	Copper 500 #C17A3E — secondary accent
	•	Copper 600 #A85D2E — darker copper for light theme / emphasis

Semantic support colors
	•	Success #4FAE74
	•	Info #5CA9E6
	•	Warning #D9A441
	•	Danger #D96262

Light theme neutrals
	•	Canvas #FAF7F2
	•	Panel #F2EEE7
	•	Panel Raised #EAE4DA
	•	Line Light #D7D0C4
	•	Text Dark #111522
	•	Text Muted Dark #475066

Brand color behavior
	•	Use Night/Ink as the default marketing background.
	•	Use Paper for major typography on dark surfaces.
	•	Use Violet 600 for CTAs and active states.
	•	Use Copper 500 sparingly for highlights, key diagrams, badges, and callouts.
	•	Use semantic colors only for status, not as core brand accents.

Color ratio

Suggested balance:
	•	65% neutrals
	•	20% dark structures
	•	10% violet
	•	5% copper

Gradient rule

Allowed gradient:
	•	linear-gradient(135deg, #5B4AD1 0%, #6C5CE7 55%, #C17A3E 100%)

Use only for:
	•	hero highlight lines
	•	social cards
	•	diagram emphasis
	•	subtle hover glows

Do not use for:
	•	body text
	•	large background floods
	•	data visualizations by default

Accessibility rule

Default to strong contrast. Use Violet 600 for filled buttons with light text; use Copper 500 with dark text on filled elements. Never put small muted text on textured backgrounds.

Machine-readable token block

:root {
  --sp-bg: #FAF7F2;
  --sp-surface: #F2EEE7;
  --sp-surface-2: #EAE4DA;
  --sp-border: #D7D0C4;

  --sp-text: #111522;
  --sp-text-muted: #475066;
  --sp-text-soft: #6B7388;

  --sp-primary: #5B4AD1;
  --sp-primary-2: #6C5CE7;
  --sp-accent: #A85D2E;
  --sp-accent-2: #C17A3E;

  --sp-success: #4FAE74;
  --sp-info: #5CA9E6;
  --sp-warning: #D9A441;
  --sp-danger: #D96262;
}

[data-theme="dark"] {
  --sp-bg: #0C0F14;
  --sp-surface: #141923;
  --sp-surface-2: #1B2230;
  --sp-border: #2A3446;

  --sp-text: #F4F1EA;
  --sp-text-muted: #B3BDCF;
  --sp-text-soft: #7F8AA3;

  --sp-primary: #5B4AD1;
  --sp-primary-2: #6C5CE7;
  --sp-accent: #C17A3E;
  --sp-accent-2: #E0B487;

  --sp-success: #4FAE74;
  --sp-info: #5CA9E6;
  --sp-warning: #D9A441;
  --sp-danger: #D96262;
}


⸻

6.4 Typography

The recommended stack is Space Grotesk for display, Inter for body/UI, IBM Plex Mono for code. Inter is explicitly designed as a screen-first workhorse, Space Grotesk keeps the character of Space Mono while improving readability as a proportional sans, and IBM Plex is open source and designed for UI environments.  ￼

Typography roles

Display / hero / major headings: Space Grotesk
Body / UI / docs prose: Inter
Code / CLI / config / snippets: IBM Plex Mono

Why this works
	•	Space Grotesk gives Scrypath personality without looking whimsical
	•	Inter keeps docs and product UI extremely readable
	•	IBM Plex Mono makes code feel engineered, not decorative

Recommended weights
	•	Space Grotesk: 500, 700
	•	Inter: 400, 500, 600
	•	IBM Plex Mono: 400, 500

Type rules
	•	Use sentence case for almost everything
	•	Avoid full uppercase headlines
	•	Use tabular numerals in code blocks, metrics, benchmark charts, badges
	•	Keep code size slightly smaller than body but with more line height
	•	Do not condense tracking aggressively

Suggested type scale
	•	12 / 14 / 16 / 18 / 20 / 24 / 32 / 40 / 56 / 72

Line-height guidance
	•	Hero: 1.0–1.1
	•	Headings: 1.1–1.2
	•	Body: 1.5–1.65
	•	Code: 1.45–1.6

Fallback stacks

Display: "Space Grotesk", Inter, system-ui, sans-serif
Body: Inter, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif
Mono: "IBM Plex Mono", "SFMono-Regular", Consolas, "Liberation Mono", monospace


⸻

6.5 Layout, spacing, shape

Grid
	•	Desktop: 12 columns
	•	Tablet: 8 columns
	•	Mobile: 4 columns

Spacing scale

Use an 8px base:
	•	4, 8, 12, 16, 24, 32, 40, 48, 64, 80, 96

Corner radius
	•	Inputs: 12px
	•	Cards: 16px
	•	Feature panels / hero blocks: 24px

Borders
	•	1px borders
	•	slightly cool gray on light mode
	•	slightly blue-gray slate on dark mode
	•	never thick outlines unless for code/demo blocks

Shadows

Soft, low-spread shadows only.
Think “depth of panels,” not “floating startup cards.”

Recommended shadow behavior:
	•	light mode: subtle vertical lift
	•	dark mode: faint ambient shadow plus border

⸻

6.6 Iconography

Icon style
	•	monoline
	•	1.75–2px stroke
	•	rounded corners
	•	minimal fills
	•	geometric, not hand-drawn

Preferred icon themes
	•	path
	•	map pin / waypoint
	•	branching arrows
	•	layers
	•	field lists
	•	queue / retry
	•	check / inspect / filter
	•	nodes and edges

Avoid
	•	stars
	•	wands
	•	sparkles
	•	literal eyes
	•	literal flames
	•	robot heads
	•	database cylinder stacks

⸻

6.7 Imagery

Acceptable imagery

Use:
	•	editor screenshots
	•	CLI screenshots
	•	Ecto schema snippets
	•	diagrams mapping source fields to indexed fields
	•	clean result cards and filter UIs
	•	abstract route maps
	•	node/edge systems
	•	subtle topographic lines
	•	grain-free dark UI mockups
	•	restrained glow around path lines

Conditionally acceptable
	•	faint ember-like highlights, only as color accents
	•	abstract celestial geometry, only if extremely minimal
	•	hardware/server imagery, only in technical blog posts

Forbidden imagery

Do not use:
	•	stock office people
	•	smiling teams around laptops
	•	literal fortune tellers or occult tools
	•	crystal balls
	•	fantasy spellbooks
	•	literal phoenix bird
	•	search magnifying glass as hero symbol
	•	random 3D blobs
	•	neon cyberpunk cityscapes
	•	generic AI robots
	•	brain/network clichés
	•	CCTV/eye surveillance visuals

Image treatment
	•	high contrast
	•	restrained saturation
	•	clean blacks
	•	warm off-white text
	•	focus on structure and path, not decoration

⸻

6.8 Illustration and diagrams

Preferred illustration style
	•	diagrammatic
	•	topological
	•	sparse
	•	technical
	•	elegant
	•	modular

Diagram ingredients
	•	source schema block
	•	transformation step
	•	job queue / sync state
	•	adapter boundary
	•	search index destination
	•	status and retry markers

Diagram language

Every visual diagram should imply:
source → transform → sync → index → query

Diagram colors
	•	structure lines: Slate
	•	active route: Violet
	•	key callout nodes: Copper
	•	success confirmations: Success green
	•	errors: Danger red, minimal use

⸻

6.9 Motion

Motion personality

Motion should feel:
	•	deliberate
	•	directional
	•	smooth
	•	infrastructural

Not:
	•	playful
	•	springy
	•	loud
	•	ornamental

Preferred motion patterns
	•	line draw/reveal
	•	node pulse
	•	panel fade/slide
	•	code block shimmer on hover
	•	active path tracing in diagrams

Timing
	•	fast UI motion: 120ms
	•	standard transitions: 180ms
	•	hero diagram motion: 240ms

Easing

Use one main easing curve:
	•	cubic-bezier(0.2, 0.8, 0.2, 1)

⸻

7. Product and website design guidance

Website tone

The website should feel like:
	•	docs-first
	•	credible
	•	developer-native
	•	dark-mode-forward
	•	slightly premium, but not commercial-polished

Homepage structure
	1.	Hero with clear one-liner
	2.	Short code snippet showing schema declaration
	3.	Feature grid around sync, reindexing, adapters, multi-tenancy
	4.	Architecture diagram
	5.	Example query/result UI
	6.	Docs CTA
	7.	GitHub CTA

Hero copy recommendation

Search indexing that feels native to Ecto
Declare searchable schemas, sync changes through background jobs, and query modern search engines with a Phoenix-friendly API.

CTA language

Use:
	•	Read the docs
	•	View on GitHub
	•	See the API
	•	Explore adapters
	•	Try an example app

Avoid:
	•	Get started free
	•	Book a demo
	•	Start your journey
	•	Unlock the future of search

README style

The README should open with:
	1.	what it is
	2.	why it exists
	3.	a 10-line example
	4.	supported adapters
	5.	reindexing/sync model
	6.	design principles
	7.	installation

The first example should be a schema declaration, not a benchmark.

⸻

8. Documentation tone and code presentation

Docs should feel
	•	concise
	•	technical
	•	unsurprised by complexity
	•	operationally honest

Docs writing rules
	•	explain defaults
	•	show failure/retry behavior
	•	document migration paths
	•	treat reindexing as normal
	•	document adapter limits explicitly
	•	prefer examples over adjectives

Code example styling
	•	always use real Elixir module names
	•	prefer short schemas like Product, Account, Invoice
	•	use MyApp. namespace in docs
	•	show Oban jobs plainly, not abstractly
	•	avoid fake startup names

Code block appearance
	•	dark background by default
	•	IBM Plex Mono
	•	minimal chrome
	•	highlighted lines in muted violet
	•	copy button discreet, not flashy

⸻

9. Open-source posture

Scrypath should feel like a serious open-source project, not a pre-startup landing page.

Signals to emphasize
	•	transparent roadmap
	•	clear contribution guide
	•	stability and versioning
	•	adapter contracts
	•	operational notes
	•	examples and migrations
	•	failure handling
	•	tests and observability

Signals to avoid
	•	vanity metrics as primary proof
	•	investor-language polish
	•	growth copy
	•	hard-sell CTAs
	•	empty aspirational statements

⸻

10. Brand do / don’t

Do
	•	use dark neutrals with violet and copper accents
	•	lead with schema-integrated examples
	•	make diagrams central
	•	sound calm and technically mature
	•	emphasize sync, reindexing, portability, and observability
	•	keep the mystique subtle and controlled

Don’t
	•	overuse “scry” metaphors
	•	lean into wizard/fantasy visuals
	•	sound like an AI company
	•	copy Rails/Searchkick’s tone directly
	•	use generic search-company green/blue branding
	•	turn the homepage into a benchmark flex page

⸻

11. LLM-ready design brief

Use this as the canonical design instruction block for future AI-assisted design work:

Design for Scrypath, an open-source Elixir/Phoenix library for Ecto-native search indexing and search orchestration.

Brand attributes:
- calm
- precise
- technical
- trustworthy
- slightly arcane
- docs-first
- open-source, not commercial SaaS

Visual style:
- dark-mode-forward
- midnight neutrals
- violet primary accent
- copper secondary accent
- warm off-white text
- clean borders
- sparse glows
- route/path diagrams
- schema-to-index visuals
- no generic startup blobs
- no magnifying glasses
- no literal eyes
- no fantasy/occult imagery
- no stock photos
- no AI robots

Typography:
- Space Grotesk for display
- Inter for body/UI
- IBM Plex Mono for code

UI characteristics:
- 12-column desktop grid
- 8px spacing system
- 16–24px card radius
- restrained shadows
- sentence case
- strong contrast
- code examples prominent
- architecture diagrams central

Tone of voice:
- declarative
- composed
- specific
- practical
- never hypey
- never salesy

Homepage priorities:
- explain what Scrypath is immediately
- show schema declaration example early
- highlight adapters, sync jobs, reindexing, multi-tenancy
- include architecture diagram
- prioritize docs and GitHub CTAs

Important:
Always present Scrypath with a descriptor on first mention, e.g. “Scrypath, the Ecto-native search indexing library,” because there is an existing public site using the same name in another category.


⸻

12. LLM-ready engineering brief

Use this for AI-assisted software engineering context:

Scrypath is a Phoenix/Ecto developer tool. Public brand voice is calm and exact; code API should be even plainer than the branding.

Engineering naming rules:
- prefer literal module names over mystical ones
- use Scrypath.Adapter.Meilisearch and Scrypath.Adapter.Typesense
- use Sync, Reindex, Index, Search, Schema, MultiTenant, Job names
- avoid Oracle, Prophecy, Seer, Grimoire, Ritual, Spell, etc.

Documentation rules:
- always show how sync happens
- document retries, reindexing, and failure modes
- avoid “magic” language
- show Ecto-centric examples first
- explain adapter boundaries clearly

Product framing:
- Scrypath is an Ecto-native orchestration layer, not a search engine and not an AI product
- emphasize declarative search indexing, job-backed sync, portability, and observability


⸻

13. Final recommendation

As a brand system, Scrypath works very well.
As a unique public name, it has real collision risk because of the existing Scrypath career product.  ￼

So the practical version is:
	•	keep Scrypath as the working creative identity if you love it
	•	attach the descriptor everywhere in public
	•	keep package/module/repo naming explicit
	•	let the visual identity do the heavy lifting: midnight, violet, copper, route diagrams, calm technical tone

That gives you a strong, distinctive system even if the bare word itself is not fully clean.