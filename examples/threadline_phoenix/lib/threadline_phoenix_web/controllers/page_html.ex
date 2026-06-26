defmodule ThreadlinePhoenixWeb.PageHTML do
  use ThreadlinePhoenixWeb, :html

  def home(assigns) do
    ~H"""
    <section class="rd-home" aria-labelledby="rd-home-title">
      <div class="rd-hero">
        <div class="rd-hero__copy">
          <p class="rd-kicker">Support operations demo app</p>
          <h1 id="rd-home-title">RelayDesk</h1>
          <p class="rd-hero__lede">
            A realistic customer-support workspace for Acme, Globex, and Offboarded Co.
            Use it to see how Threadline captures ticket replies, deletions, retention, and evidence
            without making the host app look like the Threadline admin UI.
          </p>

          <div class="rd-actions" :if={is_nil(@current_scope) or is_nil(@current_scope.user)}>
            <.link navigate={~p"/users/log_in"} class="rd-button rd-button--primary">Log in</.link>
            <.link navigate={~p"/users/register"} class="rd-button rd-button--secondary">Register</.link>
          </div>

          <div class="rd-signed-in" :if={@current_scope && @current_scope.user}>
            <span>Signed in as</span>
            <strong>{@current_scope.user.email}</strong>
            <.link
              :if={@operator_access?}
              navigate={~p"/audit"}
              class="rd-button rd-button--primary"
            >
              Open Threadline admin
            </.link>
          </div>
        </div>

        <aside class="rd-hero__panel" aria-label="Demo credentials">
          <div class="rd-panel__label">Seeded account</div>
          <div class="rd-demo-creds" aria-label="Demo credentials">
            <div class="rd-demo-creds__row">
              <span class="rd-demo-creds__label">Email</span>
              <code
                class="rd-demo-creds__value"
                tabindex="0"
                role="button"
                data-demo-copy={@demo.admin_email}
                data-demo-copy-label="email"
                aria-label="Copy demo email"
                title="Copy demo email"
              >{@demo.admin_email}</code>
            </div>
            <div class="rd-demo-creds__row">
              <span class="rd-demo-creds__label">Password</span>
              <code
                class="rd-demo-creds__value"
                tabindex="0"
                role="button"
                data-demo-copy={@demo.password}
                data-demo-copy-label="password"
                aria-label="Copy demo password"
                title="Copy demo password"
              >{@demo.password}</code>
            </div>
            <p class="rd-demo-creds__status" role="status" aria-live="polite" data-demo-copy-status>
            </p>
          </div>
          <p>
            Start here, then jump into Threadline from the links below. New registrations
            get a default RelayDesk workspace for local exploration.
          </p>
        </aside>
      </div>

      <div class="rd-grid rd-grid--stats" aria-label="RelayDesk snapshot">
        <article class="rd-stat">
          <span>Organizations</span>
          <strong>{@support_snapshot.organizations}</strong>
          <p>Tenant workspaces seeded for support walkthroughs.</p>
        </article>
        <article class="rd-stat">
          <span>Tickets</span>
          <strong>{@support_snapshot.tickets}</strong>
          <p>Support cases that generate auditable data changes.</p>
        </article>
        <article class="rd-stat">
          <span>Replies</span>
          <strong>{@support_snapshot.replies}</strong>
          <p>Customer and internal notes, including redaction examples.</p>
        </article>
      </div>

      <section class="rd-section" aria-labelledby="rd-walk-title">
        <div>
          <p class="rd-kicker">Golden path</p>
          <h2 id="rd-walk-title">What to click first</h2>
          <p>
            The seeded incident is Acme ticket <strong>{@demo.hero_ticket_number}</strong>.
            It uses correlation id <code>{@demo.acme_correlation_id}</code>, which is the fastest
            way to see Threadline connect a support workflow to the underlying database changes.
          </p>
        </div>
        <div class="rd-flow">
          <div>
            <span>1</span>
            <strong>Log in</strong>
            <p>Use the admin account above so every Threadline surface is enabled.</p>
          </div>
          <div>
            <span>2</span>
            <strong>Open the timeline</strong>
            <p>Follow the Acme incident link to land on filtered audit activity.</p>
          </div>
          <div>
            <span>3</span>
            <strong>Prove the controls</strong>
            <p>Review evidence, redaction, coverage, and retention from the admin UI.</p>
          </div>
        </div>
      </section>

      <section class="rd-section" aria-labelledby="rd-links-title">
        <div>
          <p class="rd-kicker">Quick links</p>
          <h2 id="rd-links-title">Navigate the demo</h2>
          <p :if={!@operator_access?}>
            Threadline's operator surface is mounted at <code>/audit</code>, but RelayDesk only
            exposes those links after an operator signs in.
          </p>
        </div>
        <div class="rd-links">
          <.link :for={link <- @quick_links} navigate={link.path} class="rd-link-card">
            <strong>{link.label}</strong>
            <span>{link.detail}</span>
          </.link>
        </div>
      </section>

      <section class="rd-section rd-section--split" aria-labelledby="rd-ticket-title">
        <div>
          <p class="rd-kicker">Host app data</p>
          <h2 id="rd-ticket-title">Recent RelayDesk tickets</h2>
          <p>
            These are ordinary host-app records. Threadline is visible only when you open
            the admin surface and inspect the audit trail behind them.
          </p>
        </div>
        <div class="rd-ticket-list">
          <div :for={ticket <- @support_snapshot.recent_tickets} class="rd-ticket">
            <div>
              <strong>{ticket.organization_name} #{ticket.number}</strong>
              <span>{ticket.assignee_name || "Unassigned"}</span>
            </div>
            <em>{ticket.status}</em>
          </div>
        </div>
      </section>
    </section>
    """
  end
end
