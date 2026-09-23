# Scaffolding copied from credo 1.7.18 deps/credo/.credo.exs; checks are deltas over Credo's embedded defaults — do not add enabled:
# This file contains the configuration for Credo and you are probably reading
# this after creating it with `mix credo.gen.config`.
#
# If you find anything wrong or unclear in this file, please report an
# issue on GitHub: https://github.com/rrrene/credo/issues
#
%{
  #
  # You can have as many configs as you like in the `configs:` field.
  configs: [
    %{
      #
      # Run any config using `mix credo -C <name>`. If no config name is given
      # "default" is used.
      #
      name: "default",
      #
      # These are the files included in the analysis:
      files: %{
        #
        # You can give explicit globs or simply directories.
        # In the latter case `**/*.{ex,exs}` will be used.
        #
        included: [
          "lib/",
          "src/",
          "test/",
          "web/",
          "apps/*/lib/",
          "apps/*/src/",
          "apps/*/test/",
          "apps/*/web/"
        ],
        excluded: [~r"/_build/", ~r"/deps/", ~r"/node_modules/"]
      },
      #
      # Load and configure plugins here:
      #
      plugins: [],
      #
      # If you create your own checks, you must specify the source files for
      # them here, so they can be loaded by Credo before running the analysis.
      #
      requires: [],
      #
      # If you want to enforce a style guide and need a more traditional linting
      # experience, you can change `strict` to `true` below:
      #
      # strict: bare `mix credo` equals the CI gate, and low-priority alias findings are otherwise hidden.
      strict: true,
      #
      # To modify the timeout for parsing files, change this value:
      #
      parse_timeout: 5000,
      #
      # If you want to use uncolored output by default, you can change `color`
      # to `false` below:
      #
      color: true,
      #
      # You can customize the parameters of any check by adding a second element
      # to the tuple.
      #
      # To disable a check put `false` as second element:
      #
      #     {Credo.Check.Design.DuplicatedCode, false}
      #
      checks: %{
        extra: [
          # TODO tags are advisory; FIXME tags stay blocking at their upstream default.
          {Credo.Check.Design.TagTODO, [exit_status: 0]},
          # Ignore lists cleared: a Hex library's LiveViews and controllers appear in hexdocs.
          {Credo.Check.Readability.ModuleDoc, [ignore_names: [], ignore_modules_using: []]},
          # Retention's Logger metadata keys, declared here rather than in host Logger config
          # so the result is the same in every Mix env.
          {Credo.Check.Warning.MissedMetadataKeyInLoggerConfig,
           [
             metadata_keys: [
               :deleted_changes,
               :deleted_transactions,
               :batch,
               :total_changes,
               :total_transactions
             ]
           ]}
        ],
        disabled: []
      }
    }
  ]
}
