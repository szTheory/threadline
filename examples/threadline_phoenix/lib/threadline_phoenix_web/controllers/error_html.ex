defmodule ThreadlinePhoenixWeb.ErrorHTML do
  use ThreadlinePhoenixWeb, :html

  def render(:"403", assigns), do: forbidden(assigns)
  def render("403.html", assigns), do: forbidden(assigns)

  def render(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end

  defp forbidden(assigns) do
    ~H"""
    <section class="rd-error" aria-labelledby="rd-error-title">
      <div class="rd-error__card">
        <p class="rd-kicker">Operator area</p>
        <h1 id="rd-error-title">Operator access required</h1>
        <p>
          This account can use RelayDesk, but it cannot open the Threadline admin surface.
          Use an operator account or return to the demo workspace.
        </p>
        <div class="rd-actions">
          <.link navigate={~p"/"} class="rd-button rd-button--primary">Back to RelayDesk</.link>
          <.link href={~p"/users/log_out"} method="delete" class="rd-button rd-button--secondary">
            Sign out
          </.link>
        </div>
      </div>
    </section>
    """
  end
end
