if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.RouterTest do
    use ExUnit.Case, async: true

    describe "threadline_operator_surface/2 macro validation" do
      test "Case 1: raises CompileError when called without pipe_through or explicit auth opts" do
        assert_raise CompileError,
                     ~r/Threadline Operator Surface must be mounted inside a secure pipeline\. Add `pipe_through :admin_browser` or explicitly provide an `:authorize_fn`\./,
                     fn ->
                       Code.compile_quoted(
                         quote do
                           defmodule Threadline.OperatorSurface.RouterTest.UnsafeMount do
                             use Phoenix.Router
                             require Threadline.OperatorSurface.Router

                             Threadline.OperatorSurface.Router.threadline_operator_surface(
                               "/threadline"
                             )
                           end
                         end
                       )
                     end
      end

      test "Case 2: compiles successfully with pipe_through" do
        modules =
          Code.compile_quoted(
            quote do
              defmodule Threadline.OperatorSurface.RouterTest.PipedMount do
                use Phoenix.Router
                require Threadline.OperatorSurface.Router

                pipeline :browser do
                  plug(:accepts, ["html"])
                end

                scope "/" do
                  pipe_through(:browser)
                  Threadline.OperatorSurface.Router.threadline_operator_surface("/threadline")
                end
              end
            end
          )

        # Cleanup compiled modules
        for {module, _} <- modules do
          :code.delete(module)
          :code.purge(module)
        end
      end

      test "Case 3: compiles successfully without pipe_through but with authorize_fn" do
        modules =
          Code.compile_quoted(
            quote do
              defmodule Threadline.OperatorSurface.RouterTest.AuthFnMount do
                use Phoenix.Router
                require Threadline.OperatorSurface.Router

                Threadline.OperatorSurface.Router.threadline_operator_surface("/threadline",
                  authorize_fn: &__MODULE__.auth/1
                )

                def auth(_), do: :ok
              end
            end
          )

        # Cleanup compiled modules
        for {module, _} <- modules do
          :code.delete(module)
          :code.purge(module)
        end
      end

      test "Case 4: compiles successfully without pipe_through but with adopter_acknowledges_unauthenticated" do
        modules =
          Code.compile_quoted(
            quote do
              defmodule Threadline.OperatorSurface.RouterTest.AckMount do
                use Phoenix.Router
                require Threadline.OperatorSurface.Router

                Threadline.OperatorSurface.Router.threadline_operator_surface("/threadline",
                  adopter_acknowledges_unauthenticated: true
                )
              end
            end
          )

        # Cleanup compiled modules
        for {module, _} <- modules do
          :code.delete(module)
          :code.purge(module)
        end
      end

      test "Case 5: compiles successfully with actor_fn on the standard mount path" do
        modules =
          Code.compile_quoted(
            quote do
              defmodule Threadline.OperatorSurface.RouterTest.ActorMount do
                use Phoenix.Router
                require Threadline.OperatorSurface.Router

                pipeline :browser do
                  plug(:accepts, ["html"])
                  plug(:fetch_session)
                end

                scope "/" do
                  pipe_through(:browser)

                  Threadline.OperatorSurface.Router.threadline_operator_surface("/threadline",
                    actor_fn: &__MODULE__.actor/1,
                    authorize_fn: &__MODULE__.auth/1
                  )
                end

                def actor(_conn),
                  do: %Threadline.Semantics.ActorRef{type: :user, id: "operator-1"}

                def auth(_socket), do: :ok
              end
            end
          )

        for {module, _} <- modules do
          :code.delete(module)
          :code.purge(module)
        end
      end

      test "Case 6: compiles successfully with system theme" do
        modules =
          Code.compile_quoted(
            quote do
              defmodule Threadline.OperatorSurface.RouterTest.SystemThemeMount do
                use Phoenix.Router
                require Threadline.OperatorSurface.Router

                pipeline :browser do
                  plug(:accepts, ["html"])
                end

                scope "/" do
                  pipe_through(:browser)

                  Threadline.OperatorSurface.Router.threadline_operator_surface("/threadline",
                    theme: :system
                  )
                end
              end
            end
          )

        for {module, _} <- modules do
          :code.delete(module)
          :code.purge(module)
        end
      end

      test "Case 7: raises CompileError for invalid theme literal" do
        assert_raise CompileError,
                     ~r/Threadline Operator Surface theme must be one of :dark \| :light \| :system/,
                     fn ->
                       Code.compile_quoted(
                         quote do
                           defmodule Threadline.OperatorSurface.RouterTest.InvalidThemeMount do
                             use Phoenix.Router
                             require Threadline.OperatorSurface.Router

                             pipeline :browser do
                               plug(:accepts, ["html"])
                             end

                             scope "/" do
                               pipe_through(:browser)

                               Threadline.OperatorSurface.Router.threadline_operator_surface(
                                 "/threadline",
                                 theme: :sepia
                               )
                             end
                           end
                         end
                       )
                     end
      end

      test "mounted route set and HTTP export auth boundary stay explicit" do
        modules =
          Code.compile_quoted(
            quote do
              defmodule Threadline.OperatorSurface.RouterTest.RouteContractMount do
                use Phoenix.Router
                require Threadline.OperatorSurface.Router

                pipeline :browser do
                  plug(:accepts, ["html"])
                  plug(:fetch_session)
                end

                scope "/" do
                  pipe_through(:browser)

                  Threadline.OperatorSurface.Router.threadline_operator_surface("/threadline",
                    authorize_fn: &__MODULE__.auth/1,
                    export_authorize_fn: &__MODULE__.export_auth/1,
                    coverage_authorize_fn: &__MODULE__.feature_auth/1,
                    policy_authorize_fn: &__MODULE__.feature_auth/1,
                    evidence_authorize_fn: &__MODULE__.feature_auth/1
                  )
                end

                def auth(_socket), do: :ok
                def export_auth(_conn), do: :ok
                def feature_auth(_socket), do: :ok
              end
            end
          )

        routes = Phoenix.Router.routes(Threadline.OperatorSurface.RouterTest.RouteContractMount)

        live_routes =
          routes
          |> Enum.flat_map(fn
            %{
              path: path,
              plug: Phoenix.LiveView.Plug,
              metadata: %{phoenix_live_view: {view, action, _opts, _metadata}}
            } ->
              [{path, view, action}]

            _route ->
              []
          end)
          |> Enum.sort()

        assert live_routes ==
                 Enum.sort([
                   {"/threadline", Threadline.OperatorSurface.Live.StartLive, :index},
                   {"/threadline/actors/:kind/:id", Threadline.OperatorSurface.Live.ActorLive,
                    :show},
                   {"/threadline/coverage", Threadline.OperatorSurface.Live.CoverageLive, :index},
                   {"/threadline/evidence", Threadline.OperatorSurface.Live.EvidenceLive, :index},
                   {"/threadline/exports", Threadline.OperatorSurface.Live.ExportStatusLive,
                    :index},
                   {"/threadline/policy/redaction",
                    Threadline.OperatorSurface.Live.PolicyRedactionLive, :index},
                   {"/threadline/policy/retention",
                    Threadline.OperatorSurface.Live.RetentionHistoryLive, :index},
                   {"/threadline/rows/:table/:record_id",
                    Threadline.OperatorSurface.Live.RowHistoryLive, :show},
                   {"/threadline/timeline", Threadline.OperatorSurface.Live.TimelineLive, :index},
                   {"/threadline/transactions/:id",
                    Threadline.OperatorSurface.Live.TransactionLive, :show},
                   {"/threadline/transactions/:id/history/:table/:record_id",
                    Threadline.OperatorSurface.Live.TransactionLive, :history}
                 ])

        export_routes =
          routes
          |> Enum.flat_map(fn
            %{
              path: "/threadline/exports" <> _rest = path,
              plug: Threadline.OperatorSurface.Controllers.ExportController,
              plug_opts: action,
              verb: :get
            } ->
              [{path, action}]

            _route ->
              []
          end)
          |> Enum.sort()

        assert export_routes ==
                 Enum.sort([
                   {"/threadline/exports/changes.csv", :csv},
                   {"/threadline/exports/changes.json", :json},
                   {"/threadline/exports/changes.ndjson", :ndjson},
                   {"/threadline/exports/download/:job_id", :download}
                 ])

        source = File.read!("lib/threadline/operator_surface/router.ex")
        assert source =~ "pipeline :threadline_exports"
        assert source =~ "plug(Threadline.OperatorSurface.ExportAuthPlug"
        assert_before(source, "pipeline :threadline_exports", "get(\"/changes.csv\"")

        purge_modules(modules)
      end

      test "exports option suppresses only the HTTP export controller routes" do
        modules =
          Code.compile_quoted(
            quote do
              defmodule Threadline.OperatorSurface.RouterTest.RouteContractNoExportsMount do
                use Phoenix.Router
                require Threadline.OperatorSurface.Router

                pipeline :browser do
                  plug(:accepts, ["html"])
                  plug(:fetch_session)
                end

                scope "/" do
                  pipe_through(:browser)

                  Threadline.OperatorSurface.Router.threadline_operator_surface("/threadline",
                    authorize_fn: &__MODULE__.auth/1,
                    exports: false
                  )
                end

                def auth(_socket), do: :ok
              end
            end
          )

        routes =
          Phoenix.Router.routes(Threadline.OperatorSurface.RouterTest.RouteContractNoExportsMount)

        assert Enum.any?(routes, &(&1.path == "/threadline/timeline"))
        refute Enum.any?(routes, &String.starts_with?(&1.path, "/threadline/exports/changes."))
        refute Enum.any?(routes, &(&1.path == "/threadline/exports/download/:job_id"))

        purge_modules(modules)
      end
    end

    defp purge_modules(modules) do
      for {module, _} <- modules do
        :code.delete(module)
        :code.purge(module)
      end
    end

    defp assert_before(source, first, second) do
      first_index = :binary.match(source, first)
      second_index = :binary.match(source, second)

      assert first_index != :nomatch
      assert second_index != :nomatch

      {first_offset, _} = first_index
      {second_offset, _} = second_index
      assert first_offset < second_offset
    end
  end
end
