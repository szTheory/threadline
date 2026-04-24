defmodule ThreadlinePhoenixWeb.PostsCorrelationPathTest do
  use ThreadlinePhoenixWeb.ConnCase, async: false

  alias ThreadlinePhoenix.Repo

  test "POST /api/posts with x-correlation-id yields timeline rows for :correlation_id" do
    corr = "loop-03-corr-#{System.unique_integer([:positive])}"
    slug = "corr-path-#{System.unique_integer([:positive])}"

    conn =
      build_conn()
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
end
