defmodule ThreadlinePhoenixWeb.SessionHTML do
  @moduledoc """
  Controller-mode login templates.

  Per Phase 10.1.1 D-12 / B9, the login page is a plain controller +
  HEEx template in BOTH `--live` and `--no-live` installs. LiveView's
  LiveView form submission attributes were swallowing the browser form
  submit during UAT. With no LiveView process on the page, the browser
  performs a real HTTP POST to `SessionController.create/2`.

  Two separate form assigns (`@form` and `@magic_link_form`) isolate
  validation/flash state so an error on one form does not corrupt the
  other.
  """
  use ThreadlinePhoenixWeb, :html

  def new(assigns) do
    ~H"""
    <section class="rd-auth" aria-labelledby="rd-login-title">
      <div class="rd-auth__story">
        <p class="rd-kicker">RelayDesk access</p>
        <h1 id="rd-login-title">Log in to the support ops demo</h1>
        <p>
          Use the seeded admin to unlock the Threadline surfaces, or register a
          new user to see how the host app provisions a local workspace.
        </p>
        <div class="rd-demo-creds" aria-label="Demo credentials">
          <p class="rd-demo-creds__intro">Demo credentials:</p>
          <div class="rd-demo-creds__row">
            <span class="rd-demo-creds__label">Email</span>
            <code
              class="rd-demo-creds__value"
              tabindex="0"
              role="button"
              data-demo-copy="admin@example.com"
              data-demo-copy-label="email"
              aria-label="Copy demo email"
              title="Copy demo email"
            >admin@example.com</code>
          </div>
          <div class="rd-demo-creds__row">
            <span class="rd-demo-creds__label">Password</span>
            <code
              class="rd-demo-creds__value"
              tabindex="0"
              role="button"
              data-demo-copy="password123456"
              data-demo-copy-label="password"
              aria-label="Copy demo password"
              title="Copy demo password"
            >password123456</code>
          </div>
          <p class="rd-demo-creds__status" role="status" aria-live="polite" data-demo-copy-status>
          </p>
        </div>
        <p>
          <.link navigate={~p"/"}>Return to RelayDesk home</.link>
        </p>
      </div>

      <div class="rd-auth__card">
        <.header>
          Log in
          <:subtitle>
            Don't have an account?
            <.link navigate={~p"/users/register"} class="font-semibold text-brand hover:underline">
              Sign up
            </.link>
            for an account now.
          </:subtitle>
        </.header>

        <% # Magic link section %>
        <.form :let={f} for={@magic_link_form} id="magic_link_form" action={~p"/users/log_in"} method="post">
          <input type="hidden" name="_action" value="magic_link" />
          <.input field={f[:email]} type="email" label="Email" autocomplete="username" required />

          <.button class="btn btn-primary w-full">
            Send magic link <span aria-hidden="true">&rarr;</span>
          </.button>
        </.form>

        <% # Divider %>
        <div class="rd-divider">
          <span>or sign in with password</span>
        </div>

        <% # Password section %>
        <.form :let={f} for={@form} id="login_form" action={~p"/users/log_in"} method="post">
          <.input field={f[:email]} type="email" label="Email" autocomplete="username" required />
          <.input field={f[:password]} type="password" label="Password" autocomplete="current-password" required />

          <div class="flex items-center justify-between">
            <label class="flex items-center gap-2 text-sm">
              <input type="checkbox" name={f[:remember_me].name} value="true" class="checkbox" />
              Keep me logged in
            </label>
          </div>

          <.button class="btn btn-primary w-full">
            Log in <span aria-hidden="true">&rarr;</span>
          </.button>
        </.form>
      </div>
    </section>
    """
  end
end
