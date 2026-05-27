defmodule ThreadlinePhoenixWeb.CoreComponents do
  @moduledoc """
  Minimal Phoenix 1.8-style UI components for Sigra auth templates.
  """
  use Phoenix.Component
  use Gettext, backend: ThreadlinePhoenixWeb.Gettext

  attr :id, :string, default: nil
  attr :kind, :atom, values: [:info, :error], required: true
  attr :flash, :map, required: true
  attr :title, :string, default: nil
  attr :rest, :global

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      class={["flash", "flash-#{@kind}"]}
      {@rest}
    >
      <p :if={@title}><strong>{@title}</strong></p>
      <p>{msg}</p>
    </div>
    """
  end

  attr :class, :string, default: nil
  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={["mb-6", @class]}>
      <h1 class="text-2xl font-semibold">
        {render_slot(@inner_block)}
      </h1>
      <p :if={@subtitle != []} class="mt-2 text-sm text-slate-600">
        {render_slot(@subtitle)}
      </p>
      <div :if={@actions != []} class="mt-4 flex gap-2">
        {render_slot(@actions)}
      </div>
    </header>
    """
  end

  attr :name, :string, required: true
  attr :class, :string, default: nil

  def icon(assigns) do
    ~H"""
    <span class={["inline-block h-5 w-5", @class]} aria-hidden="true" />
    """
  end

  attr :for, :any, required: true
  attr :id, :string, default: nil
  attr :action, :string, required: true
  attr :method, :string, default: "post"
  attr :rest, :global, include: ~w(autocomplete class)
  slot :inner_block, required: true

  def simple_form(assigns) do
    ~H"""
    <.form for={@for} id={@id} action={@action} method={@method} {@rest}>
      {render_slot(@inner_block)}
    </.form>
    """
  end

  attr :type, :string, default: "text"
  attr :field, Phoenix.HTML.FormField, default: nil
  attr :name, :string, default: nil
  attr :id, :string, default: nil
  attr :value, :any, default: nil
  attr :label, :string, default: nil
  attr :errors, :list, default: []
  attr :rest, :global,
    include: ~w(autocomplete disabled required readonly maxlength pattern placeholder)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    assigns =
      assigns
      |> assign(:name, field.name)
      |> assign(:id, field.id)
      |> assign(:value, field.value)
      |> assign(:errors, field.errors)

    input(assigns)
  end

  def input(assigns) do
    assigns = assign_new(assigns, :id, fn -> assigns.name end)

    ~H"""
    <div class="mb-4">
      <label :if={@label} for={@id} class="mb-1 block text-sm font-medium">
        {@label}
      </label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class="w-full rounded border border-slate-300 px-3 py-2"
        {@rest}
      />
      <p :for={error <- @errors} class="mt-1 text-sm text-red-600">
        {translate_error(error)}
      </p>
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name type value)
  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button type="submit" class={["rounded bg-blue-600 px-4 py-2 text-white", @class]} {@rest}>
      {render_slot(@inner_block)}
    </button>
    """
  end

  defp translate_error({msg, opts}) do
    if count = opts[:count] do
      Gettext.dngettext(ThreadlinePhoenixWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(ThreadlinePhoenixWeb.Gettext, "errors", msg, opts)
    end
  end
end
