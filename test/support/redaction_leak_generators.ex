defmodule Threadline.Test.RedactionLeakGenerators do
  @moduledoc """
  StreamData generator for PROP-04 (D-08/D-09): operation plans that carry
  escape-proof canaries through INSERT/UPDATE/DELETE steps on the
  `prop_redaction_leak` fixture table.

  ## Canary shape (D-08)

  `canary(slot, step)` is `"ZQXSECRET_" <> slot <> "_s" <> step <> "_ZQX"`.
  It uses only `[A-Z0-9_]`, so its bytes survive Jason encoding, CSV
  quoting, and jsonb text identically. It is deterministic per slot and
  step, so seed replay holds and shrinking cannot reduce it to something
  that collides with a uuid, timestamp, table name, or the `"[REDACTED]"`
  placeholder. The step index makes consecutive values differ, so every
  "touch" step really puts the column in `changed_fields`.

  `plain_marker(step)` is the positive-control twin:
  `"ZQXVISIBLE_plain_s" <> step <> "_ZQX"`. It must appear on every surface a
  change touches, so a missing trigger (which would otherwise make
  `LeakOracle.refute_canaries!/3` pass vacuously) cannot pass silently.

  ## Value bias for a redacted slot, by `frequency` (D-08)

  About 70%: `prefix <> canary <> padding <> suffix`, with `prefix`/`suffix`
  drawn from a small pool of hostile wrapper shapes (quote, comma, CRLF,
  multibyte, a JSON-looking fragment, the placeholder itself) and an
  occasional 1-4 KB `"p"` padding, so canaries, JSON escaping, CSV quoting,
  multibyte text, and oversized values are all exercised. About 10% each:
  `nil`, `""`, and exactly `"[REDACTED]"` — these get **structural checks
  only** (no substring search is meaningful for them, per D-08), so no
  canary token is recorded for that slot/step.

  `profile_masked` always nests its value as `%{"k" => v, "l" => [v]}`
  (stored as SQL NULL when `v` is `nil`), per D-07.

  ## Operation plan per iteration (D-09)

  An INSERT (step 0), then 1-4 steps, each `frequency`-picked:
  `{5, touch_redacted}` (a non-empty subset of the three redacted columns,
  biased toward subsets that include both `secret_excluded` and
  `secret_masked`), `{2, touch_plain_only}` (only `bio` changes), `{1,
  noop_update}` (every column resent unchanged — the trigger still fires,
  since the capture trigger carries no `WHEN` clause). About a third of
  plans end in a DELETE. `paired` is `nil` or a 0-based step index `i` such
  that steps `i` and `i+1` run inside one `Repo.transaction`, exercising the
  same-txid upsert in `transaction_capture_begin_sql/1`.

  `include_action_metadata` is a generated boolean threaded into the CSV
  export call.
  """

  use ExUnitProperties

  @placeholder "[REDACTED]"
  @redacted_slots [:secret_excluded, :secret_masked, :profile_masked]

  # Hostile wrapper shapes a redacted/plain value's generated token is
  # embedded in: empty, the placeholder itself (tests "placeholder as
  # substring" without being the exact placeholder), a bare comma or quote
  # (CSV/JSON escaping), a lone CRLF, an emoji and an accented letter
  # (multibyte), a backslash, and a JSON-looking fragment.
  @hostile_pool ["", "[REDACTED]", ",", "\"", "\r\n", "😀", "é", "\\", "{\"a\":1}"]

  @doc ~s|The canary for one redacted slot ("excluded", "masked", or "profile") at one step.|
  def canary(slot, step) when slot in ["excluded", "masked", "profile"] and is_integer(step) do
    "ZQXSECRET_" <> slot <> "_s" <> Integer.to_string(step) <> "_ZQX"
  end

  @doc "The plain positive-control marker for one step."
  def plain_marker(step) when is_integer(step) do
    "ZQXVISIBLE_plain_s" <> Integer.to_string(step) <> "_ZQX"
  end

  @doc """
  Every bare canary token this plan actually plants (one entry per
  slot/step where the generated value was the 70% "wrapped" case; `nil`,
  `""`, and exact-placeholder slots plant no canary token).
  """
  def canaries(plan) do
    insert_canaries = @redacted_slots |> Enum.map(&token(Map.fetch!(plan.insert, &1)))

    step_canaries =
      Enum.flat_map(plan.steps, fn
        %{kind: :touch_redacted, values: values} -> values |> Map.values() |> Enum.map(&token/1)
        _ -> []
      end)

    (insert_canaries ++ step_canaries) |> Enum.reject(&is_nil/1) |> Enum.uniq()
  end

  @doc "Every plain marker this plan actually plants (one per write to `bio`)."
  def markers(plan) do
    insert_marker = token(plan.insert.bio)

    step_markers =
      Enum.flat_map(plan.steps, fn
        %{kind: :touch_redacted, bio: bio} -> [token(bio)]
        %{kind: :touch_plain_only, bio: bio} -> [token(bio)]
        %{kind: :noop_update} -> []
      end)

    ([insert_marker] ++ step_markers) |> Enum.reject(&is_nil/1) |> Enum.uniq()
  end

  @doc "The written value (first element) of a `{value, token}` pair produced by this module."
  def value({value, _token}), do: value

  defp token({_value, token}), do: token

  @doc """
  The full D-08/D-09 operation plan generator: an insert, 1-4 steps,
  an optional paired-transaction index, an optional trailing delete, and a
  generated `include_action_metadata` boolean for the CSV export call.
  """
  def op_plan_gen do
    gen all(
          insert <- insert_gen(),
          steps <- steps_gen(),
          paired <- paired_gen(length(steps)),
          delete? <- delete_gen(),
          include_action_metadata <- boolean()
        ) do
      %{
        insert: insert,
        steps: steps,
        paired: paired,
        delete?: delete?,
        include_action_metadata: include_action_metadata
      }
    end
  end

  defp insert_gen do
    gen all(
          excluded <- redacted_value_gen(:secret_excluded, 0),
          masked <- redacted_value_gen(:secret_masked, 0),
          profile <- redacted_value_gen(:profile_masked, 0),
          bio <- plain_value_gen(0)
        ) do
      %{secret_excluded: excluded, secret_masked: masked, profile_masked: profile, bio: bio}
    end
  end

  defp steps_gen do
    bind(integer(1..4), fn count ->
      1..count |> Enum.map(&step_gen/1) |> StreamData.fixed_list()
    end)
  end

  defp step_gen(step) do
    frequency([
      {5, touch_redacted_gen(step)},
      {2, touch_plain_only_gen(step)},
      {1, constant(%{kind: :noop_update})}
    ])
  end

  defp touch_redacted_gen(step) do
    gen all(
          slots <- redacted_subset_gen(),
          slot_results <-
            slots |> Enum.map(&redacted_value_gen(&1, step)) |> StreamData.fixed_list(),
          bio <- plain_value_gen(step)
        ) do
      values = slots |> Enum.zip(slot_results) |> Map.new()
      %{kind: :touch_redacted, values: values, bio: bio}
    end
  end

  defp touch_plain_only_gen(step) do
    gen all(bio <- plain_value_gen(step)) do
      %{kind: :touch_plain_only, bio: bio}
    end
  end

  # Biased toward subsets containing both secret_excluded and
  # secret_masked (D-26's >=40%-of-plans coverage floor).
  defp redacted_subset_gen do
    frequency([
      {5, constant([:secret_excluded, :secret_masked])},
      {2, constant([:secret_excluded, :secret_masked, :profile_masked])},
      {1, map(member_of(@redacted_slots), &[&1])},
      {1, member_of([[:secret_excluded, :profile_masked], [:secret_masked, :profile_masked]])}
    ])
  end

  defp paired_gen(count) when count < 2, do: constant(nil)

  defp paired_gen(count) do
    frequency([
      {3, constant(nil)},
      {1, integer(0..(count - 2))}
    ])
  end

  defp delete_gen, do: frequency([{1, constant(true)}, {2, constant(false)}])

  defp redacted_value_gen(slot, step) do
    frequency([
      {7, wrapped_value_gen(slot, step)},
      {1, constant({nil, nil})},
      {1, constant({"", nil})},
      {1, constant({@placeholder, nil})}
    ])
  end

  defp wrapped_value_gen(slot, step) do
    gen all(
          prefix <- member_of(@hostile_pool),
          suffix <- member_of(@hostile_pool),
          pad <- padding_gen()
        ) do
      token = canary(slot_name(slot), step)
      {prefix <> token <> pad <> suffix, token}
    end
  end

  defp plain_value_gen(step) do
    gen all(
          prefix <- member_of(@hostile_pool),
          suffix <- member_of(@hostile_pool)
        ) do
      token = plain_marker(step)
      {prefix <> token <> suffix, token}
    end
  end

  defp padding_gen do
    frequency([
      {4, constant("")},
      {1, map(integer(1024..4096), &String.duplicate("p", &1))}
    ])
  end

  defp slot_name(:secret_excluded), do: "excluded"
  defp slot_name(:secret_masked), do: "masked"
  defp slot_name(:profile_masked), do: "profile"
end
