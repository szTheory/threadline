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
    end
  end
end
