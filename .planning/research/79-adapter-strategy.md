# Phase 79: Scale Adapters Strategy & Research

## Executive Summary

After evaluating the tradeoffs between In-Tree Optional Dependencies, Separate Hex Packages, and Bring Your Own Adapter (BYOA) models, **Threadline must adopt Approach 1: Optional Dependencies (In-Tree).** 

Shipping `Oban` and `S3` adapters inside the main `threadline` Hex package—while marking their underlying libraries as `optional: true` in `mix.exs`—is the only approach that satisfies Threadline's dual mandate of "zero-config for local development" and "frictionless enterprise scale-out." This mirrors the gold-standard Developer Experience (DX) established by libraries like `Swoosh` and `Ecto`. It directly aligns with the architectural mandate laid out in `GEMINI.md`.

By centralizing the adapters, we eliminate the "version drift footgun" associated with multi-package ecosystems, maintain atomic updates when internal `@callback` contracts change, and deliver the "batteries-included" magic expected from a premier Elixir platform.

---

## Strategic Context & DX Goals

Based on Threadline's OSS "DNA" and product strategy:
1. **Batteries-Included Operator Experience:** The platform must provide robust operator tooling out-of-the-box. Forcing adopters to write custom Oban or S3 wrappers for standard enterprise needs violates the principle of least surprise and introduces unnecessary friction for compliance teams.
2. **Zero-Config Baseline:** SMBs and local development environments should not be burdened with transitive dependencies (`oban`, `ex_aws`) or infrastructure requirements they do not use. Defaulting to local disk storage and async Task queues for zero-config setups is critical.
3. **Atomic Coherence:** Documentation, changelogs, and releases must tell a unified story. Multi-package setups fracture this narrative and break integration confidence.

---

## Evaluation of Approaches

### 1. Optional Dependencies (In-Tree) - **RECOMMENDED**
Adapters (`Threadline.ExportQueue.Oban`, `Threadline.Storage.S3`) ship in the core package. Dependencies (`oban`, `ex_aws`, etc.) are marked `optional: true`.

*   **Pros:**
    *   **Maximized DX:** The transition from local to distributed scaling is a single-line configuration change and a simple `mix deps.get`.
    *   **Atomic Refactoring:** If Threadline changes the `Threadline.Storage` `@callback`, the `S3` adapter is updated in the exact same commit. 
    *   **Unified Documentation:** All adapter documentation lives centrally on HexDocs under the `Threadline` namespace.
    *   **CI Guarantees:** Threadline's core test matrix runs against the actual adapter code, ensuring compatibility.
*   **Cons:**
    *   Slightly larger `.beam` footprint for the package (negligible in Elixir).
    *   Requires deliberate guardrails to prevent cryptic `UndefinedFunctionError` crashes if a user configures an adapter without having the optional dependency installed.
*   **Elixir Ecosystem Precedent:** **Swoosh** is the prime example, shipping dozens of adapters in-tree and relying on optional `finch`/`hackney` dependencies. **Ecto** (`ecto_sql` bundles Postgres, MySQL, TDS) and **Oban** (bundles telemetry and different engines) also use this pattern.

### 2. Separate Hex Packages (`threadline_oban`, `threadline_s3`)
Extracting adapters into distinct packages for "pure" dependency isolation.

*   **Pros:**
    *   Perfect dependency isolation (no `optional: true` needed).
    *   Core `threadline` package remains theoretically pristine and minimal.
*   **Cons:**
    *   **The Version Drift Footgun:** Adopters must manually align versions (`{:threadline, "~> 1.2"}, {:threadline_oban, "~> 1.2"}`). A breaking change in the core behaviour causes massive ecosystem friction and confusion if adapters lag behind.
    *   **Maintenance Bloat:** Managing 3-4 separate repositories (or a complex Hex workspace) for 50-line adapter modules destroys maintainer velocity and scatters issues.
*   **Ecosystem Precedent:** **Broadway** uses this (`broadway_sqs`, `broadway_rabbitmq`), but Broadway producers are vastly more complex and heavy than Threadline's storage sinks. Node.js heavily utilizes this (e.g., `passport` strategies), frequently resulting in dependency hell and abandoned micro-packages.

### 3. Bring Your Own Adapter (BYOA)
Providing only `@callback` modules and leaving the implementation completely to the user.

*   **Pros:**
    *   Zero maintenance overhead for Threadline maintainers regarding external systems.
*   **Cons:**
    *   **High Friction:** Violates the core product thesis of an operator-friendly audit platform. Oban and S3 are the overwhelming industry standards for Elixir background jobs and object storage. Forcing every enterprise adopter to independently reinvent, test, and debug the exact same integration boilerplate guarantees a poor adoption experience.

---

## Lessons from Broader Ecosystems

*   **Ruby on Rails (ActiveJob / ActiveStorage):** Rails won the developer ergonomics war by defining core interfaces (`ActiveJob`, `ActiveStorage`) and bundling the most common adapters (Sidekiq, S3, GCS) directly within the framework. This established immediate ecosystem standards and minimized boilerplate for 90% of use cases.
*   **Django:** Django bundles database cache backends, Redis, and Memcached support in-tree, allowing developers to switch infrastructure topologies purely via `settings.py`. Its `django-auditlog` extension is similarly "batteries-included."
*   **The Micro-Package Trap:** Ecosystems that heavily favor Approach 2 (Separate Packages) often end up with outdated, unmaintained adapters floating around package registries, eroding trust in the core library. Threadline must avoid this by keeping its core integrations under the umbrella of its primary CI and test matrices, ensuring the "happy path" is completely owned by Threadline.

---

## Technical Implementation Strategy

To execute **Approach 1** perfectly, Threadline must implement the following safeguards:

1.  **Explicit Contracts:** Define rigid `@callback` modules (`Threadline.ExportQueue`, `Threadline.Storage`).
2.  **Optional Deps:** Add `:oban`, `:ex_aws`, `:ex_aws_s3`, and `:hackney` to `mix.exs` as `optional: true`.
3.  **Fail Beautifully:** Implement compile-time or initialization-time checks inside the adapters. Do not let it fail with a cryptic missing module error at runtime. We must provide actionable instructions.

**Example Safeguard Pattern:**

```elixir
defmodule Threadline.Storage.S3 do
  @behaviour Threadline.Storage

  def init(opts) do
    unless Code.ensure_loaded?(ExAws.S3) do
      raise """
      Threadline.Storage.S3 requires the :ex_aws and :ex_aws_s3 dependencies.
      Please add them to your mix.exs:
        {:ex_aws, "~> 2.0"},
        {:ex_aws_s3, "~> 2.0"}
      """
    end
    
    # Proceed with initialization...
  end
end
```

By keeping the adapters in-tree, Threadline guarantees that every scale-out deployment is tested against the core framework in a single, unified CI pipeline, delivering the reliability and ergonomics expected of a tier-one Elixir platform.