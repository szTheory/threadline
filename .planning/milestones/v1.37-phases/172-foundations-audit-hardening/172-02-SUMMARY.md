---
phase: 172
plan: 02
requirements-completed: [DS-05]
---

## Summary
Fixed layout bugs by applying a consistent max-width container (`.tl-container`) to pages like the transaction view. Implemented a zero-JS persistent theme picker using a native HTML `<form>` inside the `surface_header` component. A new `ThemeController` processes the form submission, sets a `tl_theme` cookie, and redirects the user back. The session theme state is loaded in `Auth.on_mount/4` and merged into the connection, enabling seamless light/dark mode toggling across all LiveViews. Finally, updated test selectors in `row_history_live_test.exs` to uniquely identify the correct forms.

## Key Commits
- `feat(172-02): layout declutter and zero-JS theme picker`

## key-files.created
- lib/threadline/operator_surface/controllers/theme_controller.ex (created by subagent)
- .planning/phases/172-foundations-audit-hardening/172-02-SUMMARY.md
