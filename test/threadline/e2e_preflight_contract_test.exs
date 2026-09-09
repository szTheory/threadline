defmodule Threadline.E2ePreflightContractTest do
  use ExUnit.Case, async: true

  @script "examples/threadline_phoenix/e2e/run-e2e.sh"

  test "relative and same-origin login redirects pass with normalized default ports" do
    for {base, location} <- [
          {"http://127.0.0.1:4002", "/users/log_in"},
          {"http://127.0.0.1:4002", "/users/log_in?return=%2Faudit#form"},
          {"http://example.test", "http://example.test:80/users/log_in"},
          {"https://example.test:443", "https://EXAMPLE.test/users/log_in?next=audit"}
        ] do
      result = run_preflight(base, 302, [{"Location", location}], "")
      assert result.status == 0, "expected #{location} to pass: #{result.output}"
      assert result.playwright_started
    end
  end

  test "cross-origin and ambiguous login-looking redirects fail before Playwright" do
    invalid = [
      "//example.test/users/log_in",
      "https://foreign.test/users/log_in",
      "http://example.test:81/users/log_in",
      "http://example.test@foreign.test/users/log_in",
      "http://example.test\\@foreign.test/users/log_in",
      "http://example.test/users/log_in\tignored",
      "http://example.test/users/log_in/extra",
      "http://example.test/prefix/users/log_in"
    ]

    for location <- invalid do
      result = run_preflight("http://example.test", 302, [{"Location", location}], "")
      assert result.status != 0, "expected #{inspect(location)} to fail"
      refute result.playwright_started, "Playwright sentinel ran for rejected #{inspect(location)}"
    end
  end

  test "missing or multiple Location headers and empty BASE_URL fail" do
    missing = run_preflight("http://example.test", 302, [], "")
    assert missing.status != 0
    refute missing.playwright_started

    multiple =
      run_preflight("http://example.test", 302, [
        {"Location", "/users/log_in"},
        {"Location", "http://foreign.test/users/log_in"}
      ], "")

    assert multiple.status != 0
    refute multiple.playwright_started

    empty_base = run_preflight("", 302, [{"Location", "/users/log_in"}], "")
    assert empty_base.status != 0
    refute empty_base.playwright_started
  end

  test "2xx requires both operator shell markers" do
    passing = run_preflight("http://example.test", 200, [], ~s(<main class="threadline-ui" id="tl-main">))
    assert passing.status == 0
    assert passing.playwright_started

    for body <- ["", "threadline-ui", "tl-main"] do
      result = run_preflight("http://example.test", 200, [], body)
      assert result.status != 0
      refute result.playwright_started
    end
  end

  test "preflight never asks curl to follow redirects" do
    source = File.read!(@script)
    refute source =~ ~r/"?\$CURL_BIN"?[^\n]*\s-L\b/
  end

  defp run_preflight(base, status, headers, body) do
    fixture_dir = Path.join(System.tmp_dir!(), "threadline-preflight-#{System.unique_integer([:positive])}")
    File.mkdir_p!(fixture_dir)
    curl = Path.join(fixture_dir, "curl-fixture")
    sentinel = Path.join(fixture_dir, "playwright-sentinel")
    marker = Path.join(fixture_dir, "playwright-started")

    File.write!(
      curl,
      "#!/bin/sh\n" <>
        "printf 'HTTP/1.1 %s Synthetic\\r\\n' \"$FIXTURE_STATUS\"\n" <>
        "printf '%s' \"$FIXTURE_HEADERS\"\n" <>
        "printf '\\r\\n%s\\n__HTTP_CODE__%s' \"$FIXTURE_BODY\" \"$FIXTURE_STATUS\"\n"
    )

    File.write!(sentinel, "#!/bin/sh\ntouch \"$PLAYWRIGHT_MARKER\"\n")
    File.chmod!(curl, 0o700)
    File.chmod!(sentinel, 0o700)

    header_text = Enum.map_join(headers, "", fn {name, value} -> "#{name}: #{value}\r\n" end)

    {output, exit_status} =
      System.cmd("bash", [@script],
        stderr_to_stdout: true,
        env: [
          {"THREADLINE_E2E_PREFLIGHT_ONLY", "1"},
          {"THREADLINE_E2E_CURL", curl},
          {"THREADLINE_E2E_PLAYWRIGHT_SENTINEL", sentinel},
          {"PLAYWRIGHT_MARKER", marker},
          {"E2E_BASE_URL", base},
          {"FIXTURE_STATUS", Integer.to_string(status)},
          {"FIXTURE_HEADERS", header_text},
          {"FIXTURE_BODY", body}
        ]
      )

    result = %{status: exit_status, output: output, playwright_started: File.exists?(marker)}
    File.rm_rf!(fixture_dir)
    result
  end
end
