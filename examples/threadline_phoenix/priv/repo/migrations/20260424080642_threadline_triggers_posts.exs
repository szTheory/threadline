defmodule ThreadlineTriggersPosts do
  use Ecto.Migration

  def up do
    execute "CREATE TRIGGER threadline_audit_posts\nAFTER INSERT OR UPDATE OR DELETE ON posts\nFOR EACH ROW EXECUTE FUNCTION threadline_capture_changes()\n"
  end

  def down do
    execute "DROP TRIGGER IF EXISTS threadline_audit_posts ON posts"
  end
end
