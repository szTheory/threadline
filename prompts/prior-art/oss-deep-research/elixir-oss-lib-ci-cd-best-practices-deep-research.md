Here’s the opinionated, high-signal answer I’d use for an open-source Elixir Stripe SDK on GitHub Actions.

Bottom line

For your use case, the best default stack is:
	•	GitHub Actions for CI/CD
	•	erlef/setup-beam for Elixir/OTP setup, with strict exact versions
	•	Release Please for automated version bumps, CHANGELOG generation, release PRs, tags, and GitHub Releases
	•	Conventional Commits to drive semver automatically
	•	Hex publishing via mix hex.publish --yes
	•	ExDoc for docs, with warnings-as-errors and modern Markdown / llms.txt output
	•	Dependabot for both Mix deps and GitHub Actions
	•	Dependency Review + action pinning / least-privilege permissions for workflow security
	•	Credo + Dialyzer + tests + formatter + Hex audit as the core library quality gates

That combination gives you the most “hands-off” path while still fitting Elixir and open-source library norms well. Release Please explicitly supports an elixir release type, creates release PRs from Conventional Commits, and exposes outputs like release_created, version, and tag_name that are ideal for chaining into a Hex publish step. Hex supports noninteractive publishing with mix hex.publish --yes, and it automatically builds/publishes docs from mix docs.  ￼

The release model you want

Use this release flow:
	1.	Contributors merge PRs into main
	2.	PRs use Conventional Commits semantics
	3.	Release Please continuously updates a release PR
	4.	When that release PR is merged, Release Please:
	•	bumps the version
	•	updates CHANGELOG.md
	•	creates the Git tag
	•	creates the GitHub Release
	5.	A publish job runs only when release_created == true
	6.	That job publishes the package to Hex and lets Hex publish docs automatically

This is the cleanest “no manual cutting releases” model for an OSS library. Conventional Commits map naturally to SemVer: fix → patch, feat → minor, and ! or BREAKING CHANGE: → major. Release Please is built around that model.  ￼

Best practice for contributors: don’t overburden them

For OSS, do not require every contributor to perfectly structure every commit locally. Conventional Commits’ own guidance explicitly notes that with a squash-merge workflow, maintainers can clean up the final merge commit message instead of forcing casual contributors to conform on every commit. In practice, that means: require squash merge, and make the PR title or final squash commit conform to Conventional Commits. That keeps automation reliable without making contribution UX annoying.  ￼

My recommended workflow layout

Use separate workflows, not one giant YAML:

ci.yml

Runs on pull_request and push to main.

Include:
	•	formatter check
	•	compile with warnings as errors
	•	tests
	•	Credo
	•	Dialyzer
	•	docs build with warnings as errors
	•	Hex audit

Why: libraries live or die on API stability and developer trust, so CI should validate correctness, docs, static analysis, and publishability before merge. Elixir/Mix explicitly supports mix format --check-formatted, mix compile --warnings-as-errors, mix test --warnings-as-errors, mix docs --warnings-as-errors, and mix hex.audit. Elixir’s own docs recommend mix format --check-formatted on CI, and library guidelines recommend compiling with --no-optional-deps --warnings-as-errors in test environments for libraries with optional deps.  ￼

release-please.yml

Runs on pushes to main.

Include:
	•	Release Please action
	•	conditional publish step or follow-on job when steps.release.outputs.release_created is true

Why: this keeps release automation isolated and deterministic. Release Please’s GitHub Action is the recommended setup, and its manifest mode is the recommended way to onboard/customize repositories.  ￼

dependency-review.yml

Runs on pull_request.

Include:
	•	actions/dependency-review-action

Why: GitHub recommends dependency review to catch vulnerable dependencies before they land, including dependencies introduced by workflow changes.  ￼

actionlint.yml

