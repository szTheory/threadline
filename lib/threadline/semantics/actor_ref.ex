defmodule Threadline.Semantics.ActorRef do
  @moduledoc """
  Value object representing the actor who performed an audited operation.

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

  @enforce_keys [:type]
  defstruct [:type, :id]

  @types ~w(user admin service_account job system anonymous)a

  # --- Constructor ---

  @doc """
  Constructs a validated ActorRef.

  Returns `{:ok, %ActorRef{}}` or `{:error, reason}` where reason is one of:
  - `:unknown_actor_type` — type not in the supported list
  - `:missing_actor_id` — non-anonymous actor with nil or empty id
  """
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

  # --- Map serialization (ACTR-04) ---

  @doc "Serializes an ActorRef to a plain map for JSONB storage."
  def to_map(%__MODULE__{type: :anonymous}) do
    %{"type" => "anonymous"}
  end

  def to_map(%__MODULE__{type: type, id: id}) do
    %{"type" => Atom.to_string(type), "id" => id}
  end

  @doc "Deserializes an ActorRef from a plain map. Returns {:ok, ref} or {:error, reason}."
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
    try do
      atom = String.to_existing_atom(str)
      if atom in @types, do: {:ok, atom}, else: {:error, :unknown_actor_type}
    rescue
      ArgumentError -> {:error, :unknown_actor_type}
    end
  end

  # --- Ecto.ParameterizedType callbacks ---

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
