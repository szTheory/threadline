defmodule HexEvaluator.ShapeFixtures.CodeKeyed do
  @moduledoc false
  # TWIN-01 shape fixture: a non-`id` text primary key.
  use Ecto.Schema

  @primary_key {:code, :string, autogenerate: false}

  schema "shape_code_keyed" do
    field(:label, :string)
  end
end

defmodule HexEvaluator.ShapeFixtures.Composite do
  @moduledoc false
  # TWIN-01 shape fixture: a composite primary key.
  use Ecto.Schema

  @primary_key false

  schema "shape_composite" do
    field(:tenant_id, :integer, primary_key: true)
    field(:line_no, :integer, primary_key: true)
    field(:qty, :integer)
  end
end

defmodule HexEvaluator.ShapeFixtures.Join do
  @moduledoc false
  # TWIN-01 shape fixture: no primary key at all, addressed only through the
  # `primary_key:` override declared in config/config.exs (left_id, right_id).
  use Ecto.Schema

  @primary_key false

  schema "shape_join" do
    field(:left_id, :integer)
    field(:right_id, :integer)
    field(:note, :string)
  end
end

defmodule HexEvaluator.ShapeFixtures.TwinPublic do
  @moduledoc false
  # TWIN-01 shape fixture: same table name as ShapeFixtures.TwinShapes, but in
  # the default "public" schema. Their histories must never cross.
  use Ecto.Schema

  @primary_key {:id, :id, autogenerate: false}

  schema "shape_twin" do
    field(:note, :string)
  end
end

defmodule HexEvaluator.ShapeFixtures.TwinShapes do
  @moduledoc false
  # TWIN-01 shape fixture: same table name as ShapeFixtures.TwinPublic, but
  # in the host-owned "shapes" schema (never the Threadline storage schema).
  use Ecto.Schema

  @primary_key {:id, :id, autogenerate: false}
  @schema_prefix "shapes"

  schema "shape_twin" do
    field(:note, :string)
  end
end

defmodule HexEvaluator.ShapeFixtures.LongName do
  @moduledoc false
  # TWIN-01 shape fixture: a table name at the long end of PostgreSQL's
  # 63-byte identifier limit (60-63 bytes inclusive).
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "shape_long_name_padded_to_prove_sixty_byte_identifiers_work_ok" do
    field(:label, :string)
  end
end
