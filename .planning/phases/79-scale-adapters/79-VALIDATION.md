# Phase 79: Scale Adapters Validation

This document verifies the end-to-end satisfaction of the phase's requirements and success criteria.

## Requirement Verification

| Requirement | Verification Strategy |
|-------------|------------------------|
| **ADAPT-01** (Oban ExportQueue Adapter) | Verify that the system provides `Threadline.ExportQueue.Oban`. Configure the system to use it, ensure the `:oban` optional dependency is loaded, and run an export job. Confirm that the export payload is inserted into Oban. Also verify that when `:oban` is missing, `init/1` raises a clear error. |
| **ADAPT-02** (S3 Storage Adapter) | Verify that the system provides `Threadline.Storage.S3`. Configure the system to use it, ensure `:ex_aws_s3` and related optional dependencies are loaded. Verify that `put/2` writes files to S3, `get/1` reads them, and `download_url/2` successfully generates short-lived presigned URLs. Also verify that missing dependencies cause `init/1` to raise a clear error. |

## End-to-End Success Criteria

1. **Optional Dependencies:** Verify that `mix.exs` lists the scaling dependencies (`:oban`, `:ex_aws`, `:ex_aws_s3`, `:hackney`, `:sweet_xml`) as `optional: true`.
2. **Safeguard Initialization:** The new `init/1` callbacks on `Threadline.ExportQueue` and `Threadline.Storage` successfully protect against misconfiguration at startup, avoiding runtime crashes.
3. **TaskAdapter & Local Functional Parity:** The existing built-in adapters (`TaskAdapter` and `Local`) function correctly with the new behaviour contracts and do not raise warnings.
