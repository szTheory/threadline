defmodule Threadline.SigraDocContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @repo_root File.cwd!()

  defp read_rel!(segments) when is_list(segments) do
    @repo_root |> Path.join(Path.join(segments)) |> File.read!()
  end

  test "sigra guide retains its marker and section order" do
    doc = read_rel!(["guides", "integrations", "sigra.md"])

    assert String.contains?(doc, "<!-- SIGRA-03-INTEGRATION-GUIDE -->")
    assert String.contains?(doc, "# Threadline ↔ Sigra integration")
    assert String.contains?(doc, "current `sigra-reference` lane")
    assert String.contains?(doc, "reference claim, not a blanket support promise")

    for heading <- [
          "## Install",
          "## Plug callback wire-up",
          "## Behaviors locked by SPEC",
          "## correlation_id formats",
          "## Soft-dep contract"
        ] do
      assert String.contains?(doc, heading)
    end

    {idx_install, _} = :binary.match(doc, "## Install")
    {idx_plug, _} = :binary.match(doc, "## Plug callback wire-up")
    {idx_behaviors, _} = :binary.match(doc, "## Behaviors locked by SPEC")
    {idx_formats, _} = :binary.match(doc, "## correlation_id formats")
    {idx_soft_dep, _} = :binary.match(doc, "## Soft-dep contract")

    assert idx_install < idx_plug
    assert idx_plug < idx_behaviors
    assert idx_behaviors < idx_formats
    assert idx_formats < idx_soft_dep
  end

  test "sigra guide locks install and plug literals" do
    doc = read_rel!(["guides", "integrations", "sigra.md"])

    assert String.contains?(doc, "{:sigra, \"~> 0.2\", optional: true}")
    assert String.contains?(doc, "for hosts; never for the library")
    assert String.contains?(doc, "Sigra stays host-owned and soft-loaded")
    assert String.contains?(doc, "not a blanket support promise for every Sigra")

    assert String.contains?(
             doc,
             "proven through the current example app, docs, and focused repo verification"
           )

    assert String.contains?(
             doc,
             "plug Threadline.Plug,"
           )

    assert String.contains?(
             doc,
             "actor_fn: &Threadline.Integrations.Sigra.actor_ref_from_conn/1"
           )

    assert String.contains?(
             doc,
             "context_overrides_fn: &Threadline.Integrations.Sigra.audit_context_overrides_from_conn/1"
           )
  end

  test "sigra guide locks the narrowed plug contract" do
    doc = read_rel!(["guides", "integrations", "sigra.md"])

    assert String.contains?(doc, "Wire `Threadline.Plug` directly with both callbacks")
    assert String.contains?(doc, "`actor_fn` decides who acted")
    assert String.contains?(doc, "can add only additive")
    assert String.contains?(doc, "supplemental: it fills missing values")
    assert String.contains?(doc, "`request_id` from `x-request-id` first")
    assert String.contains?(doc, "`correlation_id` from `x-correlation-id` first")
    assert String.contains?(doc, "raises `ArgumentError` immediately")
    assert String.contains?(doc, "rewrite `conn.remote_ip` upstream")
    assert String.contains?(doc, "direct callback pair, not a second adapter layer")
    assert String.contains?(doc, "Sigra covers request capture only")
    assert String.contains?(doc, "It does not secure `/audit`, export routes,")
    assert String.contains?(doc, "## Surface and export auth stay host-owned")

    assert String.contains?(
             doc,
             "request capture auth belongs in `actor_fn` plus `context_overrides_fn`"
           )

    assert String.contains?(doc, "LiveView surface auth belongs in `authorize_fn`")
    assert String.contains?(doc, "export HTTP auth belongs in `export_authorize_fn`")
    assert String.contains?(doc, "synthetic `%{assigns: conn.assigns}` mirror")
    assert String.contains?(doc, "Sigra does not become the auth story")
    assert String.contains?(doc, "one shared `%{assigns: assigns}`")
    assert String.contains?(doc, "support-read-only lane")
    assert String.contains?(doc, "`exports: false`")
    assert String.contains?(doc, "opaque host data")
    assert String.contains?(doc, "Do not treat Sigra as a page-level authorization DSL")
    assert String.contains?(doc, "Threadline-owned roles system")

    assert String.contains?(doc, "Impersonation maps to `:admin`")
    assert String.contains?(doc, "API token maps to `:service_account`")
    assert String.contains?(doc, "Active organization adds a suffix")
    assert String.contains?(doc, "Anonymous / Sigra-absent returns `nil`")
    assert String.contains?(doc, "`x-correlation-id` header always wins")

    assert String.contains?(
             doc,
             "`x-request-id` and any existing actor identity also stay authoritative"
           )

    assert String.contains?(doc, "`audit_context_overrides_from_conn/1` returns `%{}`")
    assert String.contains?(doc, "Plug-only adapter; no telemetry subscription in v1")
    assert String.contains?(doc, "supported reference semantics for the current guide and")
    assert String.contains?(doc, "not a statement that every Sigra-backed Phoenix host or")
  end

  test "sigra guide locks correlation_id formats and soft-dep contract" do
    doc = read_rel!(["guides", "integrations", "sigra.md"])

    assert String.contains?(doc, "`sigra-imp:<session_id>:user:<imp_user_id>`")
    assert String.contains?(doc, "`sigra-session:<session_id>`")
    assert String.contains?(doc, "`sigra-token:<token_id>`")
    assert String.contains?(doc, "no override / `%{}`")
    assert String.contains?(doc, "`Code.ensure_loaded?(Sigra.Session)`")
    assert String.contains?(doc, "`actor_ref_from_conn/1` returns `nil`")
    assert String.contains?(doc, "`audit_context_overrides_from_conn/1` returns `%{}`")
    assert String.contains?(doc, "That soft-dep contract is part of the `sigra-reference` lane.")
    assert String.contains?(doc, "The host owns")
  end

  test "library mix.exs remains free of sigra deps" do
    mix_exs = read_rel!(["mix.exs"])
    refute String.contains?(mix_exs, "{:sigra")
  end
end
