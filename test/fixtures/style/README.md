# Operator stylesheet golden file

`operator_surface.css` is the exact byte output of the style-owned part of `Threadline.OperatorSurface.Style.css/1`, rendered through `Phoenix.HTML.Safe.to_iodata/1` with the default configuration. It is everything after the embedded `<style>@font-face …</style>` block that `Threadline.OperatorSurface.Fonts` contributes, from `<style>` through the closing `</style>`, with no trailing newline. `test/threadline/operator_surface/style_byte_lock_test.exs` asserts that the live render equals the font-face prefix followed by this file, and pins both this file and the full render (fonts included) by sha256. Restructuring the stylesheet source must keep every pin green. Intentional visual changes may update the fixture and both pins through the procedure below; record the user-visible reason in the commit message.

Phase 242 updates the reconnect banner with distinct lost/reconnecting copy and wrapping behavior, so long status text remains readable at narrow widths.

Phase 243 separates the policy refresh action from the posture card and keeps Evidence footer links reachable at 320px.

Phase251 constrains Coverage verdict tracks and wraps long selected-schema headings, preventing narrow-page overflow. Shared history headers preserve a readable one-line Close action while their identity content can shrink. Tokens, full values and focus behavior remain unchanged.

Phase251 independent review also aligns the actual Home lead with the approved dense Admin28px/1.2 heading tokens. This deliberately supersedes the historical Phase23932px lead exception below; the shared font tokens and all other primary-action styles are unchanged.

Phase253 carries the independently reviewed Familjen page headlines, intrinsic 812px host control layout, compact Transaction detail, neutral copy feedback, and Retention spacing/reference/Outcome allocation into the golden. This fixture migration changes no production CSS; the prior byte lock had not followed those approved visual changes.

## Updating

Only an intentional change to the rendered CSS may update this file. Phase 239 changed decorative Home card kickers from accent styling to neutral tokens, as required by the approved UI contract. That historical responsive follow-up retained the 32px Home lead on mobile, wrapped long active-filter values in a compact rectangular treatment, and kept Timeline fact cards at two columns on tablet before restoring three columns on wide desktop. The current Phase251 heading change supersedes that historical 32px exception. Phase 240 keeps row-history and investigation evidence immediate and puts clipboard status in normal flow so success and recovery messages do not cover values or controls.

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
