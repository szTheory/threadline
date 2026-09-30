# Phase 224 evidence

## SUITE-05 mutation control

Date: 2026-09-30
Base commit: `cfe1ce59`

Local mutation control for the bench bare-compile wiring (D-16). The `def cli` line
was removed from `bench/mix.exs`, both bench build dirs were wiped, and
`mix verify.bench_compile` was run from a clean bench state with `MIX_ENV` unset.

Commands:

```
rm -rf bench/_build bench/deps
env -u MIX_ENV mix verify.bench_compile
```

### Red (mutated: `def cli` removed from `bench/mix.exs`)

```
==> threadline
Compiling 156 files (.ex)
    error: module ExUnitProperties is not loaded and could not be found
    │
  8 │   use ExUnitProperties
    │   ^^^^^^^^^^^^^^^^^^^^
    │
    └─ test/support/naming_generators.ex:8: Threadline.Test.NamingGenerators (module)


== Compilation error in file test/support/naming_generators.ex ==
** (CompileError) test/support/naming_generators.ex: cannot compile module Threadline.Test.NamingGenerators (errors have been logged)
    (elixir 1.17.3) expanding macro: Kernel.use/1
    test/support/naming_generators.ex:8: Threadline.Test.NamingGenerators (module)
could not compile dependency :threadline, "mix compile" failed. Errors may have been logged above. You can recompile this dependency with "mix deps.compile threadline --force", update it with "mix deps.update threadline" or clean it with "mix deps.clean threadline"
** (Mix) verify.bench_compile failed (1)
```

Restored with `git checkout -- bench/mix.exs`; confirmed `git diff --quiet -- bench/` exited 0
(no residual mutation).

### Green (restored, bench build dirs wiped again)

```
==> threadline
Compiling 156 files (.ex)
Generated threadline app
==> bench
Generated bench app
```

`mix verify.bench_compile` exited 0.
