defmodule ThreadlinePhoenix.Demo.Seed do
  @moduledoc """
  Plants deterministic demo fiction for walkthroughs (`mix demo.seed`).

  Hybrid synthesis: Sigra personas, anchor incidents, PRNG filler, temporal backfill.
  """

  alias ThreadlinePhoenix.Demo.{Reset, Seed}

  @doc """
  Runs the full demo seed pipeline (D-107-04).
  """
  @spec run() :: :ok
  def run do
    Reset.assert_dev_or_allowed!()
    :rand.seed(:exsss, {1, 2, 3})

    ctx = %{timestamps: %{}}

    ctx =
      ctx
      |> Seed.Personas.run()
      |> Seed.Anchors.run()
      |> Seed.Filler.run()
      |> Seed.Temporal.run()
      |> Seed.RetentionTail.run()

    _ctx = ctx
    Mix.shell().info("demo.seed complete")
    :ok
  end
end
