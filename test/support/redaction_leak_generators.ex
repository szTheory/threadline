defmodule Threadline.Test.RedactionLeakGenerators do
  @moduledoc """
  StreamData generator for PROP-04 (D-08/D-09): operation plans that carry
  escape-proof canaries through INSERT/UPDATE/DELETE steps on the
  `prop_redaction_leak` fixture table.

  **Tracer stage (Task 1):** `op_plan_gen/0` yields one fixed-shape plan — an
  INSERT followed by one `touch_redacted` step, with a bare canary in every
  redacted slot and the bare plain marker in `bio`. Task 2 widens this to the
  full D-08/D-09 design (hostile wrappers, 1-4 steps, DELETE, paired
  transactions, nil/empty/placeholder redacted values).

  ## Canary shape (D-08)

  `canary(slot, step)` is `"ZQXSECRET_" <> slot <> "_s" <> step <> "_ZQX"`.
  It uses only `[A-Z0-9_]`, so its bytes survive Jason encoding, CSV quoting,
  and jsonb text identically. It is deterministic per slot and step, so seed
  replay holds and shrinking cannot reduce it to something that collides with
  a uuid, timestamp, table name, or the `"[REDACTED]"` placeholder.

  `plain_marker(step)` is the positive-control twin: `"ZQXVISIBLE_plain_s" <>
  step <> "_ZQX"`. It must appear on every surface a change touches, so a
  missing trigger (which would make `refute_canaries!/3` pass vacuously)
  cannot pass silently.
  """

  use ExUnitProperties

  @slots ["excluded", "masked", "profile"]

  @doc ~s|The canary for one redacted slot ("excluded", "masked", or "profile") at one step.|
  def canary(slot, step) when slot in ["excluded", "masked", "profile"] and is_integer(step) do
    "ZQXSECRET_" <> slot <> "_s" <> Integer.to_string(step) <> "_ZQX"
  end

  @doc "The plain positive-control marker for one step."
  def plain_marker(step) when is_integer(step) do
    "ZQXVISIBLE_plain_s" <> Integer.to_string(step) <> "_ZQX"
  end

  @doc "Every bare canary this plan plans to write, across the insert and every step."
  def canaries(plan) do
    [plan.insert | Enum.map(plan.steps, &elem(&1, 1))]
    |> Enum.flat_map(fn values -> Enum.map(@slots, &slot_canary(values, &1)) end)
    |> Enum.uniq()
  end

  defp slot_canary(values, "excluded"), do: canary_from(values.secret_excluded)
  defp slot_canary(values, "masked"), do: canary_from(values.secret_masked)
  defp slot_canary(values, "profile"), do: canary_from(values.profile_masked)

  # The bare canary always travels inside a redacted value for the tracer
  # stage; Task 2's hostile-wrapper frequency picker still embeds the exact
  # same bare token, so this extraction stays correct unchanged.
  defp canary_from(nil), do: nil
  defp canary_from(value), do: value

  @doc "Every plain marker this plan plans to write, across the insert and every step."
  def markers(plan) do
    [plan.insert | Enum.map(plan.steps, &elem(&1, 1))]
    |> Enum.map(& &1.bio)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  @doc """
  Tracer-stage plan generator (Task 1 only). Always: INSERT with step-0
  canaries/marker, then one `:touch_redacted` step with step-1
  canaries/marker. `delete?` is always `false`, `paired` is always `nil`.
  Task 2 replaces this body with the full D-08/D-09 `frequency`-driven design.
  """
  def op_plan_gen do
    gen all(_marker <- StreamData.constant(:ok)) do
      insert = step_values(0)
      step = step_values(1)
      %{insert: insert, steps: [{:touch_redacted, step}], delete?: false, paired: nil}
    end
  end

  defp step_values(step) do
    %{
      secret_excluded: canary("excluded", step),
      secret_masked: canary("masked", step),
      profile_masked: canary("profile", step),
      bio: plain_marker(step)
    }
  end
end
