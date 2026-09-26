defmodule Threadline.Mix.MigrationsPathTest do
  # async: false — these tests rewrite the VM-wide :threadline :ecto_repos env.
  use ExUnit.Case, async: false

  alias Threadline.Mix.MigrationsPath

  @custom "Threadline.TestSupport.CustomPrivRepo"
  @no_priv "Threadline.TestSupport.NoPrivRepo"

  setup do
    previous = Application.fetch_env(:threadline, :ecto_repos)
    previous_shell = Mix.shell()
    Mix.shell(Mix.Shell.Process)

    on_exit(fn ->
      Mix.shell(previous_shell)

      case previous do
        {:ok, value} -> Application.put_env(:threadline, :ecto_repos, value)
        :error -> Application.delete_env(:threadline, :ecto_repos)
      end
    end)

    :ok
  end

  describe "--migrations-path" do
    test "is returned as given and the repo is never loaded" do
      assert MigrationsPath.resolve(migrations_path: "x/y", repo: "Does.Not.Exist") == "x/y"
    end
  end

  describe "--repo" do
    test "uses the repo's :priv directory" do
      assert MigrationsPath.resolve(repo: @custom) == "priv/custom_repo/migrations"
    end

    test "without :priv uses priv/<underscored repo name>/migrations" do
      assert MigrationsPath.resolve(repo: @no_priv) == "priv/no_priv_repo/migrations"
    end

    test "given twice raises" do
      assert_raise Mix.Error,
                   "--repo may be given once; Threadline audit tables live in one repo",
                   fn -> MigrationsPath.resolve(repo: "A", repo: "B") end
    end

    test "that cannot be loaded raises naming the module" do
      assert_raise Mix.Error, ~r/Does\.Not\.Exist/, fn ->
        MigrationsPath.resolve(repo: "Does.Not.Exist")
      end
    end
  end

  describe "the configured repo" do
    test "uses the first :ecto_repos entry's :priv directory" do
      Application.put_env(:threadline, :ecto_repos, [Threadline.TestSupport.CustomPrivRepo])

      assert MigrationsPath.resolve([]) == "priv/custom_repo/migrations"
    end

    test "falls back to priv/repo/migrations when no repo is configured" do
      Application.put_env(:threadline, :ecto_repos, [])

      assert MigrationsPath.resolve([]) == "priv/repo/migrations"
    end

    test "falls back to priv/repo/migrations when :ecto_repos is unset" do
      Application.delete_env(:threadline, :ecto_repos)

      assert MigrationsPath.resolve([]) == "priv/repo/migrations"
    end

    test "an entry that cannot be loaded falls back with a warning naming the repo" do
      Application.put_env(:threadline, :ecto_repos, [Does.Not.Exist])

      assert MigrationsPath.resolve([]) == "priv/repo/migrations"
      assert_received {:mix_shell, :error, [warning]}
      assert warning =~ ~r/:ecto_repos entry, Does\.Not\.Exist: it could not be loaded/
      assert warning =~ "Using priv/repo/migrations"
    end

    test "an entry whose config raises falls back with a warning naming the repo and cause" do
      Application.put_env(:threadline, :ecto_repos, [Threadline.TestSupport.BrokenConfigRepo])

      assert MigrationsPath.resolve([]) == "priv/repo/migrations"
      assert_received {:mix_shell, :error, [warning]}
      assert warning =~ ~r/BrokenConfigRepo.*no :otp_app config/
    end

    test "a loadable entry resolves without a warning" do
      Application.put_env(:threadline, :ecto_repos, [Threadline.TestSupport.CustomPrivRepo])

      assert MigrationsPath.resolve([]) == "priv/custom_repo/migrations"
      refute_received {:mix_shell, :error, _}
    end

    test "--migrations-path never loads a broken configured repo" do
      Application.put_env(:threadline, :ecto_repos, [Does.Not.Exist])

      assert MigrationsPath.resolve(migrations_path: "x/y") == "x/y"
    end

    test "the test repo, which sets no :priv, resolves to priv/repo/migrations" do
      Application.put_env(:threadline, :ecto_repos, [Threadline.Test.Repo])

      assert MigrationsPath.resolve([]) == "priv/repo/migrations"
    end
  end
end
