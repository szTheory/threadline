defmodule ThreadlinePhoenix.DemoManifestTest do
  use ExUnit.Case, async: true

  alias ThreadlinePhoenix.Demo.Manifest

  @acme_org_id "d99bff6a-063e-5f45-baaf-4f7a9d60ff72"

  setup :verify_manifest_config

  test "epoch/0 matches application config" do
    configured = Application.get_env(:threadline_phoenix, :demo_epoch)

    assert Manifest.epoch() == configured
    assert Manifest.epoch() == ~U[2026-05-27 12:00:00Z]
  end

  test "org_id/1 returns stable Acme uuid" do
    assert Manifest.org_id(:acme) == @acme_org_id
    assert Manifest.org_slug(Manifest.org_id(:acme)) == :acme
  end

  test "hero ticket numbers and correlation id" do
    assert Manifest.ticket_number(:hero_close) == 4521
    assert Manifest.ticket_number(:hero_delete) == 4518
    assert Manifest.correlation_id(:acme_4521_close) == "walk-acme-4521-close"
  end

  test "demo_seed_password/0 reads config default" do
    assert Manifest.demo_seed_password() == "password123456"
  end

  defp verify_manifest_config(_context) do
    assert Application.get_env(:threadline_phoenix, :demo_epoch) == ~U[2026-05-27 12:00:00Z]
    assert Application.get_env(:threadline_phoenix, :demo_seed_password) == "password123456"
    :ok
  end

  test "last_tuesday/0 is seven days before epoch at 14:30 UTC" do
    assert Manifest.last_tuesday() == ~U[2026-05-20 14:30:00Z]
  end
end
