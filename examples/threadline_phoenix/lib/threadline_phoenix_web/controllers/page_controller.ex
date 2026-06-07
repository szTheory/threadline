defmodule ThreadlinePhoenixWeb.PageController do
  use ThreadlinePhoenixWeb, :controller

  import Ecto.Query

  alias ThreadlinePhoenix.Demo.Manifest
  alias ThreadlinePhoenix.HelpDesk.{Organization, Ticket, TicketReply}
  alias ThreadlinePhoenix.Repo

  def home(conn, _params) do
    render(conn, :home,
      demo: demo_context(),
      support_snapshot: support_snapshot(),
      quick_links: quick_links()
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

  defp quick_links do
    [
      %{
        label: "Threadline admin",
        path: "/audit",
        detail: "Start at the audit command center after signing in."
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
      },
      %{
        label: "Dev mailbox",
        path: "/dev/mailbox",
        detail: "Read local registration, confirmation, and magic-link emails."
      }
    ]
  end
end
