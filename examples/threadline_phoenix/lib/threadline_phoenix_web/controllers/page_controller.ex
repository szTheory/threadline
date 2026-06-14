defmodule ThreadlinePhoenixWeb.PageController do
  use ThreadlinePhoenixWeb, :controller

  import Ecto.Query

  alias ThreadlinePhoenix.Demo.Manifest
  alias ThreadlinePhoenix.HelpDesk.{Organization, Ticket, TicketReply}
  alias ThreadlinePhoenixWeb.OperatorUser
  alias ThreadlinePhoenix.Repo

  def home(conn, _params) do
    operator_user = OperatorUser.build_operator_user(conn.assigns[:current_scope], conn)

    render(conn, :home,
      demo: demo_context(),
      operator_access?: operator_access?(operator_user),
      operator_user: operator_user,
      support_snapshot: support_snapshot(),
      quick_links: quick_links(operator_user)
    )
  end

  defp demo_context do
    %{
      brand: "RelayDesk",
      admin_email: Manifest.user_email(:admin),
      password: Manifest.demo_seed_password(),
      acme_correlation_id: Manifest.correlation_id(:acme_4521_close),
      hero_ticket_number: Manifest.ticket_number(:hero_close),
      mailbox_path: "/dev/mailbox"
    }
  end

  defp support_snapshot do
    recent_tickets =
      from(t in Ticket,
        join: o in assoc(t, :organization),
        left_join: a in assoc(t, :assignee),
        order_by: [desc: t.updated_at],
        limit: 4,
        select: %{
          number: t.number,
          status: t.status,
          organization_name: o.name,
          assignee_name: a.display_name
        }
      )
      |> Repo.all()

    %{
      organizations: Repo.aggregate(Organization, :count),
      tickets: Repo.aggregate(Ticket, :count),
      replies: Repo.aggregate(TicketReply, :count),
      recent_tickets: recent_tickets
    }
  end

  defp quick_links(%{is_admin: true}) do
    audit_links() ++ mailbox_links()
  end

  defp quick_links(%{role: :support, organization_id: org_id})
       when is_binary(org_id) and org_id != "" do
    [
      %{
        label: "Threadline admin",
        path: "/audit",
        detail: "Open the scoped support audit workspace."
      },
      %{
        label: "Acme incident timeline",
        path: "/audit/timeline?correlation_id=#{Manifest.correlation_id(:acme_4521_close)}",
        detail: "Jump to the seeded incident inside your allowed organization."
      }
    ] ++ mailbox_links()
  end

  defp quick_links(_operator_user), do: mailbox_links()

  defp operator_access?(%{is_admin: true}), do: true

  defp operator_access?(%{role: :support, organization_id: org_id})
       when is_binary(org_id) and org_id != "",
       do: true

  defp operator_access?(_operator_user), do: false

  defp audit_links do
    [
      %{
        label: "Threadline admin",
        path: "/audit",
        detail: "Start at the operator command center."
      },
      %{
        label: "Acme incident timeline",
        path: "/audit/timeline?correlation_id=#{Manifest.correlation_id(:acme_4521_close)}",
        detail: "Jump to ticket ##{Manifest.ticket_number(:hero_close)} and its captured changes."
      },
      %{
        label: "Evidence vault",
        path: "/audit/evidence",
        detail: "Inspect proof artifacts for exports, retention, redaction, and coverage."
      },
      %{
        label: "Redaction policy",
        path: "/audit/policy/redaction",
        detail: "Review how sensitive ticket reply fields are protected."
      },
      %{
        label: "Coverage",
        path: "/audit/coverage",
        detail: "Check trigger coverage for the RelayDesk support tables."
      }
    ]
  end

  defp mailbox_links do
    [
      %{
        label: "Dev mailbox",
        path: "/dev/mailbox",
        detail: "Read local registration, confirmation, and magic-link emails."
      }
    ]
  end
end
