# Phase 78 Validation

This document maps the requirements for Phase 78 to their corresponding automated tests.

## Requirement to Test Mapping

| Requirement ID | Description | Test File | Test Case / Focus |
|---|---|---|---|
| **EXP-01** | Implement a built-in export orchestrator using Task.Supervisor to run exports without blocking LiveView. | `test/threadline/export_queue/task_adapter_test.exs` | Verifies Task.Supervisor child process creation and job enqueuing. |
| **EXP-02** | Stream massive CSV exports safely to `Threadline.Storage.Local` without memory bloat. | `test/threadline/export/orchestrator_test.exs` & `test/threadline/storage/local_test.exs` | Verifies chunked streaming into local storage via `Repo.stream`, and storage path retrieval logic for safe streaming. |
| **EXP-03** | Add an "Export Status" UI inside the operator surface to monitor pending/running/completed exports and download completed artifacts. | `test/threadline/operator_surface/live/export_status_live_test.exs` | Verifies UI displays jobs, real-time status updates, and valid download links for completed artifacts. |
| **EXP-04** | Implement automatic expiration and cleanup of old export artifacts (e.g., older than 7 days) to prevent local or cloud storage bloat. | `test/threadline/export/cleanup_test.exs` | Verifies expired jobs are deleted from DB and their files are successfully removed from disk. |

## End-to-End Validation
- **Export Trigger:** The timeline UI successfully inserts a "pending" job and enqueues it.
- **Background Execution:** The orchestrator successfully streams rows to `Threadline.Storage.Local`.
- **Safe Download:** `Plug.Conn.send_file/3` is used via `Threadline.Storage.path/1` in the controller so that massive files do not OOM the web node.
- **Cleanup:** Background task properly cleans up files and Ecto records based on `expires_at`.
