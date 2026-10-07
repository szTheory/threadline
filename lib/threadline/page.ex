defmodule Threadline.Page do
  @moduledoc since: "1.0.0"
  @moduledoc """
  `Threadline.Page` represents one page of a Threadline paged read.

  Every paged Threadline read — `Threadline.timeline_page/2`, the row-history,
  actor-window and correlation-bundle pagers, and `Threadline.actor_history/2`
  — returns this struct. `entries` are newest first. `has_more` is exact: it
  is only ever `true` when another row is known to exist beyond this page.
  `cursor` is `nil` exactly when `has_more` is `false` — a fully drained walk
  has nothing left to resume from.

  Feed `cursor` back as the `:cursor` option to continue the walk. Start a
  walk with `cursor: :start`. Passing `cursor: nil` raises `ArgumentError` —
  it exists only to prevent a loop that feeds a drained page's cursor back in
  from silently restarting at the beginning forever.
  """

  @enforce_keys [:entries, :cursor, :has_more]
  defstruct [:entries, :cursor, :has_more]

  @typedoc """
  A cursor for a paged change read (`timeline_page/2`, the row-history pagers).
  `captured_at` is microsecond precision (`utc_datetime_usec`), matching
  `AuditChange.captured_at`.
  """
  @type change_cursor :: %{captured_at: DateTime.t(), id: Ecto.UUID.t()}

  @typedoc """
  A cursor for a paged actor-transaction read (`actor_history/2`).
  `occurred_at` is microsecond precision (`utc_datetime_usec`), matching
  `AuditTransaction.occurred_at`.
  """
  @type actor_cursor :: %{occurred_at: DateTime.t(), id: Ecto.UUID.t()}

  @typedoc """
  Any cursor a paged Threadline read accepts: a forward change or actor
  cursor, or `{:before, actor_cursor()}` to walk an actor history backward
  toward newer records.
  """
  @type cursor :: change_cursor() | actor_cursor() | {:before, actor_cursor()}

  @typedoc "A `Threadline.Page` whose entries are of type `entry`."
  @type t(entry) :: %__MODULE__{
          entries: [entry],
          cursor: cursor() | nil,
          has_more: boolean()
        }

  @typedoc "A `Threadline.Page` of unspecified entry type."
  @type t :: t(term())
end
