# Phase 27 — Pattern map

Analog code for executors — closest existing implementations.

| Intended change | Role | Primary analog | Excerpt / note |
|-----------------|------|----------------|----------------|
| HTTP txn + `record_action` | Semantics in same txn as capture | `Blog.touch_post_for_job/2` | `Repo.transaction` → GUC → DML → `Threadline.record_action(..., [repo: Repo, actor: actor_ref] ++ Job.context_opts(args))` |
| `record_action` opts from request | Context propagation | `Threadline.Plug` + `AuditContext` | `conn.assigns[:audit_context]` has `correlation_id`, `request_id`, `actor_ref` |
| Audited HTTP integration test | ConnCase + audit asserts | `PostsAuditPathTest` | `build_conn()` → headers → `post(~p"/api/posts", ...)` → `AuditChange` / `AuditTransaction` queries |
| Timeline with correlation filter | Public API | `Threadline.timeline/2` | `validate_timeline_filters!` then `[table: "posts", correlation_id: ..., repo: Repo]` |
| Export same filters | README snippet only | `Threadline.export_json/2` | `json_format: :ndjson` in opts per `lib/threadline.ex` |

**Anti-pattern:** Calling `record_action` outside the same `Repo.transaction` as the audited insert for the HTTP create path (breaks `action_id` linkage for Phase 25 strict semantics).
