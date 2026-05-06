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
  end

  test "library mix.exs remains free of sigra deps" do
    mix_exs = read_rel!(["mix.exs"])
    refute String.contains?(mix_exs, "{:sigra")
  end
end
