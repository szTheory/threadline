# Operator stylesheet golden file

`operator_surface.css` is the exact byte output of the style-owned part of `Threadline.OperatorSurface.Style.css/1`, rendered through `Phoenix.HTML.Safe.to_iodata/1` with the default configuration. It is everything after the embedded `<style>@font-face …</style>` block that `Threadline.OperatorSurface.Fonts` contributes, from `<style>` through the closing `</style>`, with no trailing newline. `test/threadline/operator_surface/style_byte_lock_test.exs` asserts that the live render equals the font-face prefix followed by this file, and pins both this file and the full render (fonts included) by sha256. Restructuring the stylesheet source must keep every pin green; a failure means the rendered bytes changed and the change should be reverted, not re-pinned.

## Updating

Only an intentional change to the rendered CSS may update this file.

1. Regenerate the golden file from the repository root:

   ```sh
   MIX_ENV=test mix run --no-start -e 'full = Threadline.OperatorSurface.Style.css(%{__changed__: nil}) |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary(); prefix = "<style>" <> Threadline.OperatorSurface.Fonts.face_css() <> "</style>"; true = String.starts_with?(full, prefix); File.write!("test/fixtures/style/operator_surface.css", binary_part(full, byte_size(prefix), byte_size(full) - byte_size(prefix)))'
   ```

2. Compute both hashes and paste them into `@golden_sha256` and `@rendered_sha256` in the lock test:

   ```sh
   shasum -a 256 test/fixtures/style/operator_surface.css
   MIX_ENV=test mix run --no-start -e 'Threadline.OperatorSurface.Style.css(%{__changed__: nil}) |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary() |> then(&:crypto.hash(:sha256, &1)) |> Base.encode16(case: :lower) |> IO.puts()'
   ```

3. Run `mix test test/threadline/operator_surface/style_byte_lock_test.exs`.
4. Commit the golden file and both pins together, with a message that says why the rendered CSS changed.
