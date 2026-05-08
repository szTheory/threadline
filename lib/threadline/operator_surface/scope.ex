defmodule Threadline.OperatorSurface.Scope do
  @moduledoc """
  Host-owned query scoping helpers for operator-surface flows.
  """

  @spec apply(Ecto.Queryable.t(), keyword()) :: Ecto.Queryable.t()
  def apply(query, opts \\ []) do
    scope = Keyword.get(opts, :scope)
    scope_query_fn = Keyword.get(opts, :scope_query_fn)

    cond do
      is_nil(scope) or is_nil(scope_query_fn) ->
        query

      is_function(scope_query_fn, 3) ->
        context = %{
          surface: Keyword.get(opts, :surface),
          params: Keyword.get(opts, :params, %{})
        }

        scope_query_fn.(query, scope, context)

      true ->
        query
    end
  end
end
