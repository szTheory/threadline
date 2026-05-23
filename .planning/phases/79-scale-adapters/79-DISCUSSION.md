# Phase 79: Scale Adapters - Discussion & Recommendation

**Status: RESOLVED**

## Architectural Gray Areas

The primary requirements for scale-out operators mandate providing robust adapters for enterprise deployments:
1. `Threadline.ExportQueue.Oban` for multi-node background export queueing.
2. `Threadline.Storage.S3` for shared CSV export storage via `ex_aws_s3`.

Since Threadline is an embeddable engine/library, we must address the following structural questions:
1. **Dependency Management:** How do we bundle these adapters without forcing transitive dependencies (`oban`, `ex_aws`, `sweet_xml`, `hackney`) on adopters who only need single-node, local-disk capabilities?
2. **Behaviour Contracts:** What is the exact shape of the interfaces that the adapters will implement?
3. **Developer Ergonomics:** How do adopters opt-in to these adapters safely and gracefully without cryptic runtime crashes?

## Final Decision: Optional Dependencies (In-Tree)

Following deep research (see `.planning/research/79-adapter-strategy.md`) and our global `GEMINI.md` architectural preferences, Threadline will adopt the **In-Tree Optional Dependencies** approach.

We will include `oban`, `ex_aws`, `ex_aws_s3`, and an HTTP client like `hackney` in Threadline's `mix.exs` as `optional: true` dependencies. The adapters themselves will ship inside the main `threadline` package.

### Summary of Benefits
* **Zero Overhead for SMBs:** Adopters running single-node deployments don't download AWS SDKs or Oban, maintaining a frictionless onboarding experience.
* **Maximized DX & Enterprise Ready:** Multi-node adopters get robust, battle-tested integrations with standard tools. The transition from local to distributed is a one-line config change and a simple `mix deps.get`.
* **Atomic Refactoring:** Changes to internal `@callback` contracts update the adapters in the exact same commit, eliminating the "version drift footgun" associated with separate micro-packages.
* **Unified Documentation:** All adapter documentation lives centrally on HexDocs under the `Threadline` namespace.

### 1. The Behaviour Contracts

We will formalize behaviours for extensibility while maintaining type safety.

**`Threadline.ExportQueue`**
```elixir
defmodule Threadline.ExportQueue do
  @callback enqueue(export_job_id :: String.t(), opts :: keyword()) :: :ok | {:error, term()}
end
```

**`Threadline.Storage`**
```elixir
defmodule Threadline.Storage do
  @callback put(path :: String.t(), content_or_stream :: term(), opts :: keyword()) :: :ok | {:error, term()}
  @callback get_url(path :: String.t(), opts :: keyword()) :: {:ok, String.t()} | {:error, term()}
  @callback delete(path :: String.t(), opts :: keyword()) :: :ok | {:error, term()}
end
```

### 2. Dependency Management & Safety

In `mix.exs`, we will add the dependencies as optional:
```elixir
defp deps do
  [
    # ... existing deps ...
    {:oban, "~> 2.15", optional: true},
    {:ex_aws, "~> 2.4", optional: true},
    {:ex_aws_s3, "~> 2.4", optional: true},
    {:hackney, "~> 1.18", optional: true},
    {:sweet_xml, "~> 0.7", optional: true} # Required by ex_aws
  ]
end
```

To ensure excellent developer ergonomics and fail fast, the adapters must implement a robust initialization check. Example safeguard pattern:
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

This ensures Threadline stays true to its core DNA: an impossible-to-miss row capture engine paired with excellent operator tools and zero-fuss scale-out potential.