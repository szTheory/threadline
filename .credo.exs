%{
  configs: [
    %{
      name: "default",
      strict: true,
      files: %{
        included: ["lib/", "test/"],
        excluded: [~r"/_build/", ~r"/deps/"]
      },
      plugins: [],
      requires: [],
      checks: %{
        enabled: [
          {Credo.Check.Readability.ModuleDoc, []},
          {Credo.Check.Design.TagTODO, [exit_status: 0]}
        ]
      }
    }
  ]
}
