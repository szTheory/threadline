defmodule ThreadlinePhoenixWeb.PostsCorrelationPathTest do
  use ThreadlinePhoenixWeb.ConnCase, async: false

  alias ThreadlinePhoenix.Repo

  test "POST /api/posts with x-correlation-id yields timeline rows for :correlation_id" do
    corr = "loop-03-corr-#{System.unique_integer([:positive])}"
    slug = "corr-path-#{System.unique_integer([:positive])}"

    conn =
      build_conn()
      |> sigra_conn(%{user_id: "corr-user-1", session_id: "corr-session-1"})
      |> put_req_header("content-type", "application/json")
      |> put_req_header("x-request-id", "loop-03-req")
      |> put_req_header("x-correlation-id", corr)
      |> post(~p"/api/posts", Jason.encode!(%{post: %{title: "Correlation path", slug: slug}}))

    assert response(conn, 201)
    assert conn.resp_body =~ slug

    filters = [
      table: "posts",
      correlation_id: corr,
      repo: Repo
    ]

    assert :ok = Threadline.Query.validate_timeline_filters!(filters)

    rows = Threadline.timeline(filters, [])

    assert length(rows) >= 1

    assert Enum.any?(rows, fn ac ->
             ac.table_name == "posts" and ac.op == "insert" and
               match?(%{"slug" => ^slug}, ac.data_after)
           end)
  end

  test "POST /api/posts without x-correlation-id derives Sigra correlation through the router path" do
    session_id = "corr-session-#{System.unique_integer([:positive])}"
    corr = "sigra-session:#{session_id}:org:corr-org-1"
    slug = "corr-fallback-#{System.unique_integer([:positive])}"

    conn =
      build_conn()
      |> sigra_conn(%{
        user_id: "corr-user-2",
        session_id: session_id,
        active_organization_id: "corr-org-1"
      })
      |> put_req_header("content-type", "application/json")
      |> put_req_header("x-request-id", "loop-03-fallback-req")
      |> post(~p"/api/posts", Jason.encode!(%{post: %{title: "Correlation fallback", slug: slug}}))

    assert response(conn, 201)
    assert conn.resp_body =~ slug

    filters = [
      table: "posts",
      correlation_id: corr,
      repo: Repo
    ]

    assert :ok = Threadline.Query.validate_timeline_filters!(filters)

    rows = Threadline.timeline(filters, [])

    assert length(rows) >= 1

    assert Enum.any?(rows, fn ac ->
             ac.table_name == "posts" and ac.op == "insert" and
               match?(%{"slug" => ^slug}, ac.data_after)
           end)
  end
end
