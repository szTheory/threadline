if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Threadline.OperatorSurface.StressRouter do
    @moduledoc false

    defmacro threadline_operator_surface_stress(path, opts \\ []) do
      stress_env = stress_env_value(Keyword.get(opts, :stress_env, Mix.env()), __CALLER__)
      clean_opts = Keyword.delete(opts, :stress_env)
      caller_file = __CALLER__.file
      caller_line = __CALLER__.line

      cond do
        stress_env == :omit ->
          quote do
            nil
          end

        stress_env == :prod ->
          raise CompileError,
            file: caller_file,
            line: caller_line,
            description: "Threadline stress surface is dev/test-only"

        true ->
          quote do
            import Phoenix.LiveView.Router, only: [live_session: 3, live: 3]

            live_session :threadline_stress,
              on_mount: [
                {Threadline.OperatorSurface.Auth, unquote(clean_opts)},
                {Threadline.OperatorSurface.Coverage.OnMount, unquote(clean_opts)}
              ] do
              scope unquote(path), alias: Threadline.OperatorSurface.Live, as: false do
                live("/", StressLive, :index)
              end
            end
          end
      end
    end

    defp stress_env_value(value, _caller) when is_atom(value), do: value

    defp stress_env_value(value, caller) do
      {env, _binding} = Code.eval_quoted(value, [], caller)
      env
    end
  end
end
