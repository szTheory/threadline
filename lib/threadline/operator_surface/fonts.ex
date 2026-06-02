defmodule Threadline.OperatorSurface.Fonts do
  @moduledoc false

  # Brand webfonts for the operator surface, embedded at compile time as
  # Latin-subset woff2 data-URIs and emitted as scoped @font-face rules.
  #
  # Why data-URIs: the operator surface is a drop-in LiveView mounted at a
  # host-chosen path, and it already injects all of its CSS inline. Embedding
  # the fonts the same way keeps it truly zero-config — no host static-asset
  # route, no path assumptions, works under any mount path. Adopters who would
  # rather not pay the per-render weight can opt out:
  #
  #     config :threadline, operator_surface_embed_fonts: false
  #
  # ...which falls back to the Inter/system-ui and JetBrains-Mono/ui-monospace
  # token fallback chains.
  #
  # Fonts (both SIL OFL 1.1, redistributed with their licenses in priv/fonts):
  #   - Geist (sans) — weights 400/500/600
  #   - IBM Plex Mono — weights 400/500

  @faces [
    {"Geist", 400, "geist-400.woff2"},
    {"Geist", 500, "geist-500.woff2"},
    {"Geist", 600, "geist-600.woff2"},
    {"IBM Plex Mono", 400, "ibm-plex-mono-400.woff2"},
    {"IBM Plex Mono", 500, "ibm-plex-mono-500.woff2"}
  ]

  @fonts_dir Path.join([__DIR__, "..", "..", "..", "priv", "fonts"])

  for {_family, _weight, file} <- @faces do
    @external_resource Path.join(@fonts_dir, file)
  end

  @face_css (for {family, weight, file} <- @faces do
               data =
                 @fonts_dir
                 |> Path.join(file)
                 |> File.read!()
                 |> Base.encode64()

               """
               @font-face {
                 font-family: "#{family}";
                 font-style: normal;
                 font-weight: #{weight};
                 font-display: swap;
                 src: url("data:font/woff2;base64,#{data}") format("woff2");
               }
               """
             end)
            |> Enum.join("\n")

  @doc """
  Scoped `@font-face` declarations (compile-time-embedded woff2 data-URIs) as a
  CSS string. Returns `""` when font embedding is disabled via
  `config :threadline, operator_surface_embed_fonts: false`.
  """
  def face_css do
    if Application.get_env(:threadline, :operator_surface_embed_fonts, true) do
      @face_css
    else
      ""
    end
  end
end