Runs on PRs that touch .github/workflows/**.

Include:
	•	rhysd/actionlint

Why: actionlint catches workflow syntax errors, expression mistakes, invalid outputs/inputs, shell issues, and some workflow security mistakes. It is one of the highest-leverage additions for GitHub Actions quality.  ￼

dependabot.yml

Use Dependabot for:
	•	github-actions
	•	your Elixir/Mix ecosystem dependencies as supported in your repo

GitHub recommends Dependabot for keeping actions and workflows up to date, and it supports the github-actions ecosystem directly.  ￼

Elixir-specific CI best practices

For an Elixir library, I’d make these checks non-negotiable:

1. Formatter check

Run mix format --check-formatted.

Elixir recommends this on CI, and it avoids noisy formatting churn in PRs.  ￼

2. Compile warnings as errors

Run mix compile --warnings-as-errors.

For libraries, warnings are often real compatibility/documentation/API hygiene issues. Elixir library guidance also recommends mix compile --no-optional-deps --warnings-as-errors in test environments when optional dependencies exist.  ￼

3. Test warnings as errors

Run tests with warnings-as-errors, not just plain mix test.

Mix documents the correct pattern as:

MIX_ENV=test mix do compile --warnings-as-errors + test --warnings-as-errors  ￼

4. Credo

Run mix credo --strict.

Credo is the de facto Elixir static analysis/linting tool and is appropriate for a public SDK where maintainability matters.  ￼

5. Dialyzer

Run Dialyzer via Dialyxir, and cache PLTs.

Dialyxir explicitly recommends caching the project PLT in CI and notes PLTs must be rebuilt when adding a new Erlang or Elixir version.  ￼

6. Docs build as a gate

Run mix docs --warnings-as-errors.

Your SDK’s docs are part of the product. Broken docs, broken links, or missing docs should fail CI. ExDoc supports warnings-as-errors.  ￼

7. Hex audit

Run mix hex.audit.

This catches retired Hex dependencies and exits nonzero when found.  ￼

8. Coverage: useful, but don’t overfit to a vanity percentage

Coverage thresholds can be enforced in Mix, but for an SDK library I’d treat coverage as a signal, not the primary gate. More important than an arbitrary number is ensuring:
	•	request-building paths are tested
	•	response decoding/error paths are tested
	•	backward compatibility tests exist for stable public APIs

Mix can fail below a coverage threshold if you want it.  ￼

Version matrix strategy for an OSS Elixir library

Use two layers of confidence:

Fast required matrix

A small required matrix on Ubuntu:
	•	minimum supported Elixir / OTP pair
	•	current stable Elixir / OTP pair
	•	maybe latest supported pair

Slow optional matrix

Nightly or non-blocking jobs:
	•	wider OTP/Elixir matrix
	•	maybe macOS or Windows only if you truly claim support and have platform-sensitive behavior

Why: setup-beam recommends exact version pinning with version-type: strict, which is good for deterministic CI. For a library, wide matrices are useful, but they can get expensive and slow. Keep branch protection tied to a smaller required matrix.  ￼

Caching: do it, but cache the right things

Use GitHub cache for:
	•	deps
	•	_build
	•	Dialyzer PLTs

Key caches by:
	•	OS
	•	Elixir version
	•	OTP version
	•	mix.lock
	•	maybe hash of .tool-versions if you use one

GitHub distinguishes caching from artifacts: caching is for reusable dependencies; artifacts are for outputs/logs you want to inspect after a run. For Elixir CI, dependencies and PLTs belong in cache, not artifacts.  ￼

GitHub Actions best practices that matter most here

1. Set minimal permissions

Use the permissions key and grant the least privilege required. GitHub explicitly recommends granting the GITHUB_TOKEN the minimum required access and notes that permissions can be set at the workflow or job level.  ￼

2. Use concurrency

For PR CI, set concurrency so superseded runs cancel in progress. GitHub documents concurrency groups specifically for avoiding duplicate or outdated runs.  ￼

3. Pin third-party actions

Best security practice is to pin actions to a full commit SHA. GitHub says that pinning to a full-length SHA is the only way to use an action as an immutable release. In practice, many repos pin to major tags for convenience, but SHA pinning is the stricter recommendation.  ￼

4. Let Dependabot update actions

Because SHA pinning makes manual updates annoying, pair it with Dependabot on the github-actions ecosystem. GitHub explicitly recommends Dependabot for actions/workflows.  ￼

5. Protect workflow changes

Use CODEOWNERS for .github/workflows/**. GitHub recommends CODEOWNERS to monitor workflow changes.  ￼

6. Reusable workflows only if you actually need them

GitHub reusable workflows are excellent for avoiding duplication, but for a single OSS library repo, don’t over-engineer. Use them once you have repeated patterns across repos. GitHub supports reusable workflows via workflow_call.  ￼

Release Please: why it’s the best fit here

I’d choose Release Please over more generic release tools for this project because:
	•	it has a native elixir release type
	•	it is designed around release PRs, which makes release changes reviewable
	•	it automates CHANGELOG generation
	•	it automates version bumps
	•	it exposes outputs that make publish-on-release straightforward
	•	its docs recommend using the GitHub Action, and recommend manifest config for customization/onboarding  ￼

My recommendation: use manifest config even for a single package. It future-proofs you if you later add a generated API package, test helpers, or a monorepo structure. Release Please explicitly says the easiest onboarding path is to bootstrap a manifest config.  ￼

Important nuance: GITHUB_TOKEN vs PAT for release automation

This matters a lot.

Release Please defaults to secrets.GITHUB_TOKEN, but its docs warn that resources created by GITHUB_TOKEN do not trigger further GitHub Actions workflow runs. So if you want workflows to run on Release Please PRs/releases, you may need a PAT. Release Please explicitly calls this out and says a PAT is needed if you want CI checks to run on Release Please PRs.  ￼

My recommendation:
	•	Start with GITHUB_TOKEN if you want the simplest setup
	•	Switch to a fine-grained PAT if you need downstream workflow triggering on release PRs/releases
	•	Keep PAT scope as narrow as possible

Hex publishing best practices

Hex publishing is straightforward:
	•	mix hex.publish publishes the package
	•	docs are generated from mix docs and published automatically
	•	mix hex.publish --yes avoids interactive prompts
	•	mix hex.publish --dry-run is useful as a preflight check
	•	Hex requires SemVer, and while still on 0.x, breaking changes should bump the minor version, not patch  ￼

For CI/CD:
	•	store a Hex API key as a GitHub secret
	•	only expose it to the publish job
	•	only publish from trusted refs/events
	•	never publish on PRs or from forks

Hex user auth is API-key based, and Hex’s user/org auth tasks are explicitly built around API keys.  ￼

ExDoc best practices for a public SDK

For a Stripe SDK, docs are as important as code. I’d do all of this:
	•	set source_url
	•	set homepage_url
	•	set a meaningful main
	•	include README.md as an extra
	•	add guides for auth, retries, pagination, idempotency, webhooks, testing, and error handling
	•	group extras and modules so the sidebar is navigable
	•	fail CI if docs emit warnings

ExDoc supports source_url, homepage_url, extras, grouping, and warnings-as-errors.  ￼

Very relevant for your “LLM context” goal

Recent ExDoc releases added a Markdown formatter and generate llms.txt by default. That is unusually relevant for AI-assisted development because it gives your package docs an LLM-friendly representation out of the box. ExDoc 0.40.x explicitly added Markdown generation and llms.txt, and HexDocs pages now expose “View llms.txt”.  ￼

That means one of the best “2025/2026-era” best practices for your SDK is:
	•	invest in ExDoc guide pages
	•	keep examples realistic
	•	document edge cases and errors
	•	let ExDoc generate LLM-friendly docs automatically

Package metadata and naming best practices

Hex strongly recommends good package metadata and naming hygiene. For a public library:
	•	use a clear package name
	•	ensure all public modules share a consistent top-level namespace
	•	fill in description
	•	set licenses
	•	set links
	•	keep the package file list tight
	•	include README, LICENSE, and CHANGELOG

Hex’s publish docs explicitly recommend metadata like licenses and links, and explain why module naming consistency matters on the BEAM: module name collisions are real.  ￼

For your case, I’d strongly prefer a namespace like:
	•	package: stripity_stripe-style naming if you want familiarity, or a clearly distinct modern name
	•	modules: YourSdk.*

The main point is to avoid generic top-level modules in the BEAM ecosystem.  ￼

Supply-chain/security practices worth adopting now

For an OSS SDK, I’d include these from day one:
	•	Dependency Review on PRs
	•	Dependabot alerts + version updates
	•	action SHA pinning
	•	least-privilege GITHUB_TOKEN
	•	workflow CODEOWNERS
	•	artifact attestations for built release artifacts if you publish any binaries or generated assets

GitHub’s docs recommend dependency review and least-privilege tokens; they also support artifact attestations for build provenance, including required permissions id-token: write, contents: read, and attestations: write.  ￼

For a pure Hex package, attestations are optional, but if you ever attach generated OpenAPI specs, tarballs, or other release assets, provenance becomes more attractive.  ￼

What I would actually enforce in branch protection

Required checks:
	•	format
	•	compile
	•	test
	•	credo
	•	dialyzer
	•	docs
	•	dependency-review

Optional/non-blocking:
	•	wide compatibility matrix
	•	coverage reporting
	•	nightly jobs
	•	benchmark smoke tests

That keeps maintainer friction low while preserving quality.

Practical anti-patterns to avoid

Do not:
	•	use one gigantic matrix as required status
	•	publish from PRs
	•	let secrets exist in every job
	•	tie publish to a plain git tag push with no review step
	•	manually edit CHANGELOG.md and versions if Release Please is managing them
	•	skip docs validation for a public SDK
	•	pin actions only by floating tags without Dependabot or review
	•	make contributors rewrite every local commit if squash-merge titles solve the problem better

Those are the patterns that make OSS CI/CD fragile or high-maintenance.

My final recommendation

Use this exact mental model:
	•	CI is for correctness and library hygiene
	•	Release Please is the release brain
	•	Hex is the package/docs publisher
	•	ExDoc is both your user docs and your LLM-facing docs layer
	•	GitHub security features keep the automation safe
	•	Conventional squash-merge titles keep the workflow contributor-friendly

If you want, I can turn this into a concrete starter kit for your repo:
	•	.github/workflows/ci.yml
	•	.github/workflows/release-please.yml
	•	.github/workflows/dependency-review.yml
	•	.github/workflows/actionlint.yml
	•	release-please-config.json
	•	.release-please-manifest.json
	•	dependabot.yml
	•	a mix.exs docs/package config tuned for an OSS Elixir SDK