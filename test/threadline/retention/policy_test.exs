defmodule Threadline.Retention.PolicyTest do
  use ExUnit.Case, async: true

  alias Threadline.Retention.Policy

  test "validate_config!/1 accepts positive keep_days" do
    assert :ok = Policy.validate_config!(keep_days: 7, enabled: false)
  end

  test "validate_config!/1 accepts max_age_seconds alone" do
    assert :ok = Policy.validate_config!(max_age_seconds: 3600, enabled: false)
  end

  test "validate_config!/1 rejects both window keys" do
    assert_raise ArgumentError, fn ->
      Policy.validate_config!(keep_days: 1, max_age_seconds: 10, enabled: false)
    end
  end

  test "validate_config!/1 rejects non-positive keep_days" do
    err =
      assert_raise ArgumentError, fn ->
        Policy.validate_config!(keep_days: 0, enabled: false)
      end

    assert err.message =~ "retention"
  end

  test "resolution ignores extra keys and accepts recognized string spellings" do
    policy =
      Policy.resolve!(%{
        "unknown" => :ignored,
        enabled: false,
        keep_days: 2,
        extra_atom: true
      })

    assert policy.enabled == false
    assert policy.window_seconds == 172_800
  end

  test "config_map/0 admits arbitrary values for ignored string keys" do
    assert {:ok, types} = Code.Typespec.fetch_types(Policy)

    {:type, {:config_map, {:type, _, :union, arms}, []}} =
      Enum.find(types, fn
        {:type, {:config_map, _, []}} -> true
        _other -> false
      end)

    assert Enum.any?(arms, fn
             {:type, _, :map,
              [
                {:type, _, :map_field_assoc,
                 [
                   {:remote_type, _, [{:atom, _, String}, {:atom, _, :t}, []]},
                   {:type, _, :term, []}
                 ]}
              ]} ->
               true

             _other ->
               false
           end)
  end

  test "atom boolean keys take precedence over their string spellings" do
    policy =
      Policy.resolve!(%{
        "enabled" => "true",
        "delete_empty_transactions" => "false",
        "keep_days" => 3,
        enabled: false,
        delete_empty_transactions: true
      })

    assert policy.enabled == false
    assert policy.delete_empty_transactions == true
  end

  test "invalid atom boolean values do not fall back to valid string values" do
    enabled_error =
      assert_raise ArgumentError, fn ->
        Policy.resolve!(%{"enabled" => "true", "keep_days" => 2, enabled: :invalid})
      end

    assert enabled_error.message =~ ":enabled must be boolean"

    delete_empty_error =
      assert_raise ArgumentError, fn ->
        Policy.resolve!(%{
          "delete_empty_transactions" => "false",
          "keep_days" => 2,
          delete_empty_transactions: :invalid
        })
      end

    assert delete_empty_error.message =~ ":delete_empty_transactions must be boolean"
  end

  test "atom window values take precedence over their string spellings" do
    assert Policy.resolve!(%{"keep_days" => 1, keep_days: 2}).window_seconds == 172_800
    assert Policy.resolve!(%{"max_age_seconds" => 9, max_age_seconds: 4}).window_seconds == 4
  end

  test "nil and false atom window values fall back to their string spellings" do
    for fallback <- [nil, false] do
      assert Policy.resolve!(%{"keep_days" => 3, keep_days: fallback}).window_seconds == 259_200

      assert Policy.resolve!(%{"max_age_seconds" => 5, max_age_seconds: fallback}).window_seconds ==
               5
    end
  end

  test "truthy invalid windows and conflicting positive windows keep their errors" do
    invalid_window =
      assert_raise ArgumentError, fn ->
        Policy.resolve!(%{"keep_days" => 2, keep_days: 0})
      end

    assert invalid_window.message =~ ":keep_days must be positive"

    conflict =
      assert_raise ArgumentError, fn ->
        Policy.resolve!(%{"max_age_seconds" => 10, keep_days: 1})
      end

    assert conflict.message =~ "use only one of :keep_days or :max_age_seconds"
  end

  test "cutoff_utc_datetime_usec!/1 is strictly before now" do
    cutoff =
      Policy.cutoff_utc_datetime_usec!(policy: Policy.resolve!(keep_days: 1, enabled: false))

    assert DateTime.compare(cutoff, DateTime.utc_now(:microsecond)) == :lt
  end
end
