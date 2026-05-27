defmodule ThreadlinePhoenixWeb.PageHTML do
  use ThreadlinePhoenixWeb, :html

  def home(assigns) do
    ~H"""
    <div class="mx-auto max-w-lg">
      <h1 class="text-2xl font-semibold">ThreadlinePhoenix</h1>
      <p class="mt-2 text-slate-600">Reference app walkthrough entry point.</p>

      <div :if={is_nil(@current_scope) or is_nil(@current_scope.user)} class="mt-6 flex flex-col gap-2">
        <.link navigate={~p"/users/register"}>Register</.link>
        <.link navigate={~p"/users/log_in"}>Log in</.link>
      </div>

      <div :if={@current_scope && @current_scope.user} class="mt-6">
        <p class="text-sm text-slate-600">
          Signed in as {@current_scope.user.email}
        </p>
        <.link navigate={~p"/audit"} class="mt-2 inline-block font-semibold">Open audit surface</.link>
      </div>
    </div>
    """
  end
end
