# Phase 248: Reconcile the base and safety/proof ownership - Pattern Map

**Mapped:** 2026-11-10  
**Files analyzed:** 24 scoped paths  
**Analog coverage:** Router, fixture, lockfile, workflow, and contract-test patterns mapped; lock changes are Mix-generated.

## File Classification

| New/Modified File Group | Role | Data Flow | Closest Analog |
|---|---|---|---|
| lib/threadline/operator_surface/router.ex | route | request-response; compile-time mount config | Same file, lines 43-55 and 142-163 |
| test/threadline/operator_surface/router_test.exs and 17 fixture mounts in 248-mount-research.md:23-24 | test | compile-time / request-response | router_test.exs lines 5-95; test/support/operator_surface_case.ex lines 29-70 |
| mix.lock, bench/mix.lock, examples/threadline_phoenix/mix.lock | config | batch dependency resolution | Existing entries in each lockfile; update via Mix |
| .github/workflows/flake-detection.yml | config | batch CI | .github/workflows/ci.yml lines 688-699 |
| test/threadline/browser_journey_evidence_contract_test.exs | test | static workflow contract | Same file lines 148-165; ci_workflow_parity_contract_test.exs lines 3098-3142 |

## Pattern Assignments

### Router authorization guard and fixtures

The tracked macro already carries the mount call site into a compile-time guard:

~~~elixir
caller_file = __CALLER__.file
caller_line = __CALLER__.line

quote do
  unquote(secure_mount_guard(has_auth_fn?, has_ack?, caller_file, caller_line))
  import Phoenix.LiveView.Router, only: [live_session: 3, live: 3]
end
~~~

Source: lib/threadline/operator_surface/router.ex:43-56. Keep this call-site CompileError structure, but replace the current pipeline/auth/ack predicate at lines 142-163 with the approved usable-authorizer OR exact-literal-ack rule and diagnostic. Do not infer authorization from pipe_through.

The compile test uses Code.compile_quoted and assert_raise CompileError (test/threadline/operator_surface/router_test.exs:5-23). The exact public opt-out fixture is:

~~~elixir
Threadline.OperatorSurface.Router.threadline_operator_surface("/threadline",
  adopter_acknowledges_unauthenticated: true
)
~~~

Source: test/threadline/operator_surface/router_test.exs:76-86. Keep the shared OperatorSurfaceTest.Router helper as browser/session/layout middleware only; its individual mount sites stay visible (test/support/operator_surface_case.ex:29-70). Use the real test authorize_fn on fixtures whose purpose is to test authorization; mark only intentionally public UI/domain fixtures with the exact acknowledgement. The example host mount keeps both its browser/auth pipeline and authorize_fn (examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex:244-253).

### Three Mix lockfiles

Affected current tuples: Ecto 3.14.2 in mix.lock:9, bench/mix.lock:13, and examples/threadline_phoenix/mix.lock:13; Phoenix.HTML 4.3.0 in mix.lock:33 and example mix.lock:38; Bandit 1.13.1 in example mix.lock:4. Resolve the researched compatible targets through Mix independently for root, bench, and example, then review collateral lock changes. These entries/checksums are generated output; do not hand-edit them or change constraints/support floors.

Existing audit gates/contracts: bin/verify-deps-audit, test/threadline/deps_audit_contract_test.exs, and test/threadline/deps_audit_gate_test.exs. Inspect all three audit results, including non-blocking findings; exit status zero alone is not a clean report.

### Flake Detection Node/npm setup

The current required-test lane pins Node from .tool-versions, caches by the E2E lockfile, and installs with npm ci:

~~~yaml
- name: Set up Node for browser journey contract
  if: matrix.lane == 'current'
  uses: actions/setup-node@a0853c24544627f65ddf259abe73b1d18a591444 # v5.0.0
  with:
    node-version-file: .tool-versions
    cache: npm
    cache-dependency-path: examples/threadline_phoenix/e2e/package-lock.json

- name: Install locked E2E dependencies for browser journey contract
  if: matrix.lane == 'current'
  working-directory: examples/threadline_phoenix/e2e
  run: npm ci
~~~

Source: .github/workflows/ci.yml:688-699. Copy the pinned action and inputs into verify-flake, gate both steps on steps.gate.outputs.decision == 'run', and install before mix verify.flake. Keep the verify-flake job ID, repeat budget, classifier, and failure reporting.

Extend or mirror test/threadline/browser_journey_evidence_contract_test.exs:148-165 to scope checks to verify-flake and assert pinned Node, the E2E lock path, npm ci in the E2E directory, and install-before-repeat ordering. Preserve test/threadline/ci_action_pin_contract_test.exs pin rules, ci_workflow_parity_contract_test.exs toolchain/cache checks, and flake_classifier_contract_test.exs / property_scale_contract_test.exs behavior coverage.

## Shared Patterns

- Auth grants remain :ok, true, or {:ok, scope}; callback errors and invalid results deny (lib/threadline/operator_surface/auth.ex:97-152).
- Preserve existing UI output and styles. 248-UI-SPEC.md authorizes only the compile diagnostic; no runtime styling or brand migration belongs here.
- All named code, workflow, lockfile, and test analogs were verified as tracked with git ls-files --error-unmatch.

## Metadata

**Analog search scope:** operator-surface router/tests, example router, CI workflows, workflow/audit contracts, and the three project lockfiles.  
**Pattern extraction date:** 2026-11-10
