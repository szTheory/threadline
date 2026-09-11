[
  import_deps: [:ecto, :ecto_sql, :phoenix],
  subdirectories: ["priv/*/migrations"],
  inputs: [
    "*.{ex,exs}",
    "{config,lib,test}/**/*.{ex,exs}",
    "storybook/**/*.{ex,exs}",
    "priv/*/seeds.exs",
    "priv/scripts/**/*.{ex,exs}"
  ]
]
