defmodule Threadline.CommunityHealthContractTest do
  @moduledoc false
  use ExUnit.Case, async: true

  @forms [
    {".github/ISSUE_TEMPLATE/01-bug.yml", "Bug report", "bug"},
    {".github/ISSUE_TEMPLATE/02-feature-request.yml", "Feature request", "enhancement"},
    {".github/ISSUE_TEMPLATE/03-question.yml", "Question", "question"}
  ]
  @community_paths [
    ".github/ISSUE_TEMPLATE/01-bug.yml",
    ".github/ISSUE_TEMPLATE/02-feature-request.yml",
    ".github/ISSUE_TEMPLATE/03-question.yml",
    ".github/ISSUE_TEMPLATE/config.yml",
    ".github/pull_request_template.md",
    "SECURITY.md",
    "CODE_OF_CONDUCT.md"
  ]

  test "narrow issue-form validator rejects unsafe and stale intake shapes" do
    safe = """
    name: Bug report
    labels: [bug]
    assignees: []
    body:
      - type: textarea
        attributes:
          label: Reproduction
          description: Remove secrets, personal data, and production audit records.
    """

    assert issue_form_errors(safe, "Bug report", "bug") == []

    assert :public_security_route in issue_form_errors(
             safe <> "\nlabel: Public vulnerability report\n",
             "Bug report",
             "bug"
           )

    assert :stale_version_choice in issue_form_errors(
             safe <> "\noptions:\n  - 0.9.0\n",
             "Bug report",
             "bug"
           )

    assert :unknown_label in issue_form_errors(
             String.replace(safe, "[bug]", "[triage]"),
             "Bug report",
             "bug"
           )

    assert :automatic_assignee in issue_form_errors(
             String.replace(safe, "assignees: []", "assignees: [maintainer]"),
             "Bug report",
             "bug"
           )
  end

  @tag :contributor_flow
  @tag :phase200_red
  test "CONTRIBUTING leads with a newcomer-complete issue-to-PR flow" do
    doc = File.read!("CONTRIBUTING.md")
    assert byte_size(doc) > 0

    refute String.contains?(doc, ".planning/"),
           "CONTRIBUTING depends on internal planning history"

    refute Regex.match?(~r/\b(?:Phase\s+\d+|D-\d{2}|[A-Z]+-\d{2})\b/, doc)

    assert ordered?(doc, ["Communication", "Setup", "Running tests", "mix ci.all", "Pull request"]),
           "newcomer routing/setup/tests/full gate/PR submission are not ordered first"

    assert String.contains?(doc, "small") and String.contains?(doc, "pull request")
    assert String.contains?(doc, "discuss") and String.contains?(doc, "API")
  end

  @tag :contributor_troubleshooting
  @tag :phase200_red
  test "CONTRIBUTING exposes the exact missing-table repair route" do
    doc = File.read!("CONTRIBUTING.md")
    error = ~s|(undefined_table) relation "audit_changes" does not exist|
    assert String.contains?(doc, error), "missing exact searchable database error: #{error}"
    assert Regex.match?(~r/\[.+\]\(guides\/local-docker-dx\.md#[^)]+\)/, doc)
  end

  @tag :issue_security_tracer
  @tag :phase200_red
  test "issue forms and security chooser route sensitive reports privately" do
    for {path, name, label} <- @forms do
      assert File.regular?(path), "missing issue form #{path}"
      content = File.read!(path)
      assert String.trim(content) != "", "empty issue form #{path}"

      assert issue_form_errors(content, name, label) == [],
             "#{path}: #{inspect(issue_form_errors(content, name, label))}"
    end

    chooser = File.read!(".github/ISSUE_TEMPLATE/config.yml")
    assert Regex.match?(~r/blank_issues_enabled:\s*false/, chooser)
    refute String.contains?(String.downcase(chooser), "discussions")
    assert String.contains?(chooser, "SECURITY.md")

    security = File.read!("SECURITY.md")
    assert String.contains?(String.downcase(security), "private vulnerability reporting")
    refute Regex.match?(~r/(?:open|file|create).{0,30}public issue/is, security)
  end

  @tag :community_health
  @tag :phase200_red
  @tag :phase200_aggregate
  test "all community-health files are nonempty and keep support, security, and conduct distinct" do
    for path <- @community_paths do
      assert File.regular?(path), "missing community-health file #{path}"
      content = File.read!(path)
      assert String.trim(content) != "", "empty community-health file #{path}"

      refute Regex.match?(
               ~r/\b(?:TODO|FIXME|placeholder|Phase\s+\d+|D-\d{2}|SURFACE-\d+)\b/i,
               content
             ),
             "#{path} contains placeholder or planning vocabulary"

      refute String.contains?(String.downcase(content), "github discussions")
      refute String.contains?(content, "ANTHROPIC_API_KEY")
    end

    pr = File.read!(".github/pull_request_template.md")
    Enum.each(["Why", "What changed", "Verification"], &assert(String.contains?(pr, &1)))
    assert String.contains?(pr, "<!--") and String.contains?(String.downcase(pr), "vulnerab")

    conduct = File.read!("CODE_OF_CONDUCT.md")
    assert String.contains?(conduct, "Contributor Covenant")
    assert String.contains?(conduct, "https://support.github.com/contact/report-abuse")
    refute String.contains?(String.downcase(conduct), "security advisory")
  end

  defp issue_form_errors(content, expected_name, expected_label) do
    labels =
      case Regex.run(~r/^labels:\s*\[([^\]]*)\]/m, content) do
        [_, values] -> values |> String.split(",", trim: true) |> Enum.map(&String.trim/1)
        _ -> []
      end

    []
    |> maybe_add(
      not Regex.match?(~r/^name:\s*#{Regex.escape(expected_name)}\s*$/m, content),
      :wrong_name
    )
    |> maybe_add(
      labels != [expected_label] or expected_label not in ["bug", "enhancement", "question"],
      :unknown_label
    )
    |> maybe_add(not Regex.match?(~r/^assignees:\s*\[\]\s*$/m, content), :automatic_assignee)
    |> maybe_add(
      not Regex.match?(
        ~r/remove.{0,30}secrets.{0,40}(?:personal data|production audit records)/is,
        content
      ),
      :missing_privacy_warning
    )
    |> maybe_add(
      Regex.match?(
        ~r/public vulnerability|security vulnerability.{0,25}(?:issue|form)/is,
        content
      ),
      :public_security_route
    )
    |> maybe_add(
      Regex.match?(~r/options:\s*\n\s*-\s*v?\d+\.\d+/m, content),
      :stale_version_choice
    )
  end

  defp maybe_add(errors, true, error), do: errors ++ [error]
  defp maybe_add(errors, false, _error), do: errors

  defp ordered?(content, terms) do
    positions =
      Enum.map(terms, fn term ->
        :binary.match(String.downcase(content), String.downcase(term))
      end)

    if Enum.all?(positions, &match?({_, _}, &1)) do
      offsets = Enum.map(positions, &elem(&1, 0))
      offsets == Enum.sort(offsets)
    else
      false
    end
  end
end
