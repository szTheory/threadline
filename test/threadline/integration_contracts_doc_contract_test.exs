defmodule Threadline.IntegrationContractsDocContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  test "integration-contracts guide keeps the locked section architecture" do
    guide = File.read!("guides/integration-contracts.md")

    assert String.contains?(guide, "## Request path via `Threadline.Plug`")
    assert String.contains?(guide, "## Job path via `Threadline.Job`")
    assert String.contains?(guide, "## Reference integrations via `Threadline.Integrations.*`")

    assert String.contains?(
             guide,
             "## Operator-surface composition via `authorize_fn` and `export_authorize_fn`"
           )

    assert String.contains?(guide, "## Canonical references")
  end

  test "integration-contracts guide locks the concrete breadth seams" do
    guide = File.read!("guides/integration-contracts.md")

    assert String.contains?(guide, "`Threadline.Plug` owns request-path capture context.")
    assert String.contains?(guide, "`Threadline.Job` owns serialized job-path context.")
    assert String.contains?(guide, "`Threadline.Integrations.*` owns soft-loaded reference adapters.")
    assert String.contains?(guide, "`threadline_operator_surface/2` owns the operator-surface mount boundary")
    assert String.contains?(guide, "Threadline does not introduce a separate adapter behaviour")
    assert String.contains?(guide, "These are the existing supported seams.")
  end

  test "integration-contracts guide locks request and job contract literals" do
    guide = File.read!("guides/integration-contracts.md")

    assert String.contains?(guide, "actor_fn: &MyApp.Audit.actor_ref_from_conn/1")
    assert String.contains?(guide, "context_overrides_fn: &MyApp.Audit.audit_context_overrides/1")
    assert String.contains?(guide, "`actor_fn` is the only actor-authority callback.")
    assert String.contains?(guide, "`context_overrides_fn` is additive-only.")
    assert String.contains?(guide, "Unknown override keys and non-map returns fail closed with `ArgumentError`.")
    assert String.contains?(guide, "Proxy-aware IP normalization stays host-owned.")
    assert String.contains?(guide, "\"actor_ref\" => Threadline.Semantics.ActorRef.to_map(actor_ref)")
    assert String.contains?(guide, "Threadline.Job.actor_ref_from_args/1")
    assert String.contains?(guide, "Threadline.Job.context_opts/2")
    assert String.contains?(guide, "currently `\"correlation_id\"` and `\"job_id\"`.")
  end

  test "integration-contracts guide locks the support-lane proof anchors" do
    guide = File.read!("guides/integration-contracts.md")

    assert String.contains?(guide, "Capture-only adopters can stop here.")
    assert String.contains?(guide, "`mix verify.compile_no_optional` proves that")
    assert String.contains?(guide, "surface without optional Phoenix UI dependencies.")
    assert String.contains?(guide, "Threadline.Integrations.Sigra` is the current model:")
    assert String.contains?(guide, "`guides/operator-surface.md` for the screen-level mount walkthrough")
    assert String.contains?(guide, "`guides/integrations/sigra.md` for the current first-party reference adapter")
  end

  test "integration-contracts guide locks operator-surface callback and export fallback wording" do
    guide = File.read!("guides/integration-contracts.md")

    assert String.contains?(guide, "authorize_fn: &MyApp.Audit.authorize_operator/1")
    assert String.contains?(guide, "export_authorize_fn: &MyApp.Audit.authorize_operator_export/1")
    assert String.contains?(guide, "`authorize_fn` is the canonical operator-surface callback.")
    assert String.contains?(guide, "It is invoked")
    assert String.contains?(guide, "directly as a 1-arity function")
    assert String.contains?(guide, "`export_authorize_fn` is optional.")
    assert String.contains?(guide, "export auth deliberately falls back to")
    assert String.contains?(guide, "mirror = %{assigns: conn.assigns}")
    assert String.contains?(guide, "That fallback is part of the public contract.")
    assert String.contains?(guide, "Both transport faces share the same telemetry event")
  end
end
