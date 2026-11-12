defmodule Threadline.OperatorSurface.Fonts do
  @moduledoc false

  # Approved brand webfonts for the operator surface, embedded at compile time
  # as Latin-subset woff2 data-URIs and emitted as private @font-face rules.
  #
  # Why data-URIs: the operator surface is a drop-in LiveView mounted at a
  # host-chosen path, and it already injects all of its CSS inline. Embedding
  # the fonts the same way keeps it truly zero-config — no host static-asset
  # route, no path assumptions, works under any mount path. Adopters who would
  # rather not pay the per-render weight can opt out:
  #
  #     config :threadline, operator_surface_embed_fonts: false
  #
  # ...which uses the Inter/system-ui and JetBrains-Mono/ui-monospace fallback
  # chains in the scoped stylesheet.
  #
  # Fonts (SIL OFL 1.1, with license texts in brand/assets/fonts):
  #   - Familjen Grotesk variable — weights 400–700
  #   - Geist variable — weights 400–700
  #   - IBM Plex Mono — static weights 400/500

  @faces [
    {"Threadline Familjen Grotesk", "400 700", "FamiljenGrotesk-normal-400-700.woff2"},
    {"Threadline Geist", "400 700", "Geist-normal-400-700.woff2"},
    {"Threadline IBM Plex Mono", "400", "IBMPlexMono-normal-400.woff2"},
    {"Threadline IBM Plex Mono", "500", "IBMPlexMono-normal-500.woff2"}
  ]

  @fonts_dir Path.expand("../../../brand/assets/fonts/web", __DIR__)

  for {_family, _weight, file} <- @faces do
    @external_resource Path.join(@fonts_dir, file)
  end

  @face_css (for {family, weights, file} <- @faces do
               data =
                 @fonts_dir
                 |> Path.join(file)
                 |> File.read!()
                 |> Base.encode64()

               """
               @font-face {
                 font-family: "#{family}";
                 font-style: normal;
                 font-weight: #{weights};
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
