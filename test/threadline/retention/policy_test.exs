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

  test "cutoff_utc_datetime_usec!/1 is strictly before now" do
    cutoff =
      Policy.cutoff_utc_datetime_usec!(policy: Policy.resolve!(keep_days: 1, enabled: false))

    assert DateTime.compare(cutoff, DateTime.utc_now(:microsecond)) == :lt
  end
end
