defmodule Threadline.Test.PropertyRuns do
  @moduledoc """
  Reads `THREADLINE_PROPERTY_SCALE` at runtime — never a module attribute.
  `test/support` is compiled once, so a module attribute would freeze the
  value at the moment this file was compiled; any later (or earlier) change
  to the environment variable, including a CI step that exports it only
  before `mix test` runs, would be silently ignored.

  Pure properties use a `base` of 150-200 (`pure/1`). DB-backed properties
  use a `base` of at most 20 (`db/1`), because every iteration there drives
  real DDL or real queries, not just in-memory computation. The scale knob
  is one variable, not two — the DB cap (`min(scale(), 3)`) is a code
  decision, not something an operator tunes per run.
  """

  @env_var "THREADLINE_PROPERTY_SCALE"

  @doc "The environment variable name this module reads."
  def env_var, do: @env_var

  @doc """
  Parses the raw (string or nil) env value into an integer scale.

  `nil` (the variable unset) gives `1`. Only the literal integers `1`..`10`
  are accepted; anything else — `""`, `"0"`, `"-1"`, `"5x"`, `"5.0"`, `"11"`
  — raises `ArgumentError` naming #{@env_var} and the accepted range.
  """
  def parse_scale(nil), do: 1

  def parse_scale(raw) when is_binary(raw) do
    case Integer.parse(raw) do
      {n, ""} when n in 1..10 ->
        n

      _ ->
        raise ArgumentError,
              "#{@env_var} must be an integer in 1..10, got: #{inspect(raw)}"
    end
  end

  @doc "Reads #{@env_var} from the environment on every call and parses it."
  def scale, do: parse_scale(System.get_env(@env_var))

  @doc "A pure property's max_runs: base (150-200) multiplied by the scale."
  def pure(base) when base in 1..200, do: base * scale()

  @doc "A DB-backed property's max_runs: base (<=20) multiplied by min(scale, 3)."
  def db(base) when base in 1..200, do: base * min(scale(), 3)
end
