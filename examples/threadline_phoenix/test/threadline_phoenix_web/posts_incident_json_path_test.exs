defmodule ThreadlinePhoenixWeb.PostsIncidentJsonPathTest do
  @moduledoc false

  use ThreadlinePhoenixWeb.ConnCase, async: false

  test "POST /api/posts returns audit_transaction_id; GET changes returns the bundled incident contract" do
    slug = "incident-json-#{System.unique_integer([:positive])}"

    conn =
      build_conn()
      |> sigra_conn(%{user_id: "incident-user-1", session_id: "incident-session-1"})
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
      |> sigra_conn(%{user_id: "incident-user-1", session_id: "incident-session-1"})
      |> get(~p"/api/audit_transactions/#{atid}/changes")

    assert response(conn2, 200)
    drill = Jason.decode!(conn2.resp_body)
    assert drill["audit_transaction_id"] == atid
    assert is_map(drill["transaction"])
    assert drill["transaction"]["actor_ref"] == %{"type" => "user", "id" => "incident-user-1"}
    assert is_binary(drill["transaction"]["occurred_at"])
    assert is_map(drill["action"])
    assert drill["action"]["name"] == "post_created_via_api"
    assert drill["action"]["correlation_id"] == "comp-corr"
    assert drill["action"]["request_id"] == "comp-req"
    assert is_list(drill["changes"])
    assert length(drill["changes"]) >= 1

    first = hd(drill["changes"])
    assert is_binary(first["audit_change_id"])
    assert first["table_name"] == "posts"
    assert first["table_pk"]["id"] != nil
    assert first["op"] == "insert"
    assert is_map(first["change_diff"])
    assert first["change_diff"]["schema_version"] == 1
    assert first["change_diff"]["op"] == "INSERT"
  end

  test "GET /api/audit_transactions/:id/changes rejects anonymous requests" do
    conn =
      build_conn()
      |> get(~p"/api/audit_transactions/#{Ecto.UUID.generate()}/changes")

    assert response(conn, 401)

    assert Jason.decode!(conn.resp_body) == %{
             "errors" => %{"detail" => "authentication required for incident drill-down"}
           }
  end

  test "GET /api/audit_transactions/:id/changes keeps malformed ids as 400 for authenticated callers" do
    conn =
      build_conn()
      |> sigra_conn(%{user_id: "incident-user-2", session_id: "incident-session-2"})
      |> get(~p"/api/audit_transactions/not-a-uuid/changes")

    assert response(conn, 400)

    assert Jason.decode!(conn.resp_body) == %{
             "errors" => %{"detail" => "invalid audit transaction id"}
           }
  end

  test "GET /api/audit_transactions/:id/changes returns 404 for authenticated callers when the transaction is missing" do
    conn =
      build_conn()
      |> sigra_conn(%{user_id: "incident-user-3", session_id: "incident-session-3"})
      |> get(~p"/api/audit_transactions/#{Ecto.UUID.generate()}/changes")

    assert response(conn, 404)

    assert Jason.decode!(conn.resp_body) == %{
             "errors" => %{"detail" => "audit transaction not found"}
           }
  end
end
