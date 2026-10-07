defmodule Threadline.Query.Scope do
  @moduledoc false

  @spec apply(Ecto.Queryable.t(), keyword()) :: Ecto.Queryable.t()
  def apply(query, opts \\ []) do
    scope = Keyword.get(opts, :scope)
    scope_query_fn = Keyword.get(opts, :scope_query_fn)

    cond do
      # A :scope_query_fn of the wrong arity is always a wiring mistake,
      # regardless of :scope — raise before even looking at scope.
      not is_nil(scope_query_fn) and not is_function(scope_query_fn, 3) ->
        raise ArgumentError,
              ":scope_query_fn must be a 3-arity function (query, scope, context), got: #{inspect(scope_query_fn)}"

      # A non-nil :scope without a usable function could silently read
      # every tenant's rows if we fell through — refuse instead.
      not is_nil(scope) and is_nil(scope_query_fn) ->
        raise ArgumentError,
              "a :scope was given without a :scope_query_fn, so Threadline cannot apply it. " <>
                "Pass scope_query_fn: (a 3-arity function), or pass scope: nil for an unscoped read."

      # A nil scope is the host's explicit unscoped authorization (e.g. the
      # operator-surface authorize_fn returning :ok/true assigns scope nil
      # while the mount-level scope_query_fn stays configured) — stays
      # unscoped whether or not a function is configured, and the function
      # is never called.
      is_nil(scope) ->
        query

      true ->
        context = %{
          surface: Keyword.get(opts, :surface),
          params: Keyword.get(opts, :params, %{})
        }

        scope_query_fn.(query, scope, context)
    end
  end
end
