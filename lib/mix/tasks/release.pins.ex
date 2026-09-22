defmodule Mix.Tasks.Release.Pins do
  # Rewrites every documented Threadline install pin from `mix.exs` `@version`.
  #
  # Maintainer-only tooling, so `@moduledoc false` and no `@shortdoc`: this
  # task rewrites tracked repository documentation and has no meaning inside an
  # adopter's application. It is also excluded from the published Hex package
  # (see `package[:exclude_patterns]` in `mix.exs`), because a `@shortdoc`-
  # bearing maintainer task appears in every adopter's `mix help` under a
  # namespace that is not this library's. Both the module doc and the package
  # exclusion are needed: the first keeps it off the rendered documentation
  # surface, the second keeps it out of the shipped archive.
  #
  # Usage:
  #
  #     mix release.pins
  #     mix release.pins --check
  #
  # `--check` writes nothing and exits non-zero when any pin would change, so
  # the task doubles as a gate.
  #
  # Why the floor stops at the minor: the pin written into documentation is
  # `major.minor.0` derived from `@version`. A three-segment floor admits the
  # whole patch series of that minor and stops there, so a patch release is a
  # provable no-op — the derived string does not change. A two-segment pin
  # would admit any later minor and therefore silently route adopters of a
  # pre-1.0 library into future breaking releases.
  #
  # Why release automation must never own a pin line: the generic updater
  # writes the FULL version onto a marked line, which would emit a pin one
  # patch ahead of what the documentation contract derives; and the component
  # updater replaces the first bare integer on the line, which inside the
  # compound requirement string is the leading digit of the version, producing
  # a nonsense major. Both are dead ends, so this task is the owner instead.
  # That separation is enforced by the version-truth documentation contract,
  # not by convention.
  @moduledoc false

  use Mix.Task

  # The glob and the regex below are deliberately duplicated from
  # test/threadline/version_truth_doc_contract_test.exs rather than extracted
  # into a shared module. A shared module would be new production surface for a
  # release-time-only concern, and the duplication is self-policing: the
  # contract test goes red the moment this task and the contract disagree about
  # which lines count. Do not "fix" this by extracting it — keep the two
  # expressions character-identical instead.
  @pin_regex ~r/\{:threadline,\s*"~>\s*([0-9][0-9.]*)"\}/

  @impl Mix.Task
  def run(args) do
    {opts, argv, invalid} = OptionParser.parse(args, strict: [check: :boolean])

    unless invalid == [] and argv == [] do
      Mix.raise("mix release.pins accepts no arguments and only the --check switch")
    end

    check? = Keyword.get(opts, :check, false)
    target = target_pin_version()
    files = doc_files()

    Mix.shell().info(
      "release.pins: mix.exs @version is #{current_version()}, derived install pin is " <>
        "`~> #{target}`"
    )

    pending = Enum.flat_map(files, &pending_change(&1, target))

    Enum.each(pending, fn {path, from, to} ->
      Mix.shell().info("  #{path}: `~> #{from}` -> `~> #{to}`")
    end)

    Mix.shell().info(
      "release.pins: scanned #{length(files)} file(s); " <>
        "#{length(pending)} pin site(s) differ from the derived pin"
    )

    cond do
      pending == [] ->
        Mix.shell().info("release.pins: no changes — every install pin already reads the")
        Mix.shell().info("release.pins: derived `~> #{target}`.")

      check? ->
        Mix.raise(
          "mix release.pins --check: #{length(pending)} install pin(s) do not match the " <>
            "derived `~> #{target}`. Run `mix release.pins` to rewrite them."
        )

      true ->
        rewritten = pending |> Enum.map(fn {path, _from, _to} -> path end) |> Enum.uniq()
        Enum.each(rewritten, &rewrite_file!(&1, target))

        Mix.shell().info("release.pins: rewrote #{length(rewritten)} file(s).")
    end
  end

  # README + guides only, matching the documentation contract's glob exactly. A
  # glob rather than an allowlist means a future guide that adds an install
  # snippet cannot silently slip past this task.
  defp doc_files do
    ["README.md" | Path.wildcard("guides/**/*.md")]
  end

  defp current_version, do: Mix.Project.config()[:version]

  # Read at runtime rather than frozen into a module attribute so that a bump
  # to mix.exs can never be shadowed by a stale compiled artifact.
  defp target_pin_version do
    parsed = Version.parse!(current_version())
    "#{parsed.major}.#{parsed.minor}.0"
  end

  defp pending_change(path, target) do
    for [_full, captured] <- Regex.scan(@pin_regex, File.read!(path)),
        captured != target,
        do: {path, captured, target}
  end

  defp rewrite_file!(path, target) do
    content = File.read!(path)

    # Rewrite only the captured version segment inside a matched pin. The rest
    # of the line — surrounding prose, table-cell markup, list markers — is left
    # byte-identical, which is what keeps the release-automation-owned prose
    # lines and the attestation row out of this task's blast radius.
    rewritten =
      Regex.replace(@pin_regex, content, fn full, captured ->
        if captured == target, do: full, else: String.replace(full, captured, target)
      end)

    File.write!(path, rewritten)
  end
end
