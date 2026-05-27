defmodule ThreadlinePhoenixWeb.Gettext do
  @moduledoc """
  A module providing Internationalization with a gettext-based API.

  By using [Gettext](https://hexdocs.pm/gettext), your module gains a set of
  macros, per locale, that can be used in your templates and modules.
  """
  use Gettext.Backend, otp_app: :threadline_phoenix
end
