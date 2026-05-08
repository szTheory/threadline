# Plan 71-02 Summary

## What shipped

- Updated [guides/getting-started-saas.md](/Users/jon/projects/threadline/guides/getting-started-saas.md) and [guides/integrations/sigra.md](/Users/jon/projects/threadline/guides/integrations/sigra.md) to point at the same Phase 71 mount/auth story.
- Reworked the example router in [examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex](/Users/jon/projects/threadline/examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex) to use one shared assigns-shaped `my_authorize_fn/1`.
- Refreshed [examples/threadline_phoenix/README.md](/Users/jon/projects/threadline/examples/threadline_phoenix/README.md) so it stays a narrow runnable proof artifact while documenting the admin recipe, support-read-only variation, and honest fallback parity.

## Key outcomes

- Quickstart, Sigra guide, example router, and example README now reinforce one canonical `/audit` access-tier story.
- The example no longer teaches split `%Plug.Conn{}` versus `%Phoenix.LiveView.Socket{}` authorizer heads.
- Inline parity now names `mix threadline.incident`, `mix threadline.export`, `mix threadline.health.coverage`, `mix threadline.policy.show`, plus API fallbacks where no dedicated Mix task exists.

## Verification

- `rg -n "support-read-only|exports: false|mix threadline\\.(incident|export|health\\.coverage|policy\\.show)|Threadline\\.timeline_page/2|Threadline\\.actor_history/2|Threadline\\.history/3|Threadline\\.as_of/4|%\\{assigns: assigns\\}" guides/getting-started-saas.md guides/integrations/sigra.md`
- `rg -n "%\\{assigns: assigns\\}|exports: false|support-read-only|pipe_through \\[:browser, :admin_auth\\]|mix threadline\\.(incident|export|health\\.coverage|policy\\.show)" examples/threadline_phoenix/lib/threadline_phoenix_web/router.ex examples/threadline_phoenix/README.md`
