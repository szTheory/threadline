defmodule Threadline.Mix.MigrationsPath do
  @moduledoc false

  # Both generator tasks must write into, and look for existing migrations in,
  # the same directory, so they share this one resolver. It is resolved here
  # rather than through Ecto because Ecto.Migrator's own helper returns a path
  # inside _build (the compiled app), and the task helper in ecto_sql that
  # reads the source tree is private.
  #
  # Precedence: an explicit --migrations-path (used as given, relative to the
  # current directory, without loading any repo), then the repo's :priv
  # directory, then priv/<underscored repo name>/migrations, then
  # priv/repo/migrations when no repo is configured at all.

  @default "priv/repo/migrations"

  @doc false
  @spec resolve(keyword()) :: Path.t()
  def resolve(opts) do
    case Keyword.get_values(opts, :repo) do
      [_, _ | _] ->
        Mix.raise("--repo may be given once; Threadline audit tables live in one repo")

      _ ->
        :ok
    end

    cond do
      path = opts[:migrations_path] -> path
      name = opts[:repo] -> name |> explicit_repo() |> repo_migrations_path()
      true -> default_repo_path()
    end
  end

  # A repo named on the command line must load; falling back to a default
  # directory would write the migrations somewhere the user did not ask for.
  defp explicit_repo(name) do
    repo = Module.concat([name])

    unless Code.ensure_loaded?(repo) and function_exported?(repo, :config, 0) do
      Mix.raise("--repo #{inspect(repo)} could not be loaded; pass a compiled Ecto repo module")
    end

    repo
  end

  # The first configured repo of the current app. With no app (an umbrella
  # root) or no :ecto_repos, the conventional directory is used. A configured
  # repo that cannot be loaded or read also falls back to it, as the install
  # task always has, but with a warning naming the repo so the fallback is not
  # silent: that directory may not be the one `mix ecto.migrate` reads.
  defp default_repo_path do
    app = Keyword.get(Mix.Project.config(), :app)

    case app && Application.get_env(app, :ecto_repos, []) do
      [repo | _] -> configured_repo_path(repo)
      _ -> @default
    end
  end

  defp configured_repo_path(repo) do
    if is_atom(repo) and Code.ensure_loaded?(repo) and function_exported?(repo, :config, 0) do
      try do
        repo_migrations_path(repo)
      rescue
        e -> fall_back(repo, "its config raised: " <> Exception.message(e))
      end
    else
      fall_back(repo, "it could not be loaded or does not define config/0")
    end
  end

  defp fall_back(repo, reason) do
    Mix.shell().error(
      "warning: could not read the first :ecto_repos entry, #{inspect(repo)}: #{reason}. " <>
        "Using #{@default}, which may not be the directory `mix ecto.migrate` reads " <>
        "for that repo. Fix the repo or pass --repo or --migrations-path."
    )

    @default
  end

  defp repo_migrations_path(repo) do
    case repo.config()[:priv] do
      nil ->
        Path.join(
          "priv/" <> (repo |> Module.split() |> List.last() |> Macro.underscore()),
          "migrations"
        )

      priv ->
        Path.join(priv, "migrations")
    end
  end
end
