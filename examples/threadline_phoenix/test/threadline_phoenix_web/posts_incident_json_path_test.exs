defmodule ThreadlinePhoenixWeb.PostsIncidentJsonPathTest do
  @moduledoc false

  use ThreadlinePhoenixWeb.ConnCase, async: false

  test "POST /api/posts returns audit_transaction_id; GET changes returns change_diff" do
    slug = "incident-json-#{System.unique_integer([:positive])}"

    conn =
      build_conn()
      |> put_req_header("content-type", "application/json")
      |> put_req_header("x-request-id", "comp-req")
      |> put_req_header("x-correlation-id", "comp-corr")
      |> post(~p"/api/posts", Jason.encode!(%{post: %{title: "Incident JSON", slug: slug}}))

    assert response(conn, 201)
    body = Jason.decode!(conn.resp_body)
    assert body["slug"] == slug
    assert is_binary(body["audit_transaction_id"])
    atid = body["audit_transaction_id"]

    conn2 =
      build_conn()
      |> get(~p"/api/audit_transactions/#{atid}/changes")

    assert response(conn2, 200)
    drill = Jason.decode!(conn2.resp_body)
    assert drill["audit_transaction_id"] == atid
    assert is_list(drill["changes"])
    assert length(drill["changes"]) >= 1

    first = hd(drill["changes"])
    assert is_binary(first["audit_change_id"])
    assert is_map(first["change_diff"])
    assert first["change_diff"]["schema_version"] == 1
    assert first["change_diff"]["op"] == "INSERT"
  end
end
