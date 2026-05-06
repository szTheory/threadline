if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.Router do
    @moduledoc """
    Provides the `threadline_operator_surface/2` macro to mount the
    Threadline LiveView interface within a Phoenix router.

    This module enforces a secure-by-default mount by requiring either:
    1. A `pipe_through` directive in the enclosing router scope.
    2. An explicit `:authorize_fn` option.
    3. An explicit `:adopter_acknowledges_unauthenticated` option.
    """

    defmacro threadline_operator_surface(path, opts \\ []) do
      has_auth_fn? = Keyword.has_key?(opts, :authorize_fn)
      has_ack? = Keyword.get(opts, :adopter_acknowledges_unauthenticated, false)
      caller_file = __CALLER__.file
      caller_line = __CALLER__.line

      quote do
        _scopes = @phoenix_top_scopes || %{pipes: []}
        _has_pipe? = 
          _scopes
          |> List.wrap()
          |> Enum.any?(fn
            %{pipes: [_ | _]} -> true
            _ -> false
          end)

        if not (_has_pipe? or unquote(has_auth_fn?) or unquote(has_ack?)) do
          raise CompileError,
            file: unquote(caller_file),
            line: unquote(caller_line),
            description: "Threadline Operator Surface must be mounted inside a secure pipeline. Add `pipe_through :admin_browser` or explicitly provide an `:authorize_fn`."
        end

        import Phoenix.LiveView.Router, only: [live_session: 3, live: 3]

        live_session :threadline, on_mount: [{Threadline.OperatorSurface.Auth, unquote(opts)}] do
          scope unquote(path), alias: Threadline.OperatorSurface.Live do
            live "/transactions/:id", TransactionLive, :show
            live "/transactions/:id/history/:table/:record_id", TransactionLive, :history
            live "/actors/:kind/:id", ActorLive, :show
          end
        end
      end
    end
  end
end
