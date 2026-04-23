defmodule Threadline.Semantics.ActorRefTest do
  use ExUnit.Case, async: true

  alias Threadline.Semantics.ActorRef

  describe "new/2" do
    test "valid typed actor with id" do
      assert {:ok, %ActorRef{type: :user, id: "u1"}} = ActorRef.new(:user, "u1")
    end

    test "all six actor types accept valid construction" do
      for type <- ~w(user admin service_account job system)a do
        assert {:ok, %ActorRef{type: ^type}} = ActorRef.new(type, "id-1")
      end

      assert {:ok, %ActorRef{type: :anonymous, id: nil}} = ActorRef.new(:anonymous)
    end

    test "anonymous does not require id" do
      assert {:ok, %ActorRef{type: :anonymous, id: nil}} = ActorRef.new(:anonymous, nil)
    end

    test "anonymous ignores any id provided" do
      assert {:ok, %ActorRef{type: :anonymous, id: nil}} = ActorRef.new(:anonymous, "ignored")
    end

    test "non-anonymous with nil id returns error" do
      assert {:error, :missing_actor_id} = ActorRef.new(:user, nil)
    end

    test "non-anonymous with empty string id returns error" do
      assert {:error, :missing_actor_id} = ActorRef.new(:user, "")
    end

    test "unknown actor type returns error" do
      assert {:error, :unknown_actor_type} = ActorRef.new(:robot)
    end
  end

  describe "to_map/1 and from_map/1 round-trip" do
    test "typed actor round-trips through map" do
      {:ok, ref} = ActorRef.new(:user, "u1")
      assert %{"type" => "user", "id" => "u1"} = ActorRef.to_map(ref)
      assert {:ok, ^ref} = ActorRef.from_map(ActorRef.to_map(ref))
    end

    test "anonymous round-trips without id key" do
      {:ok, ref} = ActorRef.new(:anonymous)
      map = ActorRef.to_map(ref)
      assert map == %{"type" => "anonymous"}
      refute Map.has_key?(map, "id")
      assert {:ok, ^ref} = ActorRef.from_map(map)
    end

    test "all six types round-trip" do
      for type <- ~w(user admin service_account job system)a do
        {:ok, ref} = ActorRef.new(type, "test-id")
        assert {:ok, ^ref} = ActorRef.from_map(ActorRef.to_map(ref))
      end
    end
  end

  describe "Ecto.ParameterizedType callbacks" do
    test "cast accepts an ActorRef struct" do
      {:ok, ref} = ActorRef.new(:user, "u1")
      assert {:ok, ^ref} = Ecto.Type.cast({:parameterized, {ActorRef, %{}}}, ref)
    end

    test "cast accepts a valid map" do
      {:ok, ref} = ActorRef.new(:user, "u1")

      assert {:ok, ^ref} =
               Ecto.Type.cast({:parameterized, {ActorRef, %{}}}, %{"type" => "user", "id" => "u1"})
    end

    test "cast rejects invalid input" do
      assert :error = Ecto.Type.cast({:parameterized, {ActorRef, %{}}}, "not_a_ref")
    end

    test "dump produces a plain map" do
      {:ok, ref} = ActorRef.new(:admin, "a1")

      assert {:ok, %{"type" => "admin", "id" => "a1"}} =
               Ecto.Type.dump({:parameterized, {ActorRef, %{}}}, ref)
    end

    test "dump handles nil" do
      assert {:ok, nil} = Ecto.Type.dump({:parameterized, {ActorRef, %{}}}, nil)
    end

    test "load produces an ActorRef from a map" do
      {:ok, ref} = ActorRef.new(:system, "sys-1")
      map = ActorRef.to_map(ref)
      assert {:ok, ^ref} = Ecto.Type.load({:parameterized, {ActorRef, %{}}}, map)
    end
  end
end
