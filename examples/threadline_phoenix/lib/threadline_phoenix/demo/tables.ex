defmodule ThreadlinePhoenix.Demo.Tables do
  @moduledoc """
  Shared `TRUNCATE` table list for `mix demo.reset` and audit tests (D-107-03b).

  Order matters for foreign keys; `CASCADE` handles dependent Sigra session tables
  when `users` is truncated.
  """

  @tables [
    "ticket_replies",
    "tickets",
    "agents",
    "org_memberships",
    "organizations",
    "threadline.threadline_export_jobs",
    "threadline.audit_changes",
    "threadline.audit_transactions",
    "threadline.audit_actions",
    "posts",
    "oban_jobs",
    "audit_events",
    "user_tokens",
    "users"
  ]

  @doc """
  Returns `TRUNCATE TABLE ... RESTART IDENTITY CASCADE` for demo fiction tables.
  """
  @spec truncate_sql() :: String.t()
  def truncate_sql do
    "TRUNCATE TABLE\n  " <> Enum.join(@tables, ",\n  ") <> "\nRESTART IDENTITY CASCADE"
  end
end
