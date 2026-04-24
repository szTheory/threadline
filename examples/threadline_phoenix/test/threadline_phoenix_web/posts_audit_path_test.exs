defmodule ThreadlinePhoenixWeb.PostsAuditPathTest do
  use ThreadlinePhoenixWeb.ConnCase, async: false

  import Ecto.Query

  alias Threadline.Capture.{AuditChange, AuditTransaction}
  alias ThreadlinePhoenix.Repo

  test "POST /api/posts captures audit change with actor on transaction" do
    slug = "http-audit-#{System.unique_integer([:positive])}"

    conn =
      build_conn()
      |> put_req_header("content-type", "application/json")
      |> put_req_header("x-request-id", "phase-23-req")
      |> put_req_header("x-correlation-id", "phase-23-corr")
      |> post(~p"/api/posts", Jason.encode!(%{post: %{title: "HTTP audit", slug: slug}}))

    assert response(conn, 201)
    assert conn.resp_body =~ slug

    rows =
      Repo.all(
        from(ac in AuditChange,
          join: at in assoc(ac, :transaction),
          where: ac.table_name == "posts",
          select: {ac, at}
        )
      )

    assert length(rows) >= 1
    assert {ac, %AuditTransaction{} = at} = hd(rows)
    assert ac.transaction_id == at.id

    assert %Threadline.Semantics.ActorRef{
             type: :service_account,
             id: "threadline-phoenix-example"
           } =
             at.actor_ref
  end
end
