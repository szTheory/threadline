defmodule ThreadlinePhoenixWeb.TrackAGoldenPathTest do
  @moduledoc """
  Track A golden path — first audited write without `mix demo.seed`.

  Register → browser session → POST /api/posts → GET incident JSON.
  """
  use ThreadlinePhoenixWeb.ConnCase, async: false

  import ThreadlinePhoenix.AccountsFixtures

  @password valid_user_password()

  test "register, login, POST /api/posts, and GET changes without demo fiction" do
    email = unique_user_email()
    slug = "track-a-#{System.unique_integer([:positive])}"

    conn =
      build_conn()
      |> Phoenix.ConnTest.init_test_session(%{})
      |> post(~p"/users/register", %{
        "user" => %{"email" => email, "password" => @password}
      })

    assert redirected_to(conn) == ~p"/"

    conn =
      conn
      |> recycle()
      |> put_req_header("content-type", "application/json")
      |> put_req_header("x-request-id", "track-a-req")
      |> put_req_header("x-correlation-id", "track-a-corr")
      |> post(~p"/api/posts", Jason.encode!(%{post: %{title: "Track A", slug: slug}}))

    assert response(conn, 201)
    body = Jason.decode!(conn.resp_body)
    assert body["slug"] == slug
    assert is_binary(body["audit_transaction_id"])
    atid = body["audit_transaction_id"]

    conn =
      build_conn()
      |> Phoenix.ConnTest.init_test_session(%{})
      |> post(~p"/users/log_in", %{"user" => %{"email" => email, "password" => @password}})
      |> recycle()
      |> get(~p"/api/audit_transactions/#{atid}/changes")

    assert response(conn, 200)
    drill = Jason.decode!(conn.resp_body)
    assert drill["audit_transaction_id"] == atid
    assert drill["action"]["name"] == "post_created_via_api"
    assert drill["action"]["correlation_id"] == "track-a-corr"
    assert length(drill["changes"]) >= 1
  end
end
