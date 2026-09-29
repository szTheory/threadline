defmodule Threadline.Test.CiIssuePairing do
  @moduledoc """
  218 review WR-06: a CI tracking-issue lane has an open step and a close step,
  and `bin/upsert-ci-issue --close` finds the issue only by the open step's
  `TITLE_PREFIX` marker and `LABEL`. Comparing the close step to a hard-coded
  literal lets a rename of the open step pass while every close answers
  `action=none`, so tracking issues stop closing (the #28/#36 failure mode
  ECON-02 fixed). These checks derive both values from the open step instead.
  """

  @keys ["TITLE_PREFIX", "LABEL"]

  @doc """
  Returns every pairing violation between the step named `open_step` and the
  step named `close_step` in `yaml`; `[]` means the close step targets exactly
  the issue the open step files.
  """
  def violations(yaml, open_step, close_step) do
    open = step_body(yaml, open_step)
    close = step_body(yaml, close_step)

    cond do
      is_nil(open) ->
        ["no `#{open_step}` step"]

      is_nil(close) ->
        ["no `#{close_step}` step"]

      true ->
        value_checks =
          for key <- @keys do
            open_value = env_value(open, key)
            close_value = env_value(close, key)

            {not is_nil(open_value) and open_value == close_value,
             "close step #{key} (#{inspect(close_value)}) must equal the open step's " <>
               "(#{inspect(open_value)}); otherwise --close finds no issue (action=none)"}
          end

        [
          {open =~ ~s(--marker "$TITLE_PREFIX") and open =~ ~s(--label "$LABEL"),
           "open step must pass --marker \"$TITLE_PREFIX\" and --label \"$LABEL\""},
          {close =~ ~s(--close --marker "$TITLE_PREFIX" --label "$LABEL"),
           "close step must pass --close --marker \"$TITLE_PREFIX\" --label \"$LABEL\""}
          | value_checks
        ]
        |> Enum.reject(&elem(&1, 0))
        |> Enum.map(&elem(&1, 1))
    end
  end

  # The step whose `- name:` is `name`, up to the next step at the same indent.
  defp step_body(yaml, name) do
    case String.split(yaml, "- name: #{name}\n", parts: 2) do
      [_, rest] -> rest |> String.split(~r/\n      - /, parts: 2) |> hd()
      [_] -> nil
    end
  end

  defp env_value(body, key) do
    case Regex.run(~r/^\s+#{key}:\s*(.+?)\s*$/m, body) do
      [_, value] -> value
      nil -> nil
    end
  end
end
