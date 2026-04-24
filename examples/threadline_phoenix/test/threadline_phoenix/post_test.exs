defmodule ThreadlinePhoenix.PostTest do
  use ThreadlinePhoenix.DataCase, async: true

  alias ThreadlinePhoenix.{Post, Repo}

  test "posts table is queryable" do
    assert Repo.aggregate(Post, :count) >= 0
  end

  test "insert post" do
    assert {:ok, %Post{}} =
             %Post{}
             |> Post.changeset(%{title: "Test fixture", slug: "test-fixture-slug"})
             |> Repo.insert()
  end
end
