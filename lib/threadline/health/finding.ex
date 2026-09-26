defmodule Threadline.Health.Finding do
  @moduledoc """
  One structured result from `Threadline.Health.trigger_findings/1`.

  A finding names the host table it is about, the exact PostgreSQL fix, and a
  severity so callers can decide what blocks a CI gate and what only warns.

  ## Codes

  - `:legacy_trigger_no_pk_args` (warning) — a Threadline capture trigger was
    installed before trigger arguments existed. It still works on a table
    whose live primary key is exactly `(id)`, but it carries no recorded key
    columns, so it cannot be checked for drift. The fix regenerates the
    trigger so it records its key columns explicitly.
  - `:pk_drift` (error) — the key columns a Threadline trigger recorded no
    longer match the table's expected key columns (its live primary key, or a
    qualifying `primary_key:` override). Rows captured under the old key are
    unaffected; new writes would record the wrong key.
  - `:shared_capture_function` (error) — a per-table capture function is
    referenced by triggers on more than one table. Writes to either table now
    apply the other table's capture rules (redaction, primary key).
  - `:duplicate_capture_trigger` (error) — more than one Threadline capture
    trigger fires on one table, so every write is recorded more than once.
  - `:capture_trigger_disabled` (error) — a Threadline capture trigger is
    disabled, or fires only for replica sessions, so ordinary application
    writes to the table are not being captured at all.

  ## Fields

  - `:code` — one of the codes above.
  - `:severity` — `:error` or `:warning`. Never `:info`.
  - `:schema` — the host table's schema name.
  - `:table` — the host table's own name.
  - `:message` — human-readable text naming the qualified table and the exact
    fix command.
  - `:details` — a map of JSON-encodable values whose keys are documented per
    code above and in the private TriggerFindings module.

  All six keys are enforced: constructing a `Finding` without one raises.
  """

  @enforce_keys [:code, :severity, :schema, :table, :message, :details]
  defstruct [:code, :severity, :schema, :table, :message, :details]

  @type severity :: :error | :warning

  @type code ::
          :legacy_trigger_no_pk_args
          | :pk_drift
          | :shared_capture_function
          | :duplicate_capture_trigger
          | :capture_trigger_disabled

  @type t :: %__MODULE__{
          code: code(),
          severity: severity(),
          schema: String.t(),
          table: String.t(),
          message: String.t(),
          details: map()
        }
end
