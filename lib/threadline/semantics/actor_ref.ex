defmodule Threadline.Semantics.ActorRef do
  @moduledoc """
  An actor reference identifies who performed an audited operation, including when the actor is not a user.

  Implements `Ecto.ParameterizedType` for use as a JSONB field in Ecto schemas.
  Stored as `%{"type" => "user", "id" => "123"}` in PostgreSQL; loaded back
  as `%ActorRef{type: :user, id: "123"}` in Elixir.

  ## Actor types

  - `:user` — end user with a non-empty id
  - `:admin` — administrator with a non-empty id
  - `:service_account` — service account with a non-empty id
  - `:job` — background job with a non-empty id
  - `:system` — system process with a non-empty id
  - `:anonymous` — unauthenticated actor; id is nil
  """

  use Ecto.ParameterizedType

  @types ~w(user admin service_account job system anonymous)a

  @typedoc "One of the actor categories accepted by `new/2`."
  @type actor_type ::
          unquote(Enum.reduce(@types, fn actor_type, acc -> {:|, [], [actor_type, acc]} end))

  @typedoc "A stable actor reference with a supported type and an optional string identifier."
  @type t :: %__MODULE__{type: actor_type(), id: String.t() | nil}

  @typedoc "A non-empty map with string keys and string or nil values used to store an ActorRef."
  @type actor_map :: %{required(String.t()) => String.t() | nil}

  @enforce_keys [:type]
  defstruct [:type, :id]

  @doc """
  Returns a validated ActorRef for a supported actor type and identifier.

  The anonymous type discards its identifier. Other types require a non-empty string identifier.

  Returns `{:ok, actor_ref}` or `{:error, reason}` where the reason is `:unknown_actor_type` for an
  unsupported type or `:missing_actor_id` for a missing or empty identifier.
  """
  @spec new(actor_type(), String.t() | nil) ::
          {:ok, t()} | {:error, :unknown_actor_type | :missing_actor_id}
  def new(type, id \\ nil)

  def new(type, _id) when type not in @types do
    {:error, :unknown_actor_type}
  end

  def new(:anonymous, _id) do
    {:ok, %__MODULE__{type: :anonymous, id: nil}}
  end

  def new(type, id) when id in [nil, ""] do
    _ = type
    {:error, :missing_actor_id}
  end

  def new(type, id) when is_binary(id) do
    {:ok, %__MODULE__{type: type, id: id}}
  end

  @doc "Returns whether an actor has a stable identity suitable for resource ownership."
  @spec identifiable?(term()) :: boolean()
  def identifiable?(%__MODULE__{type: type, id: id})
      when type in @types and type != :anonymous and is_binary(id) and id != "",
      do: true

  def identifiable?(_actor_ref), do: false

  @doc """
  Returns the string-keyed JSON object used to store an ActorRef.

  The `"type"` key is always present. Anonymous actors have no `"id"` key; other actor types
  include an `"id"` key.
  """
  @spec to_map(t()) :: actor_map()
  def to_map(%__MODULE__{type: :anonymous}) do
    %{"type" => "anonymous"}
  end

  def to_map(%__MODULE__{type: type, id: id}) do
    %{"type" => Atom.to_string(type), "id" => id}
  end

  @doc """
  Returns an ActorRef decoded from a string-keyed JSON object.

  Accepts any input so callers can validate decoded JSON. An anonymous object has no `"id"` key;
  every other supported type requires a non-empty string identifier.

  Returns `{:ok, actor_ref}` or `{:error, reason}` for `:invalid_actor_ref_map`,
  `:unknown_actor_type`, or `:missing_actor_id`.
  """
  @spec from_map(term()) ::
          {:ok, t()} | {:error, :invalid_actor_ref_map | :unknown_actor_type | :missing_actor_id}
  def from_map(%{"type" => "anonymous"}) do
    {:ok, %__MODULE__{type: :anonymous, id: nil}}
  end

  def from_map(%{"type" => type_str, "id" => id}) when is_binary(type_str) do
    case type_from_string(type_str) do
      {:ok, type} -> new(type, id)
      error -> error
    end
  end

  def from_map(%{"type" => type_str}) when is_binary(type_str) do
    _ = type_str
    {:error, :missing_actor_id}
  end

  def from_map(_), do: {:error, :invalid_actor_ref_map}

  defp type_from_string(str) do
    atom = String.to_existing_atom(str)
    if atom in @types, do: {:ok, atom}, else: {:error, :unknown_actor_type}
  rescue
    ArgumentError -> {:error, :unknown_actor_type}
  end

  @impl Ecto.ParameterizedType
  def init(opts), do: Enum.into(opts, %{})

  @impl Ecto.ParameterizedType
  def type(_params), do: :map

  @impl Ecto.ParameterizedType
  def cast(%__MODULE__{} = ref, _params), do: {:ok, ref}

  def cast(%{"type" => _} = map, _params) do
    case from_map(map) do
      {:ok, ref} -> {:ok, ref}
      _ -> :error
    end
  end

  def cast(nil, _params), do: {:ok, nil}
  def cast(_, _params), do: :error

  @impl Ecto.ParameterizedType
  def load(nil, _loader, _params), do: {:ok, nil}

  def load(%{"type" => _} = map, _loader, _params) do
    case from_map(map) do
      {:ok, ref} -> {:ok, ref}
      _ -> :error
    end
  end

  def load(_, _loader, _params), do: :error

  @impl Ecto.ParameterizedType
  def dump(%__MODULE__{} = ref, _dumper, _params), do: {:ok, to_map(ref)}
  def dump(nil, _dumper, _params), do: {:ok, nil}
  def dump(_, _dumper, _params), do: :error
end
