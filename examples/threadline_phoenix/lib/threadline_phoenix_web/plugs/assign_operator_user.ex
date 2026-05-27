defmodule ThreadlinePhoenixWeb.Plugs.AssignOperatorUser do
  @moduledoc false

  def init(opts), do: opts

  def call(conn, opts), do: ThreadlinePhoenixWeb.OperatorUser.assign_from_scope(conn, opts)
end
