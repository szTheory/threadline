defmodule DepsAuditFixture.MixProject do
  @moduledoc false
  use Mix.Project

  def project do
    [
      app: :deps_audit_fixture,
      version: "0.1.0",
      deps: deps()
    ]
  end

  defp deps do
    [
      {:plug, "== 1.19.1"}
    ]
  end
end
