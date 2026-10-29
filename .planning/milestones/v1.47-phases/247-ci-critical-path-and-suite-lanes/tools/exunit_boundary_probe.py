#!/usr/bin/env python3
"""Bounded, dependency-free ExUnit timestamp-boundary canary."""

from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
import platform
import re
import shutil
import signal
import subprocess
import sys
import tempfile
import time
import uuid
from pathlib import Path

PHASE_DIR = Path(__file__).resolve().parents[1]
TOOL_DIR = PHASE_DIR / "tools"
ELIXIR = TOOL_DIR / "exunit_boundary_case.exs"
FORMATTER = PHASE_DIR.parents[2] / "test" / "support" / "partition_monitor.ex"
PREFLIGHT = PHASE_DIR / "247-LOCAL-CANARY-PREFLIGHT.json"
VALIDATION_PREFLIGHT = Path(os.environ.get(
    "THREADLINE_VALIDATION_PREFLIGHT",
    str(PHASE_DIR / "247-LOCAL-CANARY-VALIDATION-PREFLIGHT.json"),
)).resolve()
OLD_RECEIPT = PHASE_DIR / "247-LOCAL-CANARY.json"
OLD_PREFLIGHT = PHASE_DIR / "247-LOCAL-CANARY-PREFLIGHT.json"
FROZEN_REPLAY = PHASE_DIR / "247-FROZEN-REPLAY.json"
DECISION = PHASE_DIR / "247-LOCAL-CANARY-VALIDATION-DECISION.md"
VALIDATION_SCHEMA = "threadline.exunit-boundary-validation/1"
RECHECK_SCHEMA = "threadline.exunit-boundary-recheck/1"
LEGACY_RECHECK_PREFLIGHT_SCHEMA = "threadline.exunit-boundary-recheck-preflight/1"
RECHECK_PREFLIGHT_SCHEMA = "threadline.exunit-boundary-recheck-preflight/2"
RECHECK_PREFLIGHT_SCHEMAS = {LEGACY_RECHECK_PREFLIGHT_SCHEMA, RECHECK_PREFLIGHT_SCHEMA}
RECHECK_PREFLIGHT = PHASE_DIR / "247-LOCAL-CANARY-RECHECK-PREFLIGHT.json"
RECHECK_RESERVATION = PHASE_DIR / "247-LOCAL-CANARY-RECHECK.reservation.json"
RECHECK_RECEIPT = PHASE_DIR / "247-LOCAL-CANARY-RECHECK.json"
RECHECK_REPORT = PHASE_DIR / "247-LOCAL-CANARY-RECHECK.md"
RECHECK_DECISION = PHASE_DIR / "247-LOCAL-CANARY-RECHECK-DECISION.md"
COMPILE_SMOKE_MARKER = "THREADLINE_COMPILE_SMOKE|ok"
RECHECK_PRODUCER_PATH = ".planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_probe.py"
RECHECK_COORDINATOR_PATH = RECHECK_PRODUCER_PATH
RECHECK_RUNNER_PATH = ".planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_case.exs"
RECHECK_FORMATTER_PATH = "test/support/partition_monitor.ex"
RECHECK_NAME_PREFIX = "threadline-24723-"
HISTORICAL_HASHES = {
    "247-LOCAL-CANARY.json": "7a946173a6e4c9ca407d94d766343596f77980eaf01eb0ad353985e85b171385",
    "247-LOCAL-CANARY-PREFLIGHT.json": "728d8c8efa6fd88c6124c0c1745bcd0a26b00c4b61ebbcd25c7135aa607bb553",
    "247-FROZEN-REPLAY.json": "5bbf55a8e9958e6f38d33da9ff21a816fb2b7542b03a33829ed5b881a7b8a6f1",
}
IMAGE_TAG = "hexpm/elixir:1.15.8-erlang-26.2.5.21-debian-bookworm-20260824"
ELIXIR_VERSION = "1.15.8"
OTP_VERSION = "26.2.5.21"
CHILD_SECONDS = 15
PREFLIGHT_SECONDS = 45
TOTAL_SECONDS = 150
CHILD_CLEANUP_SECONDS = 2
CHILD_CLEANUP_MS = CHILD_CLEANUP_SECONDS * 1000
MAX_WARMUPS = 2
PAIR_SCHEDULE = [["async", "sync"], ["sync", "async"], ["async", "sync"]]
FORMAT = "threadline.partition-timings/1"
STATUS_VALUES = {"VALID_SEMANTIC", "VALID_NO_SIGNAL", "INVALID"}
EVENT_NAMES = {
    "helper_start", "exunit_start", "registration_async", "registration_sync",
    "require_start", "require_return", "barrier_start", "barrier_release",
    "module_started", "suite_finished",
}


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="milliseconds").replace("+00:00", "Z")


def parse_utc_ms(value: str) -> int:
    parsed = datetime.strptime(value, "%Y-%m-%dT%H:%M:%S.%fZ").replace(tzinfo=timezone.utc)
    return int(parsed.timestamp() * 1000)


def bounded_output(value: str | bytes | None) -> str:
    if value is None:
        return ""
    if isinstance(value, bytes):
        value = value.decode("utf-8", errors="replace")
    text = value.replace(str(Path.cwd()), "<worktree>")
    text = re.sub(r"/Users/[^ /:\n]+(?:/[^ /:\n]+)*", "<host-path>", text)
    text = re.sub(r"/private/var/[^ /:\n]+(?:/[^ /:\n]+)*", "<host-temp>", text)
    text = re.sub(r"/var/folders/[^ /:\n]+(?:/[^ /:\n]+)*", "<host-temp>", text)
    text = re.sub(r"/probe/[^ ,\"'\n]+", "/probe/<private-file>", text)
    text = re.sub(r"sha256:[0-9a-f]{64}", "<image-id>", text)
    return text[-2048:]


def run_cmd(argv: list[str], timeout: int = 8) -> str:
    result = subprocess.run(argv, check=True, text=True, stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE, timeout=timeout)
    return result.stdout.strip()


def docker_image(timeout: float = 8) -> dict:
    raw = json.loads(run_cmd(["docker", "image", "inspect", IMAGE_TAG], timeout=timeout))[0]
    return {"tag": IMAGE_TAG, "id": raw.get("Id"),
            "repo_digests": sorted(raw.get("RepoDigests") or []),
            "os": raw.get("Os"), "architecture": raw.get("Architecture"),
            "size_bytes": raw.get("Size")}


def source_status() -> list[str]:
    raw = run_cmd(["git", "status", "--porcelain", "--untracked-files=all"])
    return [line for line in raw.splitlines()]


def make_case(async_flag: bool, setup_delay: bool = False) -> bytes:
    delay = "  Process.sleep(2_000)\n" if setup_delay else ""
    return (f"defmodule BoundaryCanary do\n  use ExUnit.Case, async: {str(async_flag).lower()}\n"
            f"  setup_all do\n{delay}    :ok\n  end\n"
            "  test \"benign fixed case\" do\n    :ok\n  end\nend\n").encode()


def parse_events(stdout: str) -> list[dict]:
    events = []
    for line in stdout.splitlines():
        if line.startswith("THREADLINE_EVENT|"):
            parts = line.split("|")
            if len(parts) != 3 or not re.fullmatch(r"-?\d+", parts[2]):
                raise ValueError("malformed event record")
            events.append({"name": parts[1], "mono_ms": int(parts[2])})
    return events


def record_parse_error(arm: dict, exc: Exception) -> None:
    arm["parse_error"] = f"{type(exc).__name__}: {exc}"


def parse_runtime(stdout: str) -> dict | None:
    found = [line.split("|", 3) for line in stdout.splitlines()
             if line.startswith("THREADLINE_RUNTIME|")]
    if len(found) != 1 or len(found[0]) != 4:
        return None
    return {"elixir": found[0][1], "otp": found[0][2], "architecture": found[0][3]}


def parse_tsv(raw: str) -> dict:
    lines = [line for line in raw.splitlines() if line]
    header = next((line for line in lines if line.startswith("# ")), "")
    if not header.startswith(f"# {FORMAT} "):
        raise ValueError("formatter TSV header is missing or malformed")
    fields = dict(part.split("=", 1) for part in header.split()[2:] if "=" in part)
    match = re.fullmatch(r"([^\t]+)\t(\d+)\t(\d+)", lines[-1] if lines else "")
    if not match:
        raise ValueError("formatter TSV data row is missing or malformed")
    return {"header": header, "boot_ms": int(fields["boot_ms"]),
            "wall_ms": int(fields["wall_ms"]), "file": match.group(1),
            "file_wall_ms": int(match.group(2)), "file_test_ms": int(match.group(3))}


def event_map(events: list[dict]) -> dict[str, int]:
    result = {}
    for event in events:
        name = event["name"]
        if name not in EVENT_NAMES:
            raise ValueError(f"unknown event {name}")
        if name.startswith("registration_"):
            result.setdefault(name, []).append(event["mono_ms"])
        elif name in result:
            raise ValueError(f"duplicate event {name}")
        else:
            result[name] = event["mono_ms"]
    return result


def classify_arm(arm: dict) -> list[str]:
    errors = []
    if not isinstance(arm.get("stdout_excerpt"), str) or not isinstance(arm.get("stderr_excerpt"), str) or \
            len(arm["stdout_excerpt"]) > 2048 or len(arm["stderr_excerpt"]) > 2048:
        errors.append("bounded_process_output_missing_or_invalid")
    if arm.get("exit_code") != 0 or arm.get("timed_out"):
        errors.append("child_timeout_or_nonzero_exit")
    if arm.get("parse_error"):
        errors.append("child_output_parse_failed")
    if arm.get("cleanup_error"):
        errors.append("child_cleanup_failed")
    runtime = arm.get("runtime") or {}
    if runtime.get("elixir") != ELIXIR_VERSION or runtime.get("otp") != OTP_VERSION or \
            "aarch64" not in runtime.get("architecture", ""):
        errors.append("runtime_identity_invalid")
    try:
        ev = event_map(arm.get("events", []))
        mode = arm["mode"]
        registration = "registration_async" if mode == "async" else "registration_sync"
        if len(ev.get(registration, [])) != 1 or len(ev.get("registration_async", [])) + len(ev.get("registration_sync", [])) != 1:
            errors.append("registration_event_missing_or_duplicated")
        required = ["helper_start", "exunit_start", "require_start", "require_return",
                    "barrier_start", "barrier_release", "module_started", "suite_finished"]
        if any(name not in ev for name in required):
            errors.append("required_event_missing")
        if not errors:
            reg = ev[registration][0]
            fixed_order = [ev[name] for name in ["helper_start", "exunit_start", "require_start",
                         "require_return", "barrier_start", "barrier_release", "suite_finished"]]
            if fixed_order != sorted(fixed_order) or not (
                    ev["require_start"] <= reg <= ev["require_return"] and
                    ev["exunit_start"] <= ev["module_started"] <= ev["suite_finished"]):
                errors.append("event_order_invalid")
            if ev["barrier_release"] - ev["barrier_start"] not in range(1750, 2251):
                errors.append("barrier_duration_outside_control_window")
        formatter = arm.get("formatter") or {}
        if formatter.get("boot_ms") is None or formatter.get("wall_ms") is None:
            errors.append("formatter_tsv_invalid")
    except (KeyError, TypeError, ValueError):
        errors.append("event_or_formatter_record_malformed")
    return errors


def check_receipt(receipt: dict, check_workspace: bool = True) -> list[str]:
    errors = []
    if receipt.get("schema") != "threadline.exunit-boundary-canary/1":
        errors.append("schema_mismatch")
    if receipt.get("runtime", {}).get("elixir") != ELIXIR_VERSION or receipt.get("runtime", {}).get("otp") != OTP_VERSION:
        errors.append("runtime_identity_mismatch")
    image = receipt.get("image", {})
    if not image.get("id", "").startswith("sha256:") or image.get("architecture") != "arm64" or not image.get("repo_digests"):
        errors.append("image_identity_invalid")
    hashes = receipt.get("hashes", {})
    producer = receipt.get("producer", {})
    producer_commit = producer.get("commit")
    producer_path = producer.get("coordinator")
    source_head = receipt.get("source", {}).get("head")
    try:
        expected_producer_path = ".planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_probe.py"
        if not producer_commit or producer_path != expected_producer_path or not source_head:
            raise ValueError("producer binding missing")
        if producer_commit != source_head:
            errors.append("producer_commit_mismatch")
        subprocess.run(["git", "cat-file", "-e", f"{producer_commit}^{{commit}}"],
                       check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        historical_coordinator = subprocess.run(["git", "show", f"{producer_commit}:{producer_path}"],
                check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE).stdout
        if producer.get("coordinator_sha256") != sha256(historical_coordinator):
            errors.append("historical_producer_hash_mismatch")
        if subprocess.run(["git", "merge-base", "--is-ancestor", producer_commit, source_head],
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode != 0:
            errors.append("producer_not_ancestor_of_recorded_source")
        historical_runner = subprocess.run(["git", "show", f"{source_head}:"+
                ".planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_case.exs"],
                check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE).stdout
        historical_formatter = subprocess.run(["git", "show", f"{source_head}:test/support/partition_monitor.ex"],
                check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE).stdout
        if hashes.get("runner_sha256") != sha256(historical_runner):
            errors.append("historical_runner_hash_mismatch")
        if hashes.get("formatter_sha256") != sha256(historical_formatter):
            errors.append("historical_formatter_hash_mismatch")
    except (OSError, ValueError, subprocess.CalledProcessError):
        errors.append("historical_producer_unverifiable")
    if set(hashes.get("canary_sha256", {}).keys()) != {"async", "sync", "setup_all"}:
        errors.append("canary_hash_set_invalid")
    expected_hashes = {"async": sha256(make_case(True)), "sync": sha256(make_case(False)),
                       "setup_all": sha256(make_case(False, True))}
    if hashes.get("canary_sha256") != expected_hashes:
        errors.append("canary_source_hash_mismatch")
    if hashes.get("canary_sha256", {}).get("async") == hashes.get("canary_sha256", {}).get("sync"):
        errors.append("ab_variants_not_distinct")
    if receipt.get("budgets", {}).get("child_seconds") != CHILD_SECONDS or receipt.get("budgets", {}).get("overall_seconds") != TOTAL_SECONDS:
        errors.append("budget_mismatch")
    preflight = receipt.get("preflight")
    if preflight:
        if preflight.get("path") != PREFLIGHT.name or not PREFLIGHT.is_file() or \
                preflight.get("sha256") != sha256(PREFLIGHT.read_bytes()):
            errors.append("preflight_receipt_hash_mismatch")
    arms = receipt.get("arms")
    if not isinstance(arms, list) or len(arms) > MAX_WARMUPS + 6 + 2:
        errors.append("arm_cap_exceeded")
        arms = arms if isinstance(arms, list) else []
    warmups = [a for a in arms if a.get("kind") == "warmup"]
    pairs = [a for a in arms if a.get("kind") == "pair"]
    controls = [a for a in arms if a.get("kind") == "control"]
    if len(warmups) > MAX_WARMUPS or [a.get("mode") for a in pairs] != [m for pair in PAIR_SCHEDULE for m in pair][:len(pairs)]:
        errors.append("schedule_invalid")
    if len(pairs) > 6 or len(controls) > 2:
        errors.append("attempt_count_invalid")
    arm_ids = [a.get("id") for a in arms]
    if len(set(arm_ids)) != len(arm_ids):
        errors.append("duplicate_arm")
    arm_errors = []
    for arm in arms:
        if not isinstance(arm.get("stdout_excerpt"), str) or not isinstance(arm.get("stderr_excerpt"), str) or \
                len(arm["stdout_excerpt"]) > 2048 or len(arm["stderr_excerpt"]) > 2048:
            arm_errors.append(f"{arm.get('id')}:bounded_process_output_missing_or_invalid")
        if arm.get("kind") in {"pair", "warmup"}:
            arm_errors.extend(f"{arm.get('id')}:{e}" for e in classify_arm(arm))
        elif arm.get("kind") == "control":
            runtime = arm.get("runtime") or {}
            if runtime.get("elixir") != ELIXIR_VERSION or runtime.get("otp") != OTP_VERSION or \
                    "aarch64" not in runtime.get("architecture", ""):
                arm_errors.append(f"{arm.get('id')}:runtime_identity_invalid")
            if arm.get("control") not in {"pre_exunit", "setup_all"}:
                arm_errors.append("unknown_control")
            if arm.get("exit_code") != 0 or arm.get("timed_out"):
                arm_errors.append(f"{arm.get('id')}:control_child_failed")
    status = receipt.get("result", {}).get("status")
    if status not in STATUS_VALUES:
        errors.append("typed_status_invalid")
    if not receipt.get("result", {}).get("reason"):
        errors.append("result_reason_missing")
    if status in {"VALID_SEMANTIC", "VALID_NO_SIGNAL"}:
        errors.extend(arm_errors)
    if status == "VALID_SEMANTIC" and (errors or len(pairs) != 6 or len(controls) != 2):
        errors.append("false_semantic_claim")
    if status == "VALID_NO_SIGNAL" and errors:
        errors.append("false_no_signal_claim")
    if status in {"VALID_SEMANTIC", "VALID_NO_SIGNAL"}:
        derived, _reason = derive_status(arms)
        if status != derived:
            errors.append("typed_status_does_not_match_raw_oracle")
    if receipt.get("historical_ci_cause") != "UNPROVEN" or receipt.get("ci_02") != "INCOMPLETE" or receipt.get("ci_03") != "MISS":
        errors.append("historical_or_ci_status_promoted")
    if receipt.get("image_after") is not None and receipt.get("image_after") != image:
        errors.append("image_identity_changed")
    if receipt.get("attempted_count") != len(arms):
        errors.append("attempt_count_mismatch")
    if check_workspace:
        base = source_head or ""
        current = run_cmd(["git", "rev-parse", "HEAD"])
        ancestor = subprocess.run(["git", "merge-base", "--is-ancestor", base, current],
                                  stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0
        if not ancestor:
            errors.append("source_head_changed")
    return errors


def base_receipt(output: Path) -> dict:
    image = docker_image()
    if image["architecture"] != "arm64" or not image["id"]:
        raise RuntimeError("cached image is not an immutable native ARM64 image")
    if not image["repo_digests"]:
        raise RuntimeError("cached image has no repository digest")
    sources = {"async": make_case(True), "sync": make_case(False),
               "setup_all": make_case(False, True)}
    normalized = sources["async"].replace(b"async: true", b"async: BOOL")
    if sources["sync"].replace(b"async: false", b"async: BOOL") != normalized:
        raise RuntimeError("A/B source differs beyond async metadata")
    head = run_cmd(["git", "rev-parse", "HEAD"])
    return {"schema": "threadline.exunit-boundary-canary/1", "plan": "247-20",
            "source": {"head": head, "status_before": source_status(), "status_after": None},
            "producer": {"commit": head,
                         "coordinator": ".planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_probe.py",
                         "coordinator_sha256": sha256(Path(__file__).read_bytes())},
            "image": image,
            "host": {"architecture": platform.machine(), "cpu_count": os.cpu_count(), "container_cpu_limit": 1},
            "runtime": {"elixir": ELIXIR_VERSION, "otp": OTP_VERSION,
                        "verification": "checked inside every child"},
            "hashes": {"runner_sha256": sha256(ELIXIR.read_bytes()),
                       "formatter_sha256": sha256(FORMATTER.read_bytes()),
                       "canary_sha256": {k: sha256(v) for k, v in sources.items()}},
            "clock_labels": {"events": "monotonic milliseconds, per child; never compared across children",
                             "formatter": "VM-relative :erlang.statistics(:wall_clock) milliseconds"},
            "budgets": {"child_seconds": CHILD_SECONDS, "overall_seconds": TOTAL_SECONDS,
                        "max_warmups": MAX_WARMUPS, "pairs": PAIR_SCHEDULE,
                        "max_controls": 2},
            "command_template": ["docker", "run", "--pull=never", "--network=none",
                                 "--read-only", "--cpus=1", "<immutable-image-id>",
                                 "elixir", "/probe/exunit_boundary_case.exs"],
            "attempted_count": 0, "arms": [],
            "result": {"status": "INVALID", "reason": "run_not_started"},
            "preflight": {"path": PREFLIGHT.name, "sha256": sha256(PREFLIGHT.read_bytes())}
                if PREFLIGHT.is_file() else None,
            "historical_ci_cause": "UNPROVEN", "ci_02": "INCOMPLETE", "ci_03": "MISS",
            "output": output.name}


def write_receipt(path: Path, receipt: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_name(path.name + ".tmp")
    temp.write_text(json.dumps(receipt, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    os.chmod(temp, 0o600)
    temp.replace(path)


def run_child(root: Path, receipt: dict, arm_id: str, kind: str, mode: str,
              control: str | None, case_bytes: bytes, deadline: float,
              runner_bytes: bytes | None = None, formatter_bytes: bytes | None = None) -> dict:
    started_ns = time.monotonic_ns()
    arm = {"id": arm_id, "kind": kind, "mode": mode, "control": control,
           "exit_code": None, "timed_out": False, "events": [], "formatter": None,
           "runtime": None, "stdout_excerpt": "", "stderr_excerpt": "",
           "raw_tsv_excerpt": "", "error_code": None, "parse_error": None,
           "argv": [], "duration_ms": None, "child_duration_ms": None, "cleanup_duration_ms": 0,
           "started_monotonic_ns": started_ns, "child_started_monotonic_ns": None,
           "child_ended_monotonic_ns": None, "ended_monotonic_ns": None}
    arm_dir = root / arm_id
    arm_dir.mkdir(mode=0o700)
    (arm_dir / "case.exs").write_bytes(case_bytes)
    (arm_dir / "runner.exs").write_bytes(runner_bytes if runner_bytes is not None else ELIXIR.read_bytes())
    (arm_dir / "formatter.ex").write_bytes(
        formatter_bytes if formatter_bytes is not None else FORMATTER.read_bytes())
    cname = f"threadline-24720-{uuid.uuid4().hex[:12]}"
    argv = ["docker", "run", "--pull=never", "--rm", "--name", cname,
            "--network=none", "--read-only", "--cpus=1", "--pids-limit=64",
            "--mount", f"type=bind,src={arm_dir},dst=/probe",
            "-e", "THREADLINE_PARTITION_TIMINGS_FILE=/probe/partition.tsv",
            "--entrypoint", "elixir", receipt["image"]["id"],
            "/probe/runner.exs", f"/probe/case.exs", mode, control or "none"]
    arm["argv"] = ["docker", "run", "--pull=never", "--rm", "--name", "<owned-container>",
                   "--network=none", "--read-only", "--cpus=1", "--mount", "<private-owned-mount>",
                   "--entrypoint", "elixir", receipt["image"]["id"],
                   "/probe/runner.exs", "/probe/case.exs", mode, control or "none"]
    env = {"THREADLINE_PARTITION_TIMINGS_FILE": "/probe/partition.tsv"}
    started = time.monotonic()
    timeout = min(CHILD_SECONDS - CHILD_CLEANUP_SECONDS,
                  max(0.1, deadline - started - CHILD_CLEANUP_SECONDS))
    proc = None
    stdout = stderr = None
    try:
        arm["child_started_monotonic_ns"] = time.monotonic_ns()
        proc = subprocess.Popen(argv, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                text=True, env={**os.environ, **env}, start_new_session=True)
        stdout, stderr = proc.communicate(timeout=timeout)
        arm["stdout_excerpt"] = bounded_output(stdout)
        arm["stderr_excerpt"] = bounded_output(stderr)
        arm["exit_code"] = proc.returncode
        arm["child_ended_monotonic_ns"] = time.monotonic_ns()
        try:
            arm["events"] = parse_events(stdout)
            arm["runtime"] = parse_runtime(stdout)
        except Exception as exc:
            record_parse_error(arm, exc)
        runtime = arm["runtime"] or {}
        if runtime.get("elixir") != ELIXIR_VERSION or runtime.get("otp") != OTP_VERSION or \
                "aarch64" not in runtime.get("architecture", ""):
            arm["error_code"] = "runtime_identity_mismatch"
        if proc.returncode != 0:
            arm["error_code"] = "child_nonzero_exit"
        tsv = arm_dir / "partition.tsv"
        if tsv.exists():
            raw_tsv = tsv.read_text(encoding="utf-8")
            arm["raw_tsv_excerpt"] = bounded_output(raw_tsv)
            try:
                arm["formatter"] = parse_tsv(raw_tsv)
            except Exception as exc:
                record_parse_error(arm, exc)
        elif proc.returncode == 0:
            arm["error_code"] = "formatter_output_missing"
    except subprocess.TimeoutExpired:
        arm["timed_out"] = True
        arm["error_code"] = "child_timeout"
        arm["child_ended_monotonic_ns"] = time.monotonic_ns()
        arm["stdout_excerpt"] = bounded_output(getattr(sys.exc_info()[1], "stdout", None))
        arm["stderr_excerpt"] = bounded_output(getattr(sys.exc_info()[1], "stderr", None))
        cleanup_started = time.monotonic()
        cleanup_deadline = cleanup_started + CHILD_CLEANUP_SECONDS
        if proc:
            try:
                os.killpg(proc.pid, signal.SIGTERM)
                proc.communicate(timeout=min(0.5, max(0.01, cleanup_deadline - time.monotonic())))
            except ProcessLookupError:
                pass
            except subprocess.TimeoutExpired:
                try:
                    os.killpg(proc.pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
                try:
                    proc.communicate(timeout=min(0.5, max(0.01, cleanup_deadline - time.monotonic())))
                except subprocess.TimeoutExpired:
                    arm["cleanup_error"] = "docker_cli_did_not_exit_after_sigkill"
            except Exception as exc:
                arm["cleanup_error"] = f"process_cleanup:{type(exc).__name__}"
        remaining_cleanup = cleanup_deadline - time.monotonic()
        if remaining_cleanup > 0:
            try:
                subprocess.run(["docker", "rm", "-f", cname], stdout=subprocess.DEVNULL,
                               stderr=subprocess.DEVNULL, timeout=min(0.5, remaining_cleanup), check=False)
            except subprocess.TimeoutExpired:
                arm["cleanup_error"] = "owned_container_remove_timeout"
            except Exception as exc:
                arm["cleanup_error"] = f"owned_container_remove:{type(exc).__name__}"
        arm["cleanup_duration_ms"] = round((time.monotonic() - cleanup_started) * 1000)
    except Exception as exc:
        arm["error_code"] = f"child_execution_error:{type(exc).__name__}"
        arm["child_ended_monotonic_ns"] = time.monotonic_ns()
        if stdout is not None:
            arm["stdout_excerpt"] = bounded_output(stdout)
        if stderr is not None:
            arm["stderr_excerpt"] = bounded_output(stderr)
        if stdout is not None or stderr is not None:
            record_parse_error(arm, exc)
        else:
            arm["execution_error"] = f"{type(exc).__name__}: {exc}"
    ended_ns = time.monotonic_ns()
    if arm["child_ended_monotonic_ns"] is None:
        arm["child_ended_monotonic_ns"] = ended_ns
    arm["ended_monotonic_ns"] = ended_ns
    arm["duration_ms"] = round((ended_ns - started_ns) / 1_000_000)
    arm["child_duration_ms"] = round((arm["child_ended_monotonic_ns"] -
                                      arm["child_started_monotonic_ns"]) / 1_000_000) \
        if arm["child_started_monotonic_ns"] is not None else 0
    arm["cleanup_duration_ms"] = max(0, arm["duration_ms"] - arm["child_duration_ms"])
    return arm


def derive_status(arms: list[dict]) -> tuple[str, str]:
    errors = []
    pairs = [a for a in arms if a["kind"] == "pair"]
    controls = [a for a in arms if a["kind"] == "control"]
    if len(pairs) != 6 or len(controls) != 2:
        errors.append("fixed_schedule_stopped_early_or_incomplete")
    for arm in arms:
        errors.extend(f"{arm['id']}:{e}" for e in classify_arm(arm))
    by_control = {a.get("control"): a for a in controls}
    if set(by_control) != {"pre_exunit", "setup_all"}:
        errors.append("control_missing")
    else:
        syncs = [a for a in pairs if a["mode"] == "sync"]
        if len(syncs) != 3:
            errors.append("sync_baseline_missing")
        elif by_control["pre_exunit"].get("formatter") and by_control["setup_all"].get("formatter"):
            base_boot = syncs[-1]["formatter"]["boot_ms"]
            pre_delta = by_control["pre_exunit"]["formatter"]["boot_ms"] - base_boot
            setup = by_control["setup_all"]["formatter"]
            setup_delta = setup["wall_ms"] - syncs[-1]["formatter"]["wall_ms"]
            boot_delta = setup["boot_ms"] - base_boot
            if not 1750 <= pre_delta <= 2250:
                errors.append("pre_exunit_control_out_of_range")
            if not 1750 <= setup_delta <= 2250 or abs(boot_delta) > 250:
                errors.append("setup_all_control_out_of_range")
        else:
            errors.append("control_formatter_output_missing")
    if errors:
        return "INVALID", ";".join(dict.fromkeys(errors))
    distinction = True
    for index in range(0, 6, 2):
        left, right = pairs[index:index + 2]
        async_arm = left if left["mode"] == "async" else right
        sync_arm = right if right["mode"] == "sync" else left
        async_events = event_map(async_arm["events"])
        sync_events = event_map(sync_arm["events"])
        if not async_events["module_started"] < async_events["barrier_release"]:
            distinction = False
        if not sync_events["module_started"] >= sync_events["barrier_release"]:
            distinction = False
    return ("VALID_SEMANTIC", "all_controls_and_three_pairs_passed") if distinction else (
        "VALID_NO_SIGNAL", "instrumentation_valid_but_paired_boundary_not_consistent")


def control_error(arms: list[dict], arm: dict) -> str | None:
    if arm.get("kind") != "control":
        return None
    syncs = [a for a in arms if a.get("kind") == "pair" and a.get("mode") == "sync"]
    if not syncs or not syncs[-1].get("formatter") or not arm.get("formatter"):
        return "control_baseline_missing"
    baseline = syncs[-1]["formatter"]
    measured = arm["formatter"]
    if arm.get("control") == "pre_exunit":
        delta = measured["boot_ms"] - baseline["boot_ms"]
        return None if 1750 <= delta <= 2250 else "pre_exunit_control_out_of_range"
    if arm.get("control") == "setup_all":
        wall_delta = measured["wall_ms"] - baseline["wall_ms"]
        boot_delta = measured["boot_ms"] - baseline["boot_ms"]
        return None if 1750 <= wall_delta <= 2250 and abs(boot_delta) <= 250 else "setup_all_control_out_of_range"
    return "unknown_control"


def median_absolute_deviation(values: list[int]) -> int:
    from statistics import median
    center = median(values)
    return median([abs(value - center) for value in values])


def pair_quality_errors(pairs: list[dict]) -> list[str]:
    if len(pairs) < 4 or len(pairs) % 2:
        return []
    deltas = {"async": [], "sync": []}
    signs = {"async": [], "sync": []}
    for pair in (pairs[index:index + 2] for index in range(0, len(pairs), 2)):
        for arm in pair:
            events = event_map(arm["events"])
            offset = events["module_started"] - events["barrier_release"]
            mode = arm["mode"]
            deltas[mode].append(offset)
            signs[mode].append(offset < 0)
    errors = []
    if any(len(set(values)) > 1 for values in signs.values()):
        errors.append("pair_boundary_signal_inconsistent")
    if any(len(values) >= 2 and median_absolute_deviation(values) > 250 for values in deltas.values()):
        errors.append("pair_offset_mad_exceeded")
    return errors


def derive_validation_status(arms: list[dict]) -> tuple[str, str]:
    errors = []
    expected_schedule = [("warmup", "async", None), ("warmup", "sync", None)]
    expected_schedule.extend(("pair", mode, None) for pair in PAIR_SCHEDULE for mode in pair)
    expected_schedule.extend([("control", "sync", "pre_exunit"),
                              ("control", "sync", "setup_all")])
    actual_schedule = [(arm.get("kind"), arm.get("mode"), arm.get("control")) for arm in arms]
    warmups = [arm for arm in arms if arm.get("kind") == "warmup"]
    pairs = [arm for arm in arms if arm.get("kind") == "pair"]
    controls = [arm for arm in arms if arm.get("kind") == "control"]
    if actual_schedule != expected_schedule[:len(actual_schedule)]:
        errors.append("fixed_schedule_changed")
    elif len(actual_schedule) != len(expected_schedule):
        errors.append("fixed_schedule_incomplete")
    for arm in arms:
        stdout = arm.get("stdout_excerpt")
        stderr = arm.get("stderr_excerpt")
        raw_tsv = arm.get("raw_tsv_excerpt")
        if not isinstance(stdout, str) or not isinstance(stderr, str) or not isinstance(raw_tsv, str) or \
                max(len(stdout), len(stderr), len(raw_tsv)) > 2048:
            errors.append(f"{arm.get('id')}:bounded_raw_output_missing_or_invalid")
        try:
            parsed_events = parse_events(stdout or "")
            if parsed_events != arm.get("events", []):
                errors.append(f"{arm.get('id')}:event_payload_differs_from_raw_stdout")
        except ValueError as exc:
            if arm.get("parse_error") != f"{type(exc).__name__}: {exc}":
                errors.append(f"{arm.get('id')}:parse_error_not_bound_to_raw_stdout")
        try:
            parsed_runtime = parse_runtime(stdout or "")
            if parsed_runtime != arm.get("runtime"):
                errors.append(f"{arm.get('id')}:runtime_payload_differs_from_raw_stdout")
        except Exception:
            errors.append(f"{arm.get('id')}:runtime_parse_failed_without_receipt")
        if raw_tsv:
            try:
                if parse_tsv(raw_tsv) != arm.get("formatter"):
                    errors.append(f"{arm.get('id')}:formatter_payload_differs_from_raw_tsv")
            except (KeyError, TypeError, ValueError) as exc:
                if arm.get("parse_error") != f"{type(exc).__name__}: {exc}":
                    errors.append(f"{arm.get('id')}:formatter_parse_error_not_bound_to_raw_tsv")
        elif arm.get("formatter") is not None:
            errors.append(f"{arm.get('id')}:formatter_payload_without_raw_tsv")
        if arm.get("kind") in {"warmup", "pair"}:
            errors.extend(f"{arm.get('id')}:{error}" for error in classify_arm(arm))
        elif arm.get("kind") == "control":
            if arm.get("exit_code") != 0 or arm.get("timed_out") or arm.get("parse_error"):
                errors.append(f"{arm.get('id')}:control_child_failed")
            if arm.get("cleanup_error"):
                errors.append(f"{arm.get('id')}:cleanup_failed")
            runtime = arm.get("runtime") or {}
            if runtime.get("elixir") != ELIXIR_VERSION or runtime.get("otp") != OTP_VERSION or \
                    "aarch64" not in runtime.get("architecture", ""):
                errors.append(f"{arm.get('id')}:control_runtime_identity_invalid")
            if not isinstance(arm.get("stdout_excerpt"), str) or not isinstance(arm.get("stderr_excerpt"), str):
                errors.append(f"{arm.get('id')}:control_output_missing")
            if not isinstance(arm.get("formatter"), dict):
                errors.append(f"{arm.get('id')}:control_formatter_missing")
    if len(pairs) >= 4 and len(pairs) % 2 == 0:
        errors.extend(pair_quality_errors(pairs))
    if len(pairs) == 6 and len(controls) == 2:
        try:
            pair_deltas = {"async": [], "sync": []}
            for pair_index in range(3):
                pair = pairs[pair_index * 2:pair_index * 2 + 2]
                for arm in pair:
                    event_times = event_map(arm["events"])
                    delta = event_times["module_started"] - event_times["barrier_release"]
                    pair_deltas[arm["mode"]].append(delta)
            syncs = [arm for arm in pairs if arm["mode"] == "sync"]
            pre = controls[0].get("formatter") or {}
            setup = controls[1].get("formatter") or {}
            baseline = syncs[-1].get("formatter") or {}
            if not all(isinstance(item.get("boot_ms"), int) and isinstance(item.get("wall_ms"), int)
                       for item in (pre, setup, baseline)):
                errors.append("control_formatter_values_invalid")
            else:
                pre_delta = pre["boot_ms"] - baseline["boot_ms"]
                setup_delta = setup["wall_ms"] - baseline["wall_ms"]
                boot_delta = setup["boot_ms"] - baseline["boot_ms"]
                if not 1750 <= pre_delta <= 2250:
                    errors.append("pre_exunit_control_out_of_range")
                if not 1750 <= setup_delta <= 2250 or abs(boot_delta) > 250:
                    errors.append("setup_all_control_out_of_range")
        except (KeyError, TypeError, ValueError, IndexError):
            errors.append("validation_events_or_controls_malformed")
    if errors:
        return "INVALID", ";".join(dict.fromkeys(errors))
    semantic = all(pair_deltas["async"][i] < 0 and pair_deltas["sync"][i] >= 0
                   for i in range(3))
    return (("VALID_SEMANTIC", "all_controls_and_three_pairs_passed") if semantic else
            ("VALID_NO_SIGNAL", "instrumentation_valid_but_no_consistent_async_boundary_distinction"))


def committed_file(commit: str, relative_path: str) -> bytes:
    return subprocess.run(["git", "show", f"{commit}:{relative_path}"], check=True,
                          stdout=subprocess.PIPE, stderr=subprocess.PIPE).stdout


def require_scope_decision() -> None:
    if not DECISION.is_file():
        raise RuntimeError("scope decision is absent; fresh observation is not authorized")
    text = DECISION.read_text(encoding="utf-8")
    if len(re.findall(r"(?m)^Decision: authorize-one-local-series$", text)) != 1:
        raise RuntimeError("scope decision does not explicitly authorize one local series")


def load_committed_sources(head: str) -> tuple[bytes, bytes, bytes, str, str]:
    paths = (".planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_probe.py",
             ".planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_case.exs",
             "test/support/partition_monitor.ex")
    coordinator, runner, formatter = (committed_file(head, path) for path in paths)
    return coordinator, runner, formatter, sha256(runner), sha256(formatter)


def valid_image_identity(image: object) -> bool:
    if not isinstance(image, dict):
        return False
    image_id = image.get("id")
    digests = image.get("repo_digests")
    return (image.get("tag") == IMAGE_TAG and isinstance(image_id, str) and
            re.fullmatch(r"sha256:[0-9a-f]{64}", image_id) is not None and
            image.get("architecture") == "arm64" and isinstance(digests, list) and bool(digests) and
            all(re.fullmatch(r"hexpm/elixir@sha256:[0-9a-f]{64}", digest or "") for digest in digests))


def validate_preflight(preflight: dict, preflight_path: Path | None = None) -> list[str]:
    errors = []
    if preflight.get("schema") != "threadline.exunit-boundary-preflight/1" or preflight.get("plan") != "247-22":
        errors.append("preflight_schema_or_plan_mismatch")
    if preflight.get("result", {}).get("status") != "VALID":
        errors.append("preflight_not_valid")
    image = preflight.get("image")
    if not valid_image_identity(image):
        errors.append("preflight_image_identity_invalid")
    if preflight.get("runtime") != {"elixir": ELIXIR_VERSION, "otp": OTP_VERSION,
                                    "architecture": "aarch64-unknown-linux-gnu"}:
        errors.append("preflight_runtime_identity_invalid")
    if preflight.get("historical_sha256") != HISTORICAL_HASHES:
        errors.append("preflight_historical_hashes_invalid")
    try:
        source = preflight.get("source") or {}
        producer = preflight.get("producer") or {}
        head = source.get("head")
        coordinator_path = ".planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_probe.py"
        if not head or producer.get("commit") != head or producer.get("path") != coordinator_path:
            errors.append("preflight_producer_binding_invalid")
        coordinator, runner, formatter, runner_hash, formatter_hash = load_committed_sources(head or "")
        if producer.get("sha256") != sha256(coordinator):
            errors.append("preflight_producer_hash_invalid")
        if preflight.get("hashes") != {"runner_sha256": runner_hash, "formatter_sha256": formatter_hash}:
            errors.append("preflight_runner_formatter_hash_invalid")
        inspection = preflight.get("image_inspection") or {}
        if inspection.get("tag") != IMAGE_TAG or inspection.get("id") != (image or {}).get("id") or \
                inspection.get("repo_digests") != (image or {}).get("repo_digests"):
            errors.append("preflight_image_inspection_binding_invalid")
    except (OSError, ValueError, subprocess.CalledProcessError, AttributeError):
        errors.append("preflight_source_binding_unverifiable")
    try:
        parse_utc_ms(preflight.get("collected_at_utc", ""))
    except (TypeError, ValueError):
        errors.append("preflight_utc_timestamp_invalid")
    if preflight_path is not None and preflight_path.resolve() != VALIDATION_PREFLIGHT.resolve():
        errors.append("preflight_path_not_canonical")
    return errors


def validate_collection_timing(receipt: dict) -> list[str]:
    errors = []
    collection = receipt.get("collection") or {}
    try:
        utc_start = parse_utc_ms(collection.get("started_at_utc", ""))
        utc_end = parse_utc_ms(collection.get("ended_at_utc", ""))
        mono_start = collection.get("started_monotonic_ns")
        mono_end = collection.get("ended_monotonic_ns")
        if not isinstance(mono_start, int) or not isinstance(mono_end, int) or mono_end < mono_start:
            raise ValueError("monotonic collection bounds are absent or reversed")
        elapsed = round((mono_end - mono_start) / 1_000_000)
        if receipt.get("elapsed_ms") != elapsed:
            errors.append("collection_elapsed_does_not_match_monotonic_bounds")
        if utc_end < utc_start or abs((utc_end - utc_start) - elapsed) > 1_000:
            errors.append("collection_utc_bounds_invalid_or_disagree_with_monotonic")
        deadline_reached = elapsed >= TOTAL_SECONDS * 1000
        if receipt.get("overall_deadline_reached") is not deadline_reached:
            errors.append("overall_deadline_flag_does_not_match_elapsed")
        if elapsed > TOTAL_SECONDS * 1000 and receipt.get("result", {}).get("status") != "INVALID":
            errors.append("overall_budget_exceeded_but_receipt_not_invalid")
    except (TypeError, ValueError, OverflowError):
        errors.append("collection_timing_missing_malformed_or_reversed")
    for arm in receipt.get("arms") or []:
        try:
            start = arm.get("started_monotonic_ns")
            child_start = arm.get("child_started_monotonic_ns")
            child_end = arm.get("child_ended_monotonic_ns")
            end = arm.get("ended_monotonic_ns")
            if not all(isinstance(value, int) for value in (start, child_start, child_end, end)) or \
                    not start <= child_start <= child_end <= end:
                raise ValueError("child monotonic bounds are absent or reversed")
            if start < collection.get("started_monotonic_ns", 0) or \
                    end > collection.get("ended_monotonic_ns", -1):
                errors.append(f"{arm.get('id')}:child_bounds_outside_collection")
            child_ms = round((child_end - child_start) / 1_000_000)
            total_ms = round((end - start) / 1_000_000)
            if arm.get("child_duration_ms") != child_ms or arm.get("duration_ms") != total_ms:
                errors.append(f"{arm.get('id')}:duration_does_not_match_monotonic_bounds")
            if child_ms > CHILD_SECONDS * 1000:
                errors.append(f"{arm.get('id')}:child_deadline_exceeded")
            cleanup_ms = arm.get("cleanup_duration_ms")
            if not isinstance(cleanup_ms, int) or cleanup_ms < 0 or cleanup_ms > CHILD_CLEANUP_MS:
                errors.append(f"{arm.get('id')}:cleanup_deadline_missing_or_exceeded")
            if total_ms > (CHILD_SECONDS + CHILD_CLEANUP_SECONDS) * 1000:
                errors.append(f"{arm.get('id')}:total_child_and_cleanup_deadline_exceeded")
            if cleanup_ms > 0 and cleanup_ms != total_ms - child_ms and abs(cleanup_ms - (total_ms - child_ms)) > 2:
                errors.append(f"{arm.get('id')}:cleanup_duration_does_not_match_bounds")
        except (TypeError, ValueError, OverflowError):
            errors.append(f"{arm.get('id')}:child_timing_missing_malformed_or_reversed")
    return errors


def validation_preflight(output: Path) -> None:
    require_scope_decision()
    if output != VALIDATION_PREFLIGHT.resolve():
        raise RuntimeError("preflight output must use the separate validation preflight path")
    if output.exists():
        raise RuntimeError("validation preflight output already exists (write-once)")
    started = utc_now()
    head = run_cmd(["git", "rev-parse", "HEAD"])
    coordinator, runner, formatter, runner_hash, formatter_hash = load_committed_sources(head)
    receipt = {"schema": "threadline.exunit-boundary-preflight/1", "plan": "247-22",
               "collected_at_utc": started, "source": {"head": head}, "image": None, "runtime": None,
               "image_inspection": None,
               "producer": None, "hashes": {}, "historical_sha256": HISTORICAL_HASHES,
               "result": {"status": "INVALID", "reason": "preflight_not_completed"}}
    try:
        producer_path = ".planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_probe.py"
        receipt["producer"] = {"commit": head, "path": producer_path, "sha256": sha256(coordinator)}
        receipt["hashes"] = {"runner_sha256": runner_hash, "formatter_sha256": formatter_hash}
        if ELIXIR.read_bytes() != runner or FORMATTER.read_bytes() != formatter:
            raise RuntimeError("runner or formatter working bytes differ from committed source")
        image = docker_image()
        if not valid_image_identity(image):
            raise RuntimeError("cached image tag, ID, architecture, or digest is invalid")
        runtime_stdout = run_cmd(["docker", "run", "--pull=never", "--rm", "--network=none",
                                  "--entrypoint", "elixir", image["id"], "--version"], timeout=10)
        runtime_match = re.search(r"Elixir ([0-9.]+) \(compiled with Erlang/OTP ([0-9]+)", runtime_stdout)
        runtime_probe = run_cmd(["docker", "run", "--pull=never", "--rm", "--network=none",
                               "--entrypoint", "elixir", image["id"], "-e",
                               'p = :code.root_dir() |> to_string() |> Path.join("releases/#{:erlang.system_info(:otp_release)}/OTP_VERSION"); IO.puts("THREADLINE_OTP|" <> (File.read!(p) |> String.trim())); IO.puts("THREADLINE_ARCH|" <> to_string(:erlang.system_info(:system_architecture)))'], timeout=10)
        otp_match = re.search(r"(?m)^THREADLINE_OTP\|([^\r\n]+)$", runtime_probe)
        arch_match = re.search(r"(?m)^THREADLINE_ARCH\|([^\r\n]+)$", runtime_probe)
        otp_version = otp_match.group(1) if otp_match else None
        runtime_arch = arch_match.group(1) if arch_match else None
        receipt["image_inspection"] = image
        receipt["image"] = image
        receipt["runtime"] = {"elixir": runtime_match.group(1) if runtime_match else None,
                              "otp": otp_version, "architecture": runtime_arch}
        if (receipt["runtime"] == {"elixir": ELIXIR_VERSION, "otp": OTP_VERSION,
                                   "architecture": "aarch64-unknown-linux-gnu"} and
                receipt["producer"].get("sha256") == sha256(Path(__file__).read_bytes())):
            receipt["result"] = {"status": "VALID", "reason": "cached_native_arm64_runtime_and_committed_sources_match"}
        else:
            receipt["result"] = {"status": "INVALID", "reason": "image_runtime_or_committed_source_mismatch"}
    except Exception as exc:
        receipt["result"] = {"status": "INVALID", "reason": f"preflight_failed:{type(exc).__name__}"}
        receipt["stderr_excerpt"] = bounded_output(str(exc))
    write_once(output, receipt)
    print(f"preflight: {receipt['result']['status']} ({receipt['result']['reason']})")


def write_once(path: Path, receipt: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    payload = (json.dumps(receipt, indent=2, sort_keys=True) + "\n").encode("utf-8")
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, "wb") as handle:
        handle.write(payload)
        handle.flush()
        os.fsync(handle.fileno())


def compile_smoke_errors(exit_code: int | None, stdout: str, stderr: str) -> list[str]:
    errors = []
    if type(exit_code) is not int or exit_code != 0:
        errors.append("compile_smoke_child_failed")
    if stdout.splitlines().count(COMPILE_SMOKE_MARKER) != 1:
        errors.append("compile_smoke_marker_missing")
    if "THREADLINE_EVENT|" in stdout:
        errors.append("compile_smoke_emitted_semantic_event")
    if stderr:
        errors.append("compile_smoke_stderr_present")
    return errors


def compile_smoke_result(exit_code: int | None, stdout: str, stderr: str) -> dict:
    errors = compile_smoke_errors(exit_code, stdout, stderr)
    return {"status": "INVALID" if errors else "COMPILE_OK",
            "reason": ";".join(errors) if errors else "marker_and_exit_passed",
            "events": []}


def validate_owned_identity(name: str, container_id: str | None,
                            inspected_name: str | None) -> tuple[bool, str | None]:
    if not isinstance(container_id, str) or not container_id:
        return False, "cid_missing"
    if not re.fullmatch(r"[0-9a-f]{64}", container_id):
        return False, "cid_malformed"
    if not isinstance(inspected_name, str):
        return False, "container_inspect_missing"
    if inspected_name.lstrip("/") != name:
        return False, "container_name_mismatch"
    return True, None


def docker_result(argv: list[str], timeout: float) -> subprocess.CompletedProcess:
    return subprocess.run(argv, check=False, text=True, stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE, timeout=timeout)


def elapsed_timing(started_ns: int, limit_ns: int) -> dict:
    ended_ns = time.monotonic_ns()
    return {"started_monotonic_ns": started_ns, "ended_monotonic_ns": ended_ns,
            "elapsed_ns": ended_ns - started_ns, "limit_ns": limit_ns}


def timing_errors(timing: dict | None, prefix: str, cap_ns: int) -> list[str]:
    keys = ("started_monotonic_ns", "ended_monotonic_ns", "elapsed_ns", "limit_ns")
    if not isinstance(timing, dict) or any(type(timing.get(key)) is not int for key in keys):
        return [f"{prefix}_timing_missing_or_malformed"]
    if timing["elapsed_ns"] < 0 or timing["elapsed_ns"] != (
            timing["ended_monotonic_ns"] - timing["started_monotonic_ns"]):
        return [f"{prefix}_timing_inconsistent"]
    if not 0 < timing["limit_ns"] <= cap_ns:
        return [f"{prefix}_timing_limit_invalid"]
    return []


def deadline_timeout(deadline_ns: int, operation_seconds: float) -> float:
    remaining = (deadline_ns - time.monotonic_ns()) / 1_000_000_000
    if remaining <= 0:
        raise TimeoutError("preflight deadline exhausted")
    return min(operation_seconds, remaining)


def run_owned_container(name: str, cidfile: Path, docker_args: list[str],
                        timeout: float, *, deadline_ns: int | None = None) -> dict:
    """Run one named Docker child and authorize cleanup only from inspected CID evidence."""
    started_ns = time.monotonic_ns()
    limit_ns = int(min(timeout, CHILD_SECONDS) * 1_000_000_000)
    deadline_ns = min(started_ns + limit_ns, deadline_ns) if deadline_ns is not None else started_ns + limit_ns
    limit_ns = max(0, deadline_ns - started_ns)
    if limit_ns == 0:
        raise TimeoutError("owned child deadline exhausted before launch")
    record = {"name": name, "id": None, "inspected_name": None,
              "inspect_exit_code": None, "launch_exit_code": None,
              "cleanup_exit_code": None, "cleanup": "not_attempted",
              "stdout_excerpt": "", "stderr_excerpt": "", "parse_error": None,
              "retained_unverified": False, "ownership_disclosure": None,
              "cidfile_absent_before_launch": not cidfile.exists()}
    if cidfile.exists():
        record.update({"cleanup": "not_attempted", "parse_error": "cidfile_preexisted",
                       "ownership_disclosure": "No Docker command issued; the pre-existing CID path was left untouched."})
        record["timing"] = elapsed_timing(started_ns, limit_ns)
        return record
    argv = ["docker", "run", "--pull=never", "--cidfile", str(cidfile), "--name", name,
            "--network=none", "--read-only", "--cpus=1", "--pids-limit=64", *docker_args]
    try:
        # Leave some of the same child budget for inspected, CID-only cleanup.
        launch_limit = min(timeout, CHILD_SECONDS) - min(CHILD_CLEANUP_SECONDS, timeout / 3)
        launched = docker_result(argv, deadline_timeout(deadline_ns, launch_limit))
        record["launch_exit_code"] = launched.returncode
        record["stdout_excerpt"] = bounded_output(launched.stdout)
        record["stderr_excerpt"] = bounded_output(launched.stderr)
        cid_text = cidfile.read_text(encoding="ascii").strip() if cidfile.is_file() else None
        if cid_text and re.fullmatch(r"[0-9a-f]{64}", cid_text):
            record["id"] = cid_text
            inspected = docker_result(["docker", "inspect", "--format", "{{.Name}}", cid_text],
                                      deadline_timeout(deadline_ns, 5))
            record["inspect_exit_code"] = inspected.returncode
            inspected_name = inspected.stdout.strip() if inspected.returncode == 0 else None
            record["inspected_name"] = inspected_name
        elif cid_text:
            record["parse_error"] = "cid_malformed"
        else:
            record["parse_error"] = "cid_missing"
        owned, reason = validate_owned_identity(name, record["id"], record["inspected_name"])
        if owned:
            removed = docker_result(["docker", "rm", "-f", record["id"]], deadline_timeout(deadline_ns, 5))
            record["cleanup_exit_code"] = removed.returncode
            record["cleanup"] = "removed" if removed.returncode == 0 else "remove_failed"
            if removed.stderr:
                record["stderr_excerpt"] = bounded_output(
                    (record["stderr_excerpt"] + "\n" + removed.stderr).strip())
        else:
            record["parse_error"] = reason
            record["retained_unverified"] = True
    except subprocess.TimeoutExpired as exc:
        record["parse_error"] = "docker_timeout"
        record["operation_error"] = bounded_output(f"{type(exc).__name__}: {exc}")
        if record["launch_exit_code"] is None:
            record["stdout_excerpt"] = bounded_output(getattr(exc, "stdout", None))
            record["stderr_excerpt"] = bounded_output(getattr(exc, "stderr", None))
        # A timeout may still have created a container. Inspect only from a captured CID.
        try:
            cid_text = cidfile.read_text(encoding="ascii").strip() if cidfile.is_file() else None
        except OSError as read_error:
            cid_text = None
            record["parse_error"] = f"docker_timeout;cidfile_read:{type(read_error).__name__}"
        if isinstance(cid_text, str) and re.fullmatch(r"[0-9a-f]{64}", cid_text):
            record["id"] = cid_text
            try:
                inspected = docker_result(["docker", "inspect", "--format", "{{.Name}}", cid_text],
                                          deadline_timeout(deadline_ns, 5))
                record["inspect_exit_code"] = inspected.returncode
                record["inspected_name"] = inspected.stdout.strip() if inspected.returncode == 0 else None
                owned, reason = validate_owned_identity(name, cid_text, record["inspected_name"])
                if owned:
                    removed = docker_result(["docker", "rm", "-f", cid_text], deadline_timeout(deadline_ns, 5))
                    record["cleanup_exit_code"] = removed.returncode
                    record["cleanup"] = "removed" if removed.returncode == 0 else "remove_failed"
                else:
                    record["parse_error"] += f";{reason}"
                    record["retained_unverified"] = True
            except (OSError, subprocess.TimeoutExpired) as inspect_error:
                record["parse_error"] += f";inspect:{type(inspect_error).__name__}"
                record["retained_unverified"] = True
        else:
            record["parse_error"] += ";cid_missing_or_malformed"
            record["retained_unverified"] = True
    except (OSError, UnicodeError, ValueError) as exc:
        record["parse_error"] = f"docker_execution:{type(exc).__name__}"
        record["operation_error"] = bounded_output(f"{type(exc).__name__}: {exc}")
        record["retained_unverified"] = True
    record["timing"] = elapsed_timing(started_ns, limit_ns)
    if record["retained_unverified"] and not record["ownership_disclosure"]:
        record["ownership_disclosure"] = (
            "No docker rm was issued because the captured ID/name could not prove ownership; "
            "a container may remain for operator follow-up.")
    return record


def recheck_report_projection(receipt: dict) -> dict:
    return {key: receipt.get(key) for key in (
        "schema", "plan", "source", "producer", "hashes", "preflight", "reservation",
        "image", "runtime", "collection", "budgets", "attempted_count", "arms", "result",
        "historical_ci_cause", "ci_02", "ci_03")}


def recheck_preflight_report_projection(receipt: dict) -> dict:
    projection = {"schema": receipt.get("schema"), "plan": receipt.get("plan"),
            "source": receipt.get("source"), "producer": receipt.get("producer"),
            "hashes": receipt.get("hashes"), "historical_sha256": receipt.get("historical_sha256"),
            "image": receipt.get("image"), "runtime": receipt.get("runtime"),
            "compile_smoke": receipt.get("compile_smoke"),
            "compile_smoke_result": receipt.get("compile_smoke_result"),
            "reservation": receipt.get("reservation"), "result": receipt.get("result"),
            "stderr_excerpt": receipt.get("stderr_excerpt"), "attempted_count": 0, "arms": []}
    if receipt.get("schema") == RECHECK_PREFLIGHT_SCHEMA:
        projection["timing"] = receipt.get("timing")
    return projection


def check_validation_receipt(receipt: dict, receipt_path: Path | None = None) -> list[str]:
    errors = []
    if receipt.get("schema") != VALIDATION_SCHEMA or receipt.get("plan") != "247-22":
        errors.append("validation_schema_or_plan_mismatch")
    if receipt.get("output") != "247-LOCAL-CANARY-VALIDATION.json":
        errors.append("validation_output_name_mismatch")
    source = receipt.get("source") or {}
    producer = receipt.get("producer") or {}
    source_head = source.get("head")
    producer_path = ".planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_probe.py"
    if producer.get("commit") != source_head or producer.get("path") != producer_path:
        errors.append("validation_producer_binding_mismatch")
    try:
        producer_bytes = committed_file(producer.get("commit", ""), producer_path)
        if producer.get("sha256") != sha256(producer_bytes):
            errors.append("validation_producer_hash_mismatch")
        if subprocess.run(["git", "merge-base", "--is-ancestor", producer["commit"],
                           run_cmd(["git", "rev-parse", "HEAD"])], stdout=subprocess.DEVNULL,
                          stderr=subprocess.DEVNULL).returncode != 0:
            errors.append("validation_producer_not_in_current_history")
        if receipt.get("hashes", {}).get("runner_sha256") != sha256(
                committed_file(source_head, ".planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_case.exs")):
            errors.append("validation_runner_hash_mismatch")
        if receipt.get("hashes", {}).get("formatter_sha256") != sha256(
                committed_file(source_head, "test/support/partition_monitor.ex")):
            errors.append("validation_formatter_hash_mismatch")
    except (KeyError, OSError, ValueError, subprocess.CalledProcessError):
        errors.append("validation_historical_source_unverifiable")
    source_hashes = receipt.get("hashes", {}).get("canary_sha256", {})
    expected_source_hashes = {"async": sha256(make_case(True)), "sync": sha256(make_case(False)),
                              "setup_all": sha256(make_case(False, True))}
    if source_hashes != expected_source_hashes:
        errors.append("validation_canary_source_hash_mismatch")
    elif make_case(True).replace(b"async: true", b"async: BOOL") != \
            make_case(False).replace(b"async: false", b"async: BOOL"):
        errors.append("validation_ab_source_differs_beyond_async_flag")
    if receipt.get("historical_sha256") != HISTORICAL_HASHES:
        errors.append("historical_receipt_hash_binding_mismatch")
    try:
        for filename, expected in HISTORICAL_HASHES.items():
            artifact = PHASE_DIR / filename
            if not artifact.is_file() or sha256(artifact.read_bytes()) != expected:
                errors.append(f"historical_artifact_changed:{filename}")
    except OSError:
        errors.append("historical_artifact_unreadable")
    image = receipt.get("image")
    preflight = receipt.get("preflight") or {}
    preflight_receipt = None
    if preflight.get("path") != VALIDATION_PREFLIGHT.name or not VALIDATION_PREFLIGHT.is_file() or \
            preflight.get("sha256") != sha256(VALIDATION_PREFLIGHT.read_bytes()):
        errors.append("validation_preflight_binding_mismatch")
    else:
        try:
            preflight_receipt = json.loads(VALIDATION_PREFLIGHT.read_text(encoding="utf-8"))
            if preflight_receipt.get("schema") != "threadline.exunit-boundary-preflight/1" or \
                    preflight_receipt.get("historical_sha256") != HISTORICAL_HASHES or \
                    preflight_receipt.get("result", {}).get("status") not in {"VALID", "INVALID"} or \
                    preflight_receipt.get("image") != image:
                errors.append("validation_preflight_contents_invalid")
            if preflight_receipt.get("result", {}).get("status") == "VALID":
                errors.extend(validate_preflight(preflight_receipt, VALIDATION_PREFLIGHT))
                if preflight_receipt.get("source") != source or \
                        preflight_receipt.get("producer") != producer or \
                        preflight_receipt.get("hashes") != {
                            "runner_sha256": receipt.get("hashes", {}).get("runner_sha256"),
                            "formatter_sha256": receipt.get("hashes", {}).get("formatter_sha256")}:
                    errors.append("validation_preflight_source_differs_from_receipt")
        except (OSError, json.JSONDecodeError):
            errors.append("validation_preflight_unreadable")
    if receipt.get("runtime") != {"elixir": ELIXIR_VERSION, "otp": OTP_VERSION}:
        errors.append("validation_runtime_mismatch")
    preflight_result = (preflight_receipt or {}).get("result", {})
    preflight_failed = preflight_result.get("status") == "INVALID"
    image = image or {}
    if not preflight_failed and not valid_image_identity(image):
        errors.append("validation_image_identity_invalid")
    run_failure = receipt.get("run_failure") or {}
    if not preflight_failed and run_failure.get("type") == "ImageIdentityMismatch":
        if receipt.get("image_before") == image:
            errors.append("image_mismatch_failure_has_no_mismatching_inspection")
    elif not preflight_failed and run_failure.get("type") == "ImageIdentityChanged":
        if receipt.get("image_after") == receipt.get("image_before"):
            errors.append("image_change_failure_has_no_mismatching_inspection")
    elif not preflight_failed and not run_failure and \
            (receipt.get("image_before") != image or receipt.get("image_after") != image):
        errors.append("validation_image_reinspection_binding_invalid")
    if receipt.get("budgets") != {"child_seconds": CHILD_SECONDS, "overall_seconds": TOTAL_SECONDS,
                                   "max_warmups": MAX_WARMUPS, "pairs": PAIR_SCHEDULE,
                                   "max_controls": 2}:
        errors.append("validation_budget_mismatch")
    arms = receipt.get("arms")
    if not isinstance(arms, list) or len(arms) > MAX_WARMUPS + 8 or any(not isinstance(arm, dict) for arm in arms):
        errors.append("validation_arm_cap_exceeded")
        arms = arms if isinstance(arms, list) else []
        arms = [arm for arm in arms if isinstance(arm, dict)]
    if receipt.get("attempted_count") != len(arms):
        errors.append("validation_attempt_count_mismatch")
    ids = [arm.get("id") for arm in arms]
    if len(ids) != len(set(ids)):
        errors.append("validation_duplicate_arm_id")
    result = receipt.get("result") or {}
    if preflight_failed:
        if arms or result.get("status") != "INVALID" or \
                result.get("reason") != f"preflight_invalid:{preflight_result.get('reason')}":
            errors.append("preflight_invalid_not_preserved_as_terminal_receipt")
    elif receipt.get("elapsed_ms", 0) > TOTAL_SECONDS * 1000 and result.get("reason") == "overall_collection_deadline_exceeded":
        if result.get("status") != "INVALID" or not receipt.get("overall_deadline_reached"):
            errors.append("overall_deadline_invalidity_not_supported_by_elapsed_time")
    elif receipt.get("run_failure"):
        failure = receipt["run_failure"]
        if not isinstance(failure, dict) or not failure.get("type") or \
                result.get("status") != "INVALID" or result.get("reason") != f"run_failure:{failure.get('type')}":
            errors.append("run_failure_not_bound_to_invalid_verdict")
        elif not isinstance(failure.get("message"), str) or not failure.get("message") or \
                len(failure["message"]) > 2048:
            errors.append("run_failure_evidence_missing_or_unbounded")
        elif failure.get("type") == "ImageIdentityMismatch" and receipt.get("image_before") == image:
            errors.append("image_mismatch_failure_has_no_raw_inspection_difference")
        elif failure.get("type") == "ImageIdentityChanged" and \
                receipt.get("image_after") == receipt.get("image_before"):
            errors.append("image_changed_failure_has_no_raw_inspection_difference")
        if isinstance(failure, dict):
            if failure.get("type") == "ImageIdentityMismatch":
                if not isinstance(receipt.get("image_before"), dict):
                    errors.append("image_mismatch_failure_missing_raw_inspection")
            elif failure.get("type") == "ImageIdentityChanged":
                if receipt.get("image_before") != image or \
                        not isinstance(receipt.get("image_after"), dict):
                    errors.append("image_changed_failure_missing_raw_inspection")
            else:
                # Keep an exception's terminal receipt and consumed reservation, but
                # do not certify arbitrary software-error text as measurement evidence.
                errors.append("run_failure_has_no_verifiable_raw_failure")
    else:
        status, reason = derive_validation_status(arms)
        stop = receipt.get("early_stop")
        if stop and status == "INVALID" and reason == "fixed_schedule_incomplete":
            # Preserve a measured early-stop cause only when the raw attempts independently
            # reproduce it. This keeps pair failures terminal while rejecting healthy truncation.
            supported = {item for arm in arms for item in classify_arm(arm)}
            supported.update(pair_quality_errors([arm for arm in arms if arm.get("kind") == "pair"]))
            supported.update(arm.get("error_code") for arm in arms if arm.get("error_code"))
            supported.update(arm.get("parse_error") for arm in arms if arm.get("parse_error"))
            if stop.get("reason") in supported:
                reason = stop["reason"]
            elif stop.get("reason") and stop.get("reason") in {
                    control_error(arms, arms[-1]) if arms and arms[-1].get("kind") == "control" else None}:
                reason = stop["reason"]
        if result.get("status") != status or result.get("reason") != reason:
            errors.append("validation_status_or_reason_not_derived_from_raw_arms")
    if result.get("status") == "INVALID" and not result.get("reason"):
        errors.append("invalid_status_without_raw_failure")
    if result.get("status") == "INVALID" and not preflight_failed and not receipt.get("run_failure"):
        derived_failures = (result.get("reason", "").split(";"))
        supported = [item for item in derived_failures if item != "fixed_schedule_incomplete"]
        if not supported and not receipt.get("overall_deadline_reached"):
            errors.append("incomplete_schedule_has_no_terminal_raw_failure")
        if "fixed_schedule_changed" in derived_failures:
            errors.append("invalid_schedule_is_not_terminal_failure_evidence")
    if receipt.get("early_stop"):
        last_arm = arms[-1].get("id") if arms else None
        stop = receipt["early_stop"]
        if stop.get("after") != last_arm or not stop.get("reason"):
            errors.append("early_stop_does_not_match_last_attempted_arm")
    errors.extend(validate_collection_timing(receipt))
    reservation = receipt.get("reservation") or {}
    reservation_path = (receipt_path.with_name(reservation.get("path", "")) if receipt_path else None)
    if not reservation.get("path") or reservation.get("path") != "247-LOCAL-CANARY-VALIDATION.reservation.json" or \
            reservation_path is None or not reservation_path.is_file() or \
            reservation.get("sha256") != sha256(reservation_path.read_bytes()):
        errors.append("validation_series_reservation_missing_or_changed")
    else:
        try:
            reserved = json.loads(reservation_path.read_text(encoding="utf-8"))
            if reserved.get("schema") != "threadline.exunit-boundary-reservation/1" or \
                    reserved.get("series_id") != receipt.get("series_id") or \
                    reserved.get("preflight_sha256") != preflight.get("sha256") or \
                    reserved.get("producer_sha256") != producer.get("sha256"):
                errors.append("validation_series_reservation_binding_invalid")
        except (OSError, json.JSONDecodeError):
            errors.append("validation_series_reservation_unreadable")
    if receipt.get("historical_ci_cause") != "UNPROVEN" or receipt.get("ci_02") != "INCOMPLETE" or receipt.get("ci_03") != "MISS":
        errors.append("validation_promotes_historical_or_ci_status")
    if receipt_path is not None and receipt_path.name != "247-LOCAL-CANARY-VALIDATION.json":
        errors.append("validation_receipt_path_not_distinct")
    return errors


def execute_validation_run(preflight_path: Path, output: Path) -> None:
    require_scope_decision()
    if preflight_path.resolve() != VALIDATION_PREFLIGHT.resolve():
        raise RuntimeError("--run requires the separate validation preflight receipt")
    if output.resolve() != (PHASE_DIR / "247-LOCAL-CANARY-VALIDATION.json").resolve():
        raise RuntimeError("validation receipt must use its separate output path")
    if output.exists():
        raise RuntimeError("validation receipt already exists (write-once)")
    if output.resolve() in {OLD_RECEIPT.resolve(), (PHASE_DIR / "247-LOCAL-CANARY.json").resolve()}:
        raise RuntimeError("refusing to overwrite the original canary receipt")
    reservation = output.with_name("247-LOCAL-CANARY-VALIDATION.reservation.json")
    if reservation.exists():
        raise RuntimeError("series reservation already exists; this authorization is consumed")
    preflight = json.loads(preflight_path.read_text(encoding="utf-8"))
    preflight_status = preflight.get("result", {}).get("status")
    if preflight.get("schema") != "threadline.exunit-boundary-preflight/1" or \
            preflight_status not in {"VALID", "INVALID"}:
        raise RuntimeError("validation preflight receipt is malformed")
    if preflight.get("historical_sha256") != HISTORICAL_HASHES:
        raise RuntimeError("validation preflight historical hashes differ from the plan")
    head = run_cmd(["git", "rev-parse", "HEAD"])
    producer_path = ".planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_probe.py"
    coordinator_bytes, runner_bytes, formatter_bytes, runner_hash, formatter_hash = load_committed_sources(head)
    if sha256(coordinator_bytes) != sha256(Path(__file__).read_bytes()):
        raise RuntimeError("producer must be committed before any observation")
    if preflight_status == "VALID":
        preflight_errors = validate_preflight(preflight, preflight_path)
        if preflight_errors:
            raise RuntimeError("preflight binding invalid: " + ";".join(preflight_errors))
        if preflight.get("source", {}).get("head") != head:
            raise RuntimeError("preflight source head differs from current committed producer")
        if preflight.get("hashes") != {"runner_sha256": runner_hash, "formatter_sha256": formatter_hash}:
            raise RuntimeError("preflight does not bind the current committed runner and formatter")
    arm_source = {"async": make_case(True), "sync": make_case(False),
                  "setup_all": make_case(False, True)}
    normalized_async = arm_source["async"].replace(b"async: true", b"async: BOOL")
    normalized_sync = arm_source["sync"].replace(b"async: false", b"async: BOOL")
    if normalized_async != normalized_sync:
        raise RuntimeError("A/B generated case bytes differ beyond async metadata")
    image = preflight.get("image")
    started_utc = utc_now()
    started_ns = time.monotonic_ns()
    receipt = {"schema": VALIDATION_SCHEMA, "plan": "247-22", "series_id": "247-22-authorized-local-series",
               "output": output.name, "source": {"head": head},
               "producer": {"commit": head, "path": producer_path,
                            "sha256": sha256(coordinator_bytes)},
               "image": image, "runtime": {"elixir": ELIXIR_VERSION, "otp": OTP_VERSION},
               "hashes": {"runner_sha256": runner_hash, "formatter_sha256": formatter_hash,
                          "canary_sha256": {key: sha256(value) for key, value in arm_source.items()}},
               "historical_sha256": HISTORICAL_HASHES,
               "preflight": {"path": preflight_path.name, "sha256": sha256(preflight_path.read_bytes())},
               "collection": {"started_at_utc": started_utc, "ended_at_utc": None,
                              "started_monotonic_ns": started_ns, "ended_monotonic_ns": None,
                              "clock": "UTC wall clock for collection bounds; signed monotonic event occurrence time remains per child"},
               "budgets": {"child_seconds": CHILD_SECONDS, "overall_seconds": TOTAL_SECONDS,
                           "max_warmups": MAX_WARMUPS, "pairs": PAIR_SCHEDULE, "max_controls": 2},
               "arms": [], "attempted_count": 0, "historical_ci_cause": "UNPROVEN",
               "ci_02": "INCOMPLETE", "ci_03": "MISS",
               "reservation": {"path": reservation.name, "sha256": None},
               "result": {"status": "INVALID", "reason": "run_in_progress"}}
    reservation_data = {"schema": "threadline.exunit-boundary-reservation/1", "plan": "247-22",
                        "series_id": receipt["series_id"], "reserved_at_utc": started_utc,
                        "preflight_sha256": receipt["preflight"]["sha256"],
                        "producer_sha256": receipt["producer"]["sha256"],
                        "status": "RESERVED; authorization consumed even if interrupted"}
    write_once(reservation, reservation_data)
    receipt["reservation"]["sha256"] = sha256(reservation.read_bytes())
    try:
        if preflight_status == "INVALID":
            receipt["result"] = {"status": "INVALID",
                                  "reason": f"preflight_invalid:{preflight['result'].get('reason')}"}
            receipt["cleanup"] = {"observation_started": False, "reason": "preflight invalid; no child launched"}
            return
        started = time.monotonic()
        deadline = started + TOTAL_SECONDS
        before_image = docker_image(timeout=max(0.1, min(8, deadline - time.monotonic())))
        receipt["image_before"] = before_image
        if before_image != image or not valid_image_identity(before_image):
            receipt["run_failure"] = {"type": "ImageIdentityMismatch", "message": "image changed since preflight"}
            receipt["result"] = {"status": "INVALID", "reason": "run_failure:ImageIdentityMismatch"}
            return
        with tempfile.TemporaryDirectory(prefix="threadline-24722-", dir="/private/tmp") as temp:
            os.chmod(temp, 0o700)
            root = Path(temp)
            schedule = [("warmup", "async", None), ("warmup", "sync", None)]
            schedule.extend(("pair", mode, None) for pair in PAIR_SCHEDULE for mode in pair)
            schedule.extend([("control", "sync", "pre_exunit"), ("control", "sync", "setup_all")])
            for index, (kind, mode, control) in enumerate(schedule, 1):
                if time.monotonic() - started >= TOTAL_SECONDS:
                    receipt["overall_deadline_reached"] = True
                    break
                case = arm_source["setup_all"] if control == "setup_all" else arm_source[mode]
                arm_id = f"arm-{index:02d}-{kind}-{control or mode}"
                arm = run_child(root, receipt, arm_id, kind, mode, control, case,
                                deadline, runner_bytes, formatter_bytes)
                receipt["arms"].append(arm)
                receipt["attempted_count"] = len(receipt["arms"])
                structural_errors = classify_arm(arm) if kind in {"warmup", "pair"} else []
                control_failure = control_error(receipt["arms"], arm) if kind == "control" else None
                if kind == "pair" and len([item for item in receipt["arms"] if item["kind"] == "pair"]) % 2 == 0:
                    structural_errors.extend(pair_quality_errors(
                        [item for item in receipt["arms"] if item["kind"] == "pair"]))
                if arm.get("error_code") or arm.get("timed_out") or arm.get("parse_error") or structural_errors or control_failure:
                    stop_reason = (arm.get("error_code") or arm.get("parse_error") or control_failure or
                                   ";".join(structural_errors) or "child_invalid")
                    receipt["early_stop"] = {"after": arm_id, "reason": stop_reason}
                    break
            status, reason = derive_validation_status(receipt["arms"])
            if receipt.get("early_stop") and status == "INVALID" and reason == "fixed_schedule_incomplete":
                stop_reason = receipt["early_stop"].get("reason")
                supported = {item for arm in receipt["arms"] for item in classify_arm(arm)}
                supported.update(pair_quality_errors(
                    [arm for arm in receipt["arms"] if arm.get("kind") == "pair"]))
                supported.update(arm.get("error_code") for arm in receipt["arms"] if arm.get("error_code"))
                supported.update(arm.get("parse_error") for arm in receipt["arms"] if arm.get("parse_error"))
                if stop_reason in supported:
                    reason = stop_reason
            receipt["result"] = {"status": status, "reason": reason}
            receipt["cleanup"] = {"temp_directory": "private temporary directory removed by owner",
                                  "containers": "only unique owned container names removed", "network": "disabled"}
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            raise TimeoutError("overall deadline leaves no time for post-run image inspection")
        receipt["image_after"] = docker_image(timeout=max(0.1, min(8, remaining)))
        if receipt["image_after"] != receipt.get("image_before"):
            receipt["run_failure"] = {"type": "ImageIdentityChanged", "message": "post-run image inspection differs"}
            receipt["result"] = {"status": "INVALID", "reason": "run_failure:ImageIdentityChanged"}
    except Exception as exc:
        receipt["run_failure"] = {"type": type(exc).__name__, "message": bounded_output(str(exc))}
        receipt["result"] = {"status": "INVALID", "reason": f"run_failure:{type(exc).__name__}"}
    finally:
        ended_ns = time.monotonic_ns()
        receipt["collection"]["ended_monotonic_ns"] = ended_ns
        receipt["collection"]["ended_at_utc"] = utc_now()
        receipt["elapsed_ms"] = round((ended_ns - started_ns) / 1_000_000)
        receipt["overall_deadline_reached"] = receipt.get("overall_deadline_reached", False) or \
            receipt["elapsed_ms"] >= TOTAL_SECONDS * 1000
        receipt["attempted_count"] = len(receipt["arms"])
        if receipt["elapsed_ms"] > TOTAL_SECONDS * 1000 and receipt["result"].get("status") != "INVALID":
            receipt["result"] = {"status": "INVALID", "reason": "overall_collection_deadline_exceeded"}
        if receipt["result"].get("reason") == "run_in_progress":
            receipt["run_failure"] = {"type": "Interrupted", "message": "run ended before terminal status"}
            receipt["result"] = {"status": "INVALID", "reason": "run_failure:Interrupted"}
        write_once(output, receipt)
    print(f"validation: {receipt['result']['status']} ({receipt['result']['reason']})")


def execute_run(output: Path) -> None:
    receipt = base_receipt(output)
    started = time.monotonic()
    receipt["run_started_monotonic_host_ms"] = round(started * 1000)
    receipt["result"] = {"status": "INVALID", "reason": "run_in_progress"}
    with tempfile.TemporaryDirectory(prefix="threadline-24720-", dir="/private/tmp") as temp:
        os.chmod(temp, 0o700)
        root = Path(temp)
        sources = {"async": make_case(True), "sync": make_case(False),
                   "setup_all": make_case(False, True)}
        schedule = [("warmup", "async", None), ("warmup", "sync", None)]
        schedule.extend(("pair", mode, None) for pair in PAIR_SCHEDULE for mode in pair)
        schedule.extend([("control", "sync", "pre_exunit"),
                         ("control", "sync", "setup_all")])
        for idx, (kind, mode, control) in enumerate(schedule, 1):
            if time.monotonic() - started >= TOTAL_SECONDS:
                break
            source = sources["setup_all"] if control == "setup_all" else sources[mode]
            arm_id = f"arm-{idx:02d}-{kind}-{control or mode}"
            arm = run_child(root, receipt, arm_id, kind, mode, control, source,
                            started + TOTAL_SECONDS)
            receipt["arms"].append(arm)
            receipt["attempted_count"] = len(receipt["arms"])
            measured_control_error = control_error(receipt["arms"], arm)
            if measured_control_error:
                arm["error_code"] = measured_control_error
            if arm.get("error_code") or arm.get("timed_out") or classify_arm(arm):
                receipt["early_stop"] = {"after": arm_id, "reason": arm.get("error_code") or "arm_invalid"}
                break
        status, reason = derive_status(receipt["arms"])
        receipt["result"] = {"status": status, "reason": reason}
        receipt["elapsed_ms"] = round((time.monotonic() - started) * 1000)
        try:
            receipt["image_after"] = docker_image()
        except Exception as exc:
            receipt["result"] = {"status": "INVALID", "reason": "image_reinspection_failed"}
            receipt["image_after_error"] = type(exc).__name__
        if receipt.get("image_after") is not None and receipt["image_after"] != receipt["image"]:
            receipt["result"] = {"status": "INVALID", "reason": "image_identity_changed"}
        receipt["source"]["status_after"] = source_status()
        if receipt["elapsed_ms"] > TOTAL_SECONDS * 1000:
            receipt["result"] = {"status": "INVALID", "reason": "overall_deadline_exceeded"}
        receipt["cleanup"] = {"temp_directory": "private temporary directory removed by owner",
                               "containers": "only unique owned container names removed",
                               "network": "disabled"}
        receipt["attempted_count"] = len(receipt["arms"])
        write_receipt(output, receipt)
        receipt["source"]["status_after"] = source_status()
        write_receipt(output, receipt)


def self_test() -> None:
    for value in (-576460751714, 0, 37):
        parsed = parse_events(f"THREADLINE_EVENT|helper_start|{value}\n")
        if parsed != [{"name": "helper_start", "mono_ms": value}]:
            raise SystemExit(f"signed timestamp fixture failed for {value}")
    receipt_order = parse_events(
        "THREADLINE_EVENT|require_return|2\nTHREADLINE_EVENT|registration_async|1\n"
    )
    if [event["name"] for event in receipt_order] != ["require_return", "registration_async"]:
        raise SystemExit("event receipt order was changed while parsing captured occurrence times")
    try:
        parse_events("THREADLINE_EVENT|helper_start|not-a-clock\n")
    except ValueError:
        pass
    else:
        raise SystemExit("malformed clock fixture was accepted")

    parsed_failure = {"stderr_excerpt": bounded_output("child diagnostic")}
    record_parse_error(parsed_failure, ValueError("malformed event record"))
    if parsed_failure["stderr_excerpt"] != "child diagnostic" or not parsed_failure["parse_error"]:
        raise SystemExit("parser failure did not retain stderr separately")

    # Synthetic receipts exercise both acceptance and fail-closed mutations; no Docker invocation.
    def synthetic_arm(i: int, mode: str, kind: str = "pair", control: str | None = None) -> dict:
        base = 1000 + i * 10000
        async_mode = mode == "async"
        ev = [{"name": "helper_start", "mono_ms": base},
              {"name": "exunit_start", "mono_ms": base + 1},
              {"name": "require_start", "mono_ms": base + 2},
              {"name": "registration_" + mode, "mono_ms": base + 3},
              {"name": "require_return", "mono_ms": base + 4},
              {"name": "barrier_start", "mono_ms": base + 5},
              {"name": "module_started", "mono_ms": base + (100 if async_mode else 2100)},
              {"name": "barrier_release", "mono_ms": base + 2005},
              {"name": "suite_finished", "mono_ms": base + 2100}]
        ev.sort(key=lambda event: event["mono_ms"])
        arm = {"id": f"test-{i}", "kind": kind, "mode": mode, "control": control,
               "exit_code": 0, "timed_out": False, "events": ev,
               "runtime": {"elixir": ELIXIR_VERSION, "otp": OTP_VERSION,
                           "architecture": "aarch64-unknown-linux-gnu"},
               "stdout_excerpt": "", "stderr_excerpt": "",
               "raw_tsv_excerpt": "",
               "formatter": {"boot_ms": 1000 if mode == "sync" else 100,
                             "wall_ms": 2100, "header": f"# {FORMAT} partition=1 lane=local boot_ms=1 wall_ms=2"}}
        arm_start = 10_000_000_000 + i * 100_000_000
        arm.update({"started_monotonic_ns": arm_start, "child_started_monotonic_ns": arm_start + 1_000_000,
                    "child_ended_monotonic_ns": arm_start + 11_000_000, "ended_monotonic_ns": arm_start + 20_000_000,
                    "child_duration_ms": 10, "duration_ms": 20, "cleanup_duration_ms": 10})
        if control == "pre_exunit": arm["formatter"]["boot_ms"] = 3000
        if control == "setup_all": arm["formatter"].update({"boot_ms": 1100, "wall_ms": 4100})
        event_lines = [f"THREADLINE_EVENT|{event['name']}|{event['mono_ms']}" for event in ev]
        arm["stdout_excerpt"] = "\n".join([f"THREADLINE_RUNTIME|{ELIXIR_VERSION}|{OTP_VERSION}|aarch64-unknown-linux-gnu",
                                             *event_lines])
        header = (f"# {FORMAT} partition=1 lane=local boot_ms={arm['formatter']['boot_ms']} "
                  f"wall_ms={arm['formatter']['wall_ms']}")
        arm["raw_tsv_excerpt"] = f"{header}\nlocal.exs\t1\t1\n"
        arm["formatter"] = parse_tsv(arm["raw_tsv_excerpt"])
        return arm

    arms = [synthetic_arm(0, "async", "warmup"), synthetic_arm(1, "sync", "warmup")]
    arms.extend(synthetic_arm(2 + i * 2 + j, mode)
                for i, pair in enumerate(PAIR_SCHEDULE) for j, mode in enumerate(pair))
    arms.extend([synthetic_arm(20, "sync", "control", "pre_exunit"),
                 synthetic_arm(21, "sync", "control", "setup_all")])
    receipt = {"schema": "threadline.exunit-boundary-canary/1",
               "runtime": {"elixir": ELIXIR_VERSION, "otp": OTP_VERSION},
               "image": {"id": "sha256:" + "a" * 64, "repo_digests": ["hexpm/elixir@sha256:" + "b" * 64], "architecture": "arm64"},
               "hashes": {"formatter_sha256": sha256(subprocess.run(
                              ["git", "show", f"{run_cmd(['git', 'rev-parse', 'HEAD'])}:test/support/partition_monitor.ex"],
                              check=True, stdout=subprocess.PIPE).stdout),
                          "runner_sha256": sha256(subprocess.run(
                              ["git", "show", f"{run_cmd(['git', 'rev-parse', 'HEAD'])}:.planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_case.exs"],
                              check=True, stdout=subprocess.PIPE).stdout),
                          "canary_sha256": {"async": sha256(make_case(True)),
                                            "sync": sha256(make_case(False)),
                                            "setup_all": sha256(make_case(False, True))}},
               "budgets": {"child_seconds": CHILD_SECONDS, "overall_seconds": TOTAL_SECONDS},
               "preflight": {"path": PREFLIGHT.name, "sha256": sha256(PREFLIGHT.read_bytes())},
               "arms": arms, "attempted_count": len(arms),
               "historical_ci_cause": "UNPROVEN", "ci_02": "INCOMPLETE", "ci_03": "MISS",
               "source": {"head": run_cmd(["git", "rev-parse", "HEAD"])},
               "producer": {"commit": run_cmd(["git", "rev-parse", "HEAD"]),
                            "coordinator": ".planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_probe.py",
                            "coordinator_sha256": sha256(subprocess.run(["git", "show", f"{run_cmd(['git', 'rev-parse', 'HEAD'])}:.planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_probe.py"], check=True, stdout=subprocess.PIPE).stdout)},
               "result": {"status": "VALID_SEMANTIC", "reason": "synthetic"}}
    positive_errors = check_receipt(receipt)
    if positive_errors:
        raise SystemExit("self-test positive fixture rejected: " + "; ".join(positive_errors))
    if derive_status(arms)[0] != "VALID_SEMANTIC":
        raise SystemExit("self-test positive fixture did not derive VALID_SEMANTIC")
    mutations = []
    def mutate(label: str, fn) -> None:
        changed = json.loads(json.dumps(receipt))
        fn(changed)
        mutations.append((label, bool(check_receipt(changed))))
    mutate("missing_event", lambda r: r["arms"][2]["events"].pop(0))
    mutate("wrong_event_order", lambda r: r["arms"][2]["events"][0].update({"mono_ms": 1000000}))
    mutate("wrong_runtime", lambda r: r["runtime"].update({"otp": "wrong"}))
    mutate("wrong_image", lambda r: r["image"].update({"architecture": "amd64"}))
    mutate("wrong_formatter", lambda r: r["hashes"].update({"formatter_sha256": "0"}))
    mutate("extra_arm", lambda r: r["arms"].append(dict(r["arms"][-1], id="extra")))
    mutate("duplicate_arm", lambda r: r["arms"].append(dict(r["arms"][-1])))
    mutate("lost_arm", lambda r: r["arms"].pop())
    mutate("malformed_tsv", lambda r: r["arms"][2].update({"formatter": None}))
    mutate("timeout", lambda r: r["arms"][2].update({"timed_out": True}))
    mutate("missing_stderr_capture", lambda r: r["arms"][2].pop("stderr_excerpt"))
    mutate("historical_producer", lambda r: r["producer"].update({"coordinator_sha256": "0" * 64}))
    mutate("historical_producer_commit", lambda r: r["producer"].update({"commit": "0" * 40}))
    if not all(ok for _, ok in mutations):
        raise SystemExit("self-test failed: " + ", ".join(label for label, ok in mutations if not ok))
    # An honest, typed INVALID receipt is valid as a stop, never as a semantic claim.
    invalid = json.loads(json.dumps(receipt))
    invalid["result"] = {"status": "INVALID", "reason": "synthetic_invalid"}
    assert not check_receipt(invalid)

    # Exercise the separate validation schema through its persisted CLI verifier and report projection.
    global VALIDATION_PREFLIGHT
    with tempfile.TemporaryDirectory(prefix="threadline-24722-self-test-") as temp:
        temp_dir = Path(temp)
        prior_preflight = VALIDATION_PREFLIGHT
        VALIDATION_PREFLIGHT = temp_dir / "247-LOCAL-CANARY-VALIDATION-PREFLIGHT.json"
        image = {"tag": IMAGE_TAG, "id": "sha256:" + "a" * 64,
                 "repo_digests": ["hexpm/elixir@sha256:" + "b" * 64],
                 "os": "linux", "architecture": "arm64", "size_bytes": 1}
        head = run_cmd(["git", "rev-parse", "HEAD"])
        coordinator_path = ".planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_probe.py"
        coordinator, runner, formatter, runner_hash, formatter_hash = load_committed_sources(head)
        preflight_fixture = {"schema": "threadline.exunit-boundary-preflight/1", "plan": "247-22",
            "collected_at_utc": "2026-10-27T00:00:00.000Z", "source": {"head": head},
            "image": image, "image_inspection": image,
            "runtime": {"elixir": ELIXIR_VERSION, "otp": OTP_VERSION,
                        "architecture": "aarch64-unknown-linux-gnu"},
            "producer": {"commit": head, "path": coordinator_path, "sha256": sha256(coordinator)},
            "hashes": {"runner_sha256": runner_hash, "formatter_sha256": formatter_hash},
            "historical_sha256": HISTORICAL_HASHES,
            "result": {"status": "VALID", "reason": "synthetic"}}
        write_once(VALIDATION_PREFLIGHT, preflight_fixture)
        validation_arms = [synthetic_arm(0, "async", "warmup"), synthetic_arm(1, "sync", "warmup")]
        validation_arms.extend(synthetic_arm(2 + i * 2 + j, mode)
                               for i, pair in enumerate(PAIR_SCHEDULE) for j, mode in enumerate(pair))
        validation_arms.extend([synthetic_arm(20, "sync", "control", "pre_exunit"),
                                synthetic_arm(21, "sync", "control", "setup_all")])
        validation_receipt = {"schema": VALIDATION_SCHEMA, "plan": "247-22",
            "series_id": "247-22-authorized-local-series",
            "output": "247-LOCAL-CANARY-VALIDATION.json", "source": {"head": head},
            "producer": {"commit": head, "path": coordinator_path,
                         "sha256": sha256(committed_file(head, coordinator_path))},
            "image": image, "image_before": image, "image_after": image,
            "runtime": {"elixir": ELIXIR_VERSION, "otp": OTP_VERSION},
            "hashes": {"runner_sha256": runner_hash,
                       "formatter_sha256": formatter_hash,
                       "canary_sha256": {"async": sha256(make_case(True)), "sync": sha256(make_case(False)),
                                         "setup_all": sha256(make_case(False, True))}},
            "historical_sha256": HISTORICAL_HASHES,
            "preflight": {"path": VALIDATION_PREFLIGHT.name,
                          "sha256": sha256(VALIDATION_PREFLIGHT.read_bytes())},
            "collection": {"started_at_utc": "2026-10-27T00:00:00.000Z",
                           "ended_at_utc": "2026-10-27T00:00:11.000Z",
                           "started_monotonic_ns": 9_000_000_000,
                           "ended_monotonic_ns": 20_000_000_000,
                           "clock": "synthetic"},
            "elapsed_ms": 11_000, "overall_deadline_reached": False,
            "budgets": {"child_seconds": CHILD_SECONDS, "overall_seconds": TOTAL_SECONDS,
                        "max_warmups": MAX_WARMUPS, "pairs": PAIR_SCHEDULE, "max_controls": 2},
            "arms": validation_arms, "attempted_count": len(validation_arms),
            "reservation": {"path": "247-LOCAL-CANARY-VALIDATION.reservation.json", "sha256": None},
            "historical_ci_cause": "UNPROVEN", "ci_02": "INCOMPLETE", "ci_03": "MISS"}
        reservation_path = validation_path = temp_dir / "247-LOCAL-CANARY-VALIDATION.reservation.json"
        write_once(reservation_path, {"schema": "threadline.exunit-boundary-reservation/1", "plan": "247-22",
                    "series_id": validation_receipt["series_id"],
                    "preflight_sha256": validation_receipt["preflight"]["sha256"],
                    "producer_sha256": validation_receipt["producer"]["sha256"]})
        validation_receipt["reservation"]["sha256"] = sha256(reservation_path.read_bytes())
        validation_status = derive_validation_status(validation_arms)
        validation_receipt["result"] = {"status": validation_status[0], "reason": validation_status[1]}
        validation_path = temp_dir / "247-LOCAL-CANARY-VALIDATION.json"
        write_once(validation_path, validation_receipt)
        if check_validation_receipt(validation_receipt, validation_path):
            raise SystemExit("synthetic validation receipt failed structural verification")
        if validation_status[0] != "VALID_SEMANTIC":
            raise SystemExit("synthetic async/sync boundary did not derive VALID_SEMANTIC")

        no_signal = json.loads(json.dumps(validation_receipt))
        for arm in no_signal["arms"]:
            if arm.get("kind") in {"warmup", "pair"}:
                for event in arm["events"]:
                    if event["name"] == "module_started":
                        event["mono_ms"] = next(item["mono_ms"] for item in arm["events"]
                                                  if item["name"] == "barrier_release") - 100
                arm["stdout_excerpt"] = "\n".join(
                    [f"THREADLINE_RUNTIME|{ELIXIR_VERSION}|{OTP_VERSION}|aarch64-unknown-linux-gnu"] +
                    [f"THREADLINE_EVENT|{event['name']}|{event['mono_ms']}" for event in arm["events"]])
        no_signal_status = derive_validation_status(no_signal["arms"])
        no_signal["result"] = {"status": no_signal_status[0], "reason": no_signal_status[1]}
        if no_signal_status[0] != "VALID_NO_SIGNAL" or check_validation_receipt(no_signal, validation_path):
            raise SystemExit("stable no-distinction fixture did not verify as VALID_NO_SIGNAL: " +
                             repr((no_signal_status, check_validation_receipt(no_signal))))

        mutations = []
        def validation_mutation(label: str, fn) -> None:
            changed = json.loads(json.dumps(validation_receipt))
            fn(changed)
            mutations.append((label, bool(check_validation_receipt(changed, validation_path))))
        validation_mutation("source_hash", lambda value: value["producer"].update({"sha256": "0" * 64}))
        validation_mutation("historical_hash", lambda value: value["historical_sha256"].update({"247-FROZEN-REPLAY.json": "0" * 64}))
        validation_mutation("lost_stderr", lambda value: value["arms"][2].pop("stderr_excerpt"))
        validation_mutation("duplicate_arm", lambda value: value["arms"].append(dict(value["arms"][-1])))
        validation_mutation("changed_schedule", lambda value: value["arms"][2].update({"mode": "sync"}))
        validation_mutation("bad_control", lambda value: value["arms"][-1]["formatter"].update({"wall_ms": 999999}))
        validation_mutation("false_semantic", lambda value: value["result"].update({"status": "VALID_NO_SIGNAL"}))
        validation_mutation("false_invalid", lambda value: value["result"].update({"status": "INVALID", "reason": "forged_failure"}))
        if not all(rejected for _label, rejected in mutations):
            raise SystemExit("validation mutation accepted: " + ", ".join(
                label for label, rejected in mutations if not rejected))

        invalid_preflight_path = temp_dir / "invalid" / "247-LOCAL-CANARY-VALIDATION-PREFLIGHT.json"
        invalid_preflight = {"schema": "threadline.exunit-boundary-preflight/1",
                             "historical_sha256": HISTORICAL_HASHES, "image": None,
                             "result": {"status": "INVALID", "reason": "preflight_failed:RuntimeError"}}
        write_once(invalid_preflight_path, invalid_preflight)
        VALIDATION_PREFLIGHT = invalid_preflight_path
        preflight_stop = json.loads(json.dumps(validation_receipt))
        preflight_stop.update({"image": None, "arms": [], "attempted_count": 0,
            "preflight": {"path": invalid_preflight_path.name,
                          "sha256": sha256(invalid_preflight_path.read_bytes())},
            "result": {"status": "INVALID", "reason": "preflight_invalid:preflight_failed:RuntimeError"}})
        invalid_reservation = invalid_preflight_path.with_name("247-LOCAL-CANARY-VALIDATION.reservation.json")
        write_once(invalid_reservation, {"schema": "threadline.exunit-boundary-reservation/1",
                    "plan": "247-22", "series_id": preflight_stop["series_id"],
                    "preflight_sha256": preflight_stop["preflight"]["sha256"],
                    "producer_sha256": preflight_stop["producer"]["sha256"]})
        preflight_stop["reservation"] = {"path": invalid_reservation.name,
                                          "sha256": sha256(invalid_reservation.read_bytes())}
        if check_validation_receipt(preflight_stop, invalid_preflight_path.with_name(
                "247-LOCAL-CANARY-VALIDATION.json")):
            raise SystemExit("preflight failure was not preserved as an honest terminal INVALID stop: " +
                             repr(check_validation_receipt(preflight_stop)))
        VALIDATION_PREFLIGHT = temp_dir / "247-LOCAL-CANARY-VALIDATION-PREFLIGHT.json"

        report = temp_dir / "report.md"
        projection = json.dumps(validation_report_projection(validation_receipt), indent=2, sort_keys=True)
        report.write_text(f"<!-- receipt-projection:start -->\n{projection}\n<!-- receipt-projection:end -->\n",
                          encoding="utf-8")
        env = {**os.environ, "THREADLINE_VALIDATION_PREFLIGHT": str(VALIDATION_PREFLIGHT)}
        result = subprocess.run([sys.executable, "-B", str(Path(__file__).resolve()), "--verify",
                                 str(validation_path), "--report", str(report)],
                                check=False, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                text=True, env=env)
        if result.returncode != 0 or "VALID_SEMANTIC" not in result.stdout:
            raise SystemExit("synthetic CLI receipt/report round-trip failed: " + result.stderr.strip())
        try:
            write_once(validation_path, validation_receipt)
        except FileExistsError:
            pass
        else:
            raise SystemExit("write-once receipt path allowed replacement")
        VALIDATION_PREFLIGHT = prior_preflight
    compiler_failure = compile_smoke_result(1, "", "** (CompileError) runner.exs: syntax error\n")
    missing_marker = compile_smoke_result(0, "", "")
    marker_only = compile_smoke_result(0, COMPILE_SMOKE_MARKER + "\n", "")
    if compiler_failure["status"] != "INVALID" or "compile_smoke_child_failed" not in compiler_failure["reason"]:
        raise SystemExit("saved compiler-error fixture was not terminal INVALID")
    if missing_marker["status"] != "INVALID" or marker_only["status"] != "COMPILE_OK" or \
            marker_only["events"] or marker_only["status"] == "VALID_SEMANTIC":
        raise SystemExit("compile marker controls fabricated semantic events or a semantic verdict")
    historical_validation = json.loads((PHASE_DIR / "247-LOCAL-CANARY-VALIDATION.json").read_text(
        encoding="utf-8"))
    compiler_arm = next((arm for arm in historical_validation.get("arms", [])
                         if arm.get("exit_code") == 1 and "CompileError" in arm.get("stderr_excerpt", "")), None)
    if not compiler_arm:
        raise SystemExit("immutable compiler-error receipt fixture is unavailable")
    saved_compile_error = compile_smoke_result(compiler_arm["exit_code"],
                                               compiler_arm.get("stdout_excerpt", ""),
                                               compiler_arm["stderr_excerpt"])
    synthetic_recheck_projection = recheck_report_projection({
        "schema": RECHECK_SCHEMA, "plan": "247-23",
        "preflight": {"compile_smoke": {"exit_code": compiler_arm["exit_code"],
                                         "stdout_excerpt": compiler_arm.get("stdout_excerpt", ""),
                                         "stderr_excerpt": compiler_arm["stderr_excerpt"]},
                      "compile_smoke_result": saved_compile_error},
        "result": {"status": "INVALID", "reason": saved_compile_error["reason"]},
        "historical_ci_cause": "UNPROVEN", "ci_02": "INCOMPLETE", "ci_03": "MISS"})
    projected_smoke = synthetic_recheck_projection["preflight"]["compile_smoke"]
    if saved_compile_error["status"] != "INVALID" or \
            projected_smoke["stderr_excerpt"] != compiler_arm["stderr_excerpt"] or \
            synthetic_recheck_projection["result"]["status"] != "INVALID" or saved_compile_error["events"]:
        raise SystemExit("saved compiler-error stderr did not survive the synthetic report projection")
    for filename, expected in HISTORICAL_HASHES.items():
        if sha256((PHASE_DIR / filename).read_bytes()) != expected:
            raise SystemExit(f"historical immutable hash changed: {filename}")
    print("synthetic round-trip PASS")


def validation_report_projection(receipt: dict) -> dict:
    return {"source": receipt.get("source"), "producer": receipt.get("producer"),
            "image": receipt.get("image"), "runtime": receipt.get("runtime"),
            "hashes": receipt.get("hashes"), "historical_sha256": receipt.get("historical_sha256"),
            "preflight": receipt.get("preflight"), "collection": receipt.get("collection"),
            "budgets": receipt.get("budgets"), "result": receipt.get("result"),
            "attempted_count": receipt.get("attempted_count"), "arms": receipt.get("arms"),
            "historical_ci_cause": receipt.get("historical_ci_cause"),
            "ci_02": receipt.get("ci_02"), "ci_03": receipt.get("ci_03")}


def verify(path: Path, report: Path | None = None) -> None:
    receipt = json.loads(path.read_text(encoding="utf-8"))
    if receipt.get("schema") == RECHECK_SCHEMA:
        errors = check_recheck_receipt(receipt, path)
    elif receipt.get("schema") in RECHECK_PREFLIGHT_SCHEMAS:
        errors = check_recheck_preflight(receipt, path)
    elif receipt.get("schema") == VALIDATION_SCHEMA:
        errors = check_validation_receipt(receipt, path)
    else:
        errors = check_receipt(receipt)
    if report:
        text = report.read_text(encoding="utf-8")
        marker = "<!-- receipt-projection:start -->"
        end = "<!-- receipt-projection:end -->"
        projection = (recheck_report_projection(receipt) if receipt.get("schema") == RECHECK_SCHEMA else
                      recheck_preflight_report_projection(receipt)
                      if receipt.get("schema") in RECHECK_PREFLIGHT_SCHEMAS else
                      validation_report_projection(receipt) if receipt.get("schema") == VALIDATION_SCHEMA else {
                "status": receipt.get("result", {}).get("status"),
                 "reason": receipt.get("result", {}).get("reason"),
                 "attempted_count": receipt.get("attempted_count"),
                 "arms": [{"id": a.get("id"), "kind": a.get("kind"), "mode": a.get("mode"),
                          "control": a.get("control"), "exit_code": a.get("exit_code"),
                          "timed_out": a.get("timed_out"), "stdout_excerpt": a.get("stdout_excerpt"),
                          "stderr_excerpt": a.get("stderr_excerpt"), "formatter": a.get("formatter"),
                          "events": a.get("events"), "error_code": a.get("error_code")}
                         for a in receipt.get("arms", [])],
                 "historical_ci_cause": receipt.get("historical_ci_cause"),
                 "ci_02": receipt.get("ci_02"), "ci_03": receipt.get("ci_03")})
        if marker not in text or end not in text or text.split(marker, 1)[1].split(end, 1)[0].strip() != json.dumps(
                projection, indent=2, sort_keys=True):
            errors.append("report_projection_mismatch")
    if errors:
        print("INVALID receipt: " + "; ".join(errors), file=sys.stderr)
        raise SystemExit(1)
    print(f"verify: PASS ({receipt['result']['status']}; {receipt.get('attempted_count', 0)} attempted arms)")


def recheck_decision_authorized(candidate_head: str) -> bool:
    try:
        expected = ("Decision: authorize-one-recheck-series\n"
                    f"Source-Head: {candidate_head}\n"
                    "Schedule: warmup=async,sync;pair=async/sync,sync/async,async/sync;"
                    "control=pre_exunit,setup_all\n"
                    f"Limits: child={CHILD_SECONDS}s,total={TOTAL_SECONDS}s;warmups={MAX_WARMUPS};"
                    "controls=2;series=1\n")
        return bool(candidate_head) and RECHECK_DECISION.read_text(encoding="utf-8") == expected
    except (OSError, UnicodeError):
        return False


def recheck_source_binding(head: str) -> dict:
    producer = committed_file(head, RECHECK_PRODUCER_PATH)
    coordinator = committed_file(head, RECHECK_COORDINATOR_PATH)
    runner = committed_file(head, RECHECK_RUNNER_PATH)
    formatter = committed_file(head, RECHECK_FORMATTER_PATH)
    return {"producer": {"commit": head, "path": RECHECK_PRODUCER_PATH,
                         "sha256": sha256(producer)},
            "hashes": {"runner_sha256": sha256(runner),
                       "formatter_sha256": sha256(formatter)},
            "coordinator": coordinator, "runner": runner, "formatter": formatter}


def validate_recheck_source(receipt: dict, require_current: bool = True) -> list[str]:
    """Execution requires clean current bytes; read-only history binds to its own commit."""
    errors = []
    source = receipt.get("source") or {}
    producer = receipt.get("producer") or {}
    hashes = receipt.get("hashes") or {}
    head = source.get("head")
    try:
        if producer.get("commit") != head or producer.get("path") != RECHECK_PRODUCER_PATH:
            errors.append("recheck_producer_binding_invalid")
        binding = recheck_source_binding(head or "")
        if producer.get("sha256") != binding["producer"]["sha256"]:
            errors.append("recheck_producer_hash_mismatch")
        if hashes != binding["hashes"]:
            errors.append("recheck_source_hash_mismatch")
        if receipt.get("schema") in RECHECK_PREFLIGHT_SCHEMAS:
            version = re.search(rb'^RECHECK_PREFLIGHT_SCHEMA = "([^"]+)"$',
                                binding["coordinator"], re.MULTILINE)
            if not version or version.group(1).decode("ascii") != receipt["schema"]:
                errors.append("recheck_preflight_schema_not_bound_to_producer")
        if require_current and Path(__file__).read_bytes() != binding["coordinator"]:
            errors.append("recheck_coordinator_worktree_differs_from_committed_bytes")
        if require_current and (ELIXIR.read_bytes() != binding["runner"] or
                                FORMATTER.read_bytes() != binding["formatter"]):
            errors.append("recheck_worktree_source_differs_from_committed_bytes")
        if subprocess.run(["git", "merge-base", "--is-ancestor", head,
                           run_cmd(["git", "rev-parse", "HEAD"])], stdout=subprocess.DEVNULL,
                          stderr=subprocess.DEVNULL).returncode != 0:
            errors.append("recheck_source_not_in_current_history")
    except (OSError, ValueError, subprocess.CalledProcessError, TypeError):
        errors.append("recheck_source_binding_unverifiable")
    return errors


def recheck_preflight(output: Path) -> None:
    output = output.resolve()
    if output != (PHASE_DIR / "247-LOCAL-CANARY-RECHECK-PREFLIGHT.json").resolve():
        raise RuntimeError("recheck preflight must use its dedicated output path")
    if output.name in {OLD_RECEIPT.name, OLD_PREFLIGHT.name, FROZEN_REPLAY.name,
                       "247-LOCAL-CANARY-VALIDATION.json", "247-LOCAL-CANARY-VALIDATION-PREFLIGHT.json"}:
        raise RuntimeError("historical receipt paths are immutable")
    if output.exists() or RECHECK_RESERVATION.exists():
        raise RuntimeError("recheck preflight or series reservation already exists (write-once)")
    head = run_cmd(["git", "rev-parse", "HEAD"])
    if not recheck_decision_authorized(head):
        raise RuntimeError("an exact recheck series decision for the current source candidate is required")
    binding = recheck_source_binding(head)
    source_check = {"source": {"head": head}, "producer": binding["producer"],
                    "hashes": binding["hashes"]}
    source_errors = validate_recheck_source(source_check)
    if source_errors:
        raise RuntimeError("recheck source is not clean and committed: " + ";".join(source_errors))
    series_started_ns = time.monotonic_ns()
    preflight_limit_ns = PREFLIGHT_SECONDS * 1_000_000_000
    preflight_deadline_ns = series_started_ns + preflight_limit_ns
    receipt = {"schema": RECHECK_PREFLIGHT_SCHEMA, "plan": "247-23",
               "source": {"head": head, "status_before": source_status()},
               "producer": binding["producer"], "hashes": binding["hashes"],
               "historical_sha256": HISTORICAL_HASHES, "image": None, "runtime": None,
               "compile_smoke": None, "result": {"status": "INVALID", "reason": "preflight_not_completed"}}
    reservation = {"schema": "threadline.exunit-boundary-recheck-reservation/1",
                   "plan": "247-23", "series_id": uuid.uuid4().hex,
                   "source_head": head, "producer_sha256": binding["producer"]["sha256"],
                   "decision_sha256": sha256(RECHECK_DECISION.read_bytes()),
                   "preflight_output": output.name, "created_at_utc": utc_now(),
                   "series_started_monotonic_ns": series_started_ns,
                   "series_budget_seconds": TOTAL_SECONDS}
    write_once(RECHECK_RESERVATION, reservation)
    try:
        image = docker_image(timeout=deadline_timeout(preflight_deadline_ns, 8))
        receipt["image"] = image
        if not valid_image_identity(image):
            raise RuntimeError("cached image identity is not immutable ARM64")
        with tempfile.TemporaryDirectory(prefix="threadline-24723-preflight-") as private:
            root = Path(private)
            (root / "runner.exs").write_bytes(binding["runner"])
            (root / "formatter.ex").write_bytes(binding["formatter"])
            name = RECHECK_NAME_PREFIX + uuid.uuid4().hex[:12]
            cidfile = root / "owned.cid"
            result = run_owned_container(name, cidfile,
                ["--mount", f"type=bind,src={root},dst=/probe", "--entrypoint", "elixir",
                 image["id"], "/probe/runner.exs", "--compile-smoke"],
                deadline_timeout(preflight_deadline_ns, CHILD_SECONDS), deadline_ns=preflight_deadline_ns)
            receipt["compile_smoke_result"] = compile_smoke_result(
                result.get("launch_exit_code"), result.get("stdout_excerpt", ""),
                result.get("stderr_excerpt", ""))
            receipt["runtime"] = parse_runtime(result.get("stdout_excerpt", ""))
            receipt["compile_smoke"] = result
    except Exception as exc:
        receipt["stderr_excerpt"] = bounded_output(f"{type(exc).__name__}: {exc}")
        receipt["result"] = {"status": "INVALID", "reason": f"preflight_failed:{type(exc).__name__}"}
    receipt["timing"] = elapsed_timing(series_started_ns, preflight_limit_ns)
    receipt["result"] = derive_recheck_preflight_result(receipt)
    receipt["reservation"] = {"path": RECHECK_RESERVATION.name,
                               "sha256": sha256(RECHECK_RESERVATION.read_bytes())}
    write_once(output, receipt)
    print(f"recheck preflight: {receipt['result']['status']} ({receipt['result']['reason']})")


def preflight_timing_errors(preflight: dict) -> list[str]:
    if preflight.get("schema") != RECHECK_PREFLIGHT_SCHEMA:
        return []
    timing = preflight.get("timing")
    errors = timing_errors(timing, "preflight", PREFLIGHT_SECONDS * 1_000_000_000)
    smoke = preflight.get("compile_smoke")
    if isinstance(smoke, dict):
        child_timing = smoke.get("timing")
        child_errors = timing_errors(child_timing, "compile_smoke", CHILD_SECONDS * 1_000_000_000)
        if not errors and not child_errors and (
                child_timing["started_monotonic_ns"] < timing["started_monotonic_ns"] or
                child_timing["ended_monotonic_ns"] > timing["ended_monotonic_ns"] or
                child_timing["started_monotonic_ns"] + child_timing["limit_ns"] >
                timing["started_monotonic_ns"] + timing["limit_ns"]):
            child_errors.append("compile_smoke_timing_outside_preflight")
        errors.extend(child_errors)
    return errors


def derive_recheck_preflight_result(preflight: dict) -> dict:
    """Derive either terminal verdict from recorded observations, never its label."""
    smoke = preflight.get("compile_smoke")
    errors = preflight_timing_errors(preflight)
    if preflight.get("schema") == RECHECK_PREFLIGHT_SCHEMA:
        timing = preflight.get("timing")
        if not errors and timing["elapsed_ns"] > timing["limit_ns"]:
            errors.append("preflight_time_limit_exceeded")
        child_timing = (smoke or {}).get("timing") if isinstance(smoke, dict) else None
        if child_timing and not timing_errors(child_timing, "compile_smoke", CHILD_SECONDS * 1_000_000_000):
            if child_timing["elapsed_ns"] > child_timing["limit_ns"]:
                errors.append("compile_smoke_time_limit_exceeded")
    if not isinstance(smoke, dict):
        # Historical failures before a child launched retain their captured exception.
        stderr = preflight.get("stderr_excerpt", "")
        match = re.match(r"^([A-Za-z][A-Za-z0-9_]*): .+", stderr) if isinstance(stderr, str) else None
        errors.append(f"preflight_failed:{match.group(1)}" if match else "preflight_raw_failure_missing")
        return {"status": "INVALID", "reason": ";".join(dict.fromkeys(errors))}
    errors.extend(compile_smoke_errors(smoke.get("launch_exit_code"),
                                     smoke.get("stdout_excerpt", ""), smoke.get("stderr_excerpt", "")))
    runtime = parse_runtime(smoke.get("stdout_excerpt", ""))
    if runtime != {"elixir": ELIXIR_VERSION, "otp": OTP_VERSION,
                   "architecture": "aarch64-unknown-linux-gnu"}:
        errors.append("compile_smoke_runtime_identity_invalid")
    owned, identity_error = validate_owned_identity(
        smoke.get("name", ""), smoke.get("id"), smoke.get("inspected_name"))
    if not owned:
        errors.append(identity_error or "container_identity_invalid")
    if smoke.get("cleanup") != "removed":
        errors.append("owned_container_cleanup_not_confirmed")
    if (smoke.get("cidfile_absent_before_launch") is not True or smoke.get("parse_error") or
            type(smoke.get("inspect_exit_code")) is not int or smoke.get("inspect_exit_code") != 0 or
            type(smoke.get("cleanup_exit_code")) is not int or smoke.get("cleanup_exit_code") != 0):
        errors.append("owned_container_evidence_invalid")
    if not valid_image_identity(preflight.get("image")):
        errors.append("cached_image_identity_invalid")
    return {"status": "INVALID" if errors else "VALID", "reason": (
        ";".join(dict.fromkeys(errors)) if errors else "compile_smoke_and_owned_identity_passed")}


def check_recheck_preflight(preflight: dict, path: Path) -> list[str]:
    errors = []
    if preflight.get("schema") not in RECHECK_PREFLIGHT_SCHEMAS or preflight.get("plan") != "247-23":
        errors.append("recheck_preflight_schema_invalid")
    errors.extend(preflight_timing_errors(preflight))
    errors.extend(validate_recheck_source(preflight, require_current=False))
    if preflight.get("historical_sha256") != HISTORICAL_HASHES:
        errors.append("recheck_historical_hashes_changed")
    result = preflight.get("result") or {}
    if result.get("status") not in {"VALID", "INVALID"}:
        errors.append("recheck_preflight_status_invalid")
    try:
        if result != derive_recheck_preflight_result(preflight):
            errors.append("recheck_preflight_result_not_derived_from_raw_evidence")
        smoke = preflight.get("compile_smoke")
        if isinstance(smoke, dict):
            smoke_result = compile_smoke_result(smoke.get("launch_exit_code"),
                                               smoke.get("stdout_excerpt", ""),
                                               smoke.get("stderr_excerpt", ""))
            if preflight.get("compile_smoke_result") != smoke_result:
                errors.append("recheck_compile_smoke_result_not_bound_to_raw_output")
            if preflight.get("runtime") != parse_runtime(smoke.get("stdout_excerpt", "")):
                errors.append("recheck_runtime_not_bound_to_raw_output")
        elif preflight.get("compile_smoke_result") is not None or preflight.get("runtime") is not None:
            errors.append("recheck_preflight_projection_without_child")
    except (AttributeError, TypeError, ValueError):
        errors.append("recheck_preflight_raw_evidence_malformed")
    reservation = preflight.get("reservation") or {}
    if path.resolve() != RECHECK_PREFLIGHT.resolve() or reservation.get("path") != RECHECK_RESERVATION.name or \
            not RECHECK_RESERVATION.is_file() or reservation.get("sha256") != sha256(RECHECK_RESERVATION.read_bytes()):
        errors.append("recheck_reservation_binding_invalid")
    else:
        try:
            reserved = json.loads(RECHECK_RESERVATION.read_text(encoding="utf-8"))
            if reserved.get("schema") != "threadline.exunit-boundary-recheck-reservation/1" or \
                    reserved.get("plan") != "247-23" or not reserved.get("series_id") or \
                    reserved.get("source_head") != (preflight.get("source") or {}).get("head") or \
                    reserved.get("producer_sha256") != (preflight.get("producer") or {}).get("sha256") or \
                    reserved.get("decision_sha256") != sha256(RECHECK_DECISION.read_bytes()) or \
                    reserved.get("series_budget_seconds") != TOTAL_SECONDS or \
                    type(reserved.get("series_started_monotonic_ns")) is not int or \
                    (preflight.get("schema") == RECHECK_PREFLIGHT_SCHEMA and
                     reserved.get("series_started_monotonic_ns") !=
                     (preflight.get("timing") or {}).get("started_monotonic_ns")):
                errors.append("recheck_reservation_source_mismatch")
        except (OSError, json.JSONDecodeError):
            errors.append("recheck_reservation_unreadable")
    return errors


def recheck_arm_errors(prior_arms: list[dict], arm: dict) -> list[str]:
    errors = classify_arm(arm)
    container = arm.get("container") or {}
    if container.get("cidfile_absent_before_launch") is not True:
        errors.append("cidfile_not_proven_absent_before_launch")
    owned, identity_error = validate_owned_identity(container.get("name", ""),
                                                    container.get("id"),
                                                    container.get("inspected_name"))
    if not owned:
        errors.append(identity_error or "container_identity_invalid")
    if container.get("parse_error"):
        errors.append("container_ownership_or_launch_invalid")
    if container.get("cleanup") != "removed":
        errors.append("owned_container_cleanup_unconfirmed")
    if container.get("launch_exit_code") != 0:
        errors.append("child_nonzero_exit")
    control_failure = control_error(prior_arms, arm)
    if control_failure:
        errors.append(control_failure)
    _status, derived_reason = derive_validation_status(prior_arms + [arm])
    errors.extend(error for error in derived_reason.split(";")
                  if error and error != "fixed_schedule_incomplete")
    return list(dict.fromkeys(errors))


def check_recheck_receipt(receipt: dict, path: Path | None = None) -> list[str]:
    errors = []
    if receipt.get("schema") != RECHECK_SCHEMA or receipt.get("plan") != "247-23":
        errors.append("recheck_schema_invalid")
    errors.extend(validate_recheck_source(receipt, require_current=False))
    if receipt.get("historical_sha256") != HISTORICAL_HASHES:
        errors.append("recheck_historical_hashes_changed")
    if receipt.get("budgets") != {"child_seconds": CHILD_SECONDS, "overall_seconds": TOTAL_SECONDS,
                                   "max_warmups": MAX_WARMUPS, "pairs": PAIR_SCHEDULE,
                                   "max_controls": 2}:
        errors.append("recheck_budget_or_schedule_changed")
    preflight = receipt.get("preflight") or {}
    preflight_path = PHASE_DIR / "247-LOCAL-CANARY-RECHECK-PREFLIGHT.json"
    preflight_receipt = None
    if preflight.get("path") != preflight_path.name or not preflight_path.is_file() or \
            preflight.get("sha256") != sha256(preflight_path.read_bytes()):
        errors.append("recheck_preflight_hash_mismatch")
    else:
        try:
            preflight_receipt = json.loads(preflight_path.read_text(encoding="utf-8"))
            errors.extend(check_recheck_preflight(preflight_receipt, preflight_path))
            for evidence_key in ("result", "runtime", "compile_smoke", "compile_smoke_result"):
                if preflight.get(evidence_key) != preflight_receipt.get(evidence_key):
                    errors.append(f"recheck_preflight_{evidence_key}_projection_mismatch")
            if preflight_receipt.get("result", {}).get("status") != "VALID":
                errors.append("recheck_preflight_not_valid")
        except (OSError, json.JSONDecodeError):
            errors.append("recheck_preflight_unreadable")
    arms = receipt.get("arms")
    if not isinstance(arms, list) or len(arms) > MAX_WARMUPS + 8:
        errors.append("recheck_arm_count_invalid")
        arms = arms if isinstance(arms, list) else []
    ids = [arm.get("id") for arm in arms if isinstance(arm, dict)]
    if len(ids) != len(set(ids)):
        errors.append("recheck_arm_id_duplicate")
    container_ids = []
    for arm in arms:
        if not isinstance(arm, dict):
            errors.append("recheck_arm_malformed")
            continue
        container = arm.get("container") or {}
        if container.get("cidfile_absent_before_launch") is not True:
            errors.append(f"{arm.get('id')}:cidfile_not_proven_absent_before_launch")
        owned, identity_error = validate_owned_identity(container.get("name", ""),
                                                        container.get("id"),
                                                        container.get("inspected_name"))
        if not owned:
            errors.append(f"{arm.get('id')}:{identity_error}")
        if container.get("id"):
            container_ids.append(container["id"])
        if container.get("cleanup") != "removed":
            errors.append(f"{arm.get('id')}:cleanup_unconfirmed")
        if container.get("retained_unverified") and not container.get("ownership_disclosure"):
            errors.append(f"{arm.get('id')}:retained_container_disclosure_missing")
        if not isinstance(arm.get("stderr_excerpt"), str) or not isinstance(arm.get("parse_error"), (str, type(None))):
            errors.append(f"{arm.get('id')}:raw_error_fields_malformed")
    early_stop = receipt.get("early_stop")
    if early_stop is not None:
        if not arms or not isinstance(early_stop, dict) or early_stop.get("after") != arms[-1].get("id"):
            errors.append("recheck_early_stop_not_bound_to_terminal_arm")
        else:
            expected_stop_errors = recheck_arm_errors(arms[:-1], arms[-1])
            if not expected_stop_errors or early_stop.get("reason") != ";".join(expected_stop_errors):
                errors.append("recheck_early_stop_reason_not_bound_to_raw_arm")
    if len(container_ids) != len(set(container_ids)):
        errors.append("recheck_container_id_reused")
    preflight_container_id = ((preflight_receipt or {}).get("compile_smoke") or {}).get("id")
    if preflight_container_id and preflight_container_id in container_ids:
        errors.append("recheck_preflight_container_id_reused")
    result = receipt.get("result") or {}
    if result.get("status") not in {"VALID_SEMANTIC", "VALID_NO_SIGNAL", "INVALID"}:
        errors.append("recheck_result_status_invalid")
    try:
        derived_status, derived_reason = derive_validation_status(arms)
        projected_status = "INVALID" if errors else derived_status
        if result.get("status") != projected_status:
            errors.append("recheck_false_status_projection")
        if result.get("status") == "INVALID" and not result.get("reason"):
            errors.append("recheck_invalid_without_reason")
        if result.get("reason") != derived_reason:
            errors.append("recheck_status_reason_not_derived_from_arms")
    except (KeyError, TypeError, ValueError, IndexError):
        errors.append("recheck_arm_status_unverifiable")
    if receipt.get("historical_ci_cause") != "UNPROVEN" or receipt.get("ci_02") != "INCOMPLETE" or \
            receipt.get("ci_03") != "MISS":
        errors.append("recheck_promotes_historical_or_ci_status")
    if path is not None and path.name != RECHECK_RECEIPT.name:
        errors.append("recheck_receipt_path_invalid")
    return errors


def render_recheck_report(receipt_path: Path, output: Path) -> None:
    receipt_path, output = receipt_path.resolve(), output.resolve()
    if output != RECHECK_REPORT.resolve() or receipt_path not in {
            RECHECK_RECEIPT.resolve(), RECHECK_PREFLIGHT.resolve()}:
        raise RuntimeError("recheck report must use its dedicated receipt/preflight and report paths")
    if output.exists() or output.name in {"247-LOCAL-CANARY.md", "247-LOCAL-CANARY-VALIDATION.md"}:
        raise RuntimeError("report output exists or is historical (write-once)")
    receipt = json.loads(receipt_path.read_text(encoding="utf-8"))
    is_preflight = receipt.get("schema") in RECHECK_PREFLIGHT_SCHEMAS
    if is_preflight:
        errors = check_recheck_preflight(receipt, receipt_path)
        if receipt.get("result", {}).get("status") != "INVALID":
            errors.append("valid_preflight_requires_final_recheck_receipt")
        projection = recheck_preflight_report_projection(receipt)
    else:
        errors = check_recheck_receipt(receipt, receipt_path)
        projection = recheck_report_projection(receipt)
    if errors:
        raise RuntimeError("receipt verification failed: " + ";".join(errors))
    projection = json.dumps(projection, indent=2, sort_keys=True)
    body = ("# Local canary recheck\n\n## Verdict and provenance\n\n"
            "<!-- receipt-projection:start -->\n" + projection +
            "\n<!-- receipt-projection:end -->\n\n## Limits\n\n"
            "CI-02 remains INCOMPLETE; CI-03 remains MISS; exact-runtime evidence is scoped to this receipt.\n")
    fd = os.open(output, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, "w", encoding="utf-8") as handle:
        handle.write(body)
        handle.flush()
        os.fsync(handle.fileno())


def run_owned_arm(root: Path, receipt: dict, arm_id: str, kind: str, mode: str,
                  control: str | None, case_bytes: bytes, deadline: float,
                  runner: bytes, formatter: bytes) -> dict:
    arm_dir = root / arm_id
    arm_dir.mkdir(mode=0o700)
    (arm_dir / "case.exs").write_bytes(case_bytes)
    (arm_dir / "runner.exs").write_bytes(runner)
    (arm_dir / "formatter.ex").write_bytes(formatter)
    name = RECHECK_NAME_PREFIX + uuid.uuid4().hex[:12]
    cidfile = arm_dir / "owned.cid"
    docker = run_owned_container(name, cidfile,
        ["--mount", f"type=bind,src={arm_dir},dst=/probe",
         "-e", "THREADLINE_PARTITION_TIMINGS_FILE=/probe/partition.tsv",
         "--entrypoint", "elixir", receipt["image"]["id"], "/probe/runner.exs",
         "/probe/case.exs", mode, control or "none"],
        min(CHILD_SECONDS, max(0.1, deadline - time.monotonic())))
    stdout, stderr = docker.get("stdout_excerpt", ""), docker.get("stderr_excerpt", "")
    arm = {"id": arm_id, "kind": kind, "mode": mode, "control": control,
           "exit_code": docker.get("launch_exit_code"), "timed_out": docker.get("parse_error") == "docker_timeout",
           "events": [], "formatter": None, "runtime": None,
           "stdout_excerpt": stdout, "stderr_excerpt": stderr,
           "raw_tsv_excerpt": "", "error_code": None, "parse_error": docker.get("parse_error"),
           "container": docker, "duration_ms": None}
    try:
        arm["events"] = parse_events(stdout)
        arm["runtime"] = parse_runtime(stdout)
        if docker.get("launch_exit_code") != 0:
            arm["error_code"] = "child_nonzero_exit"
        if docker.get("cleanup") != "removed":
            arm["error_code"] = "owned_container_cleanup_unconfirmed"
        if docker.get("id") is None or docker.get("parse_error"):
            arm["error_code"] = "owned_container_identity_invalid"
        tsv_path = arm_dir / "partition.tsv"
        if tsv_path.is_file():
            raw_tsv = tsv_path.read_text(encoding="utf-8")
            arm["raw_tsv_excerpt"] = bounded_output(raw_tsv)
            arm["formatter"] = parse_tsv(raw_tsv)
    except (OSError, UnicodeError, ValueError) as exc:
        arm["parse_error"] = f"{type(exc).__name__}: {exc}"
    return arm


def execute_recheck(preflight_path: Path, output: Path) -> None:
    if preflight_path.resolve() != RECHECK_PREFLIGHT.resolve() or output.resolve() != RECHECK_RECEIPT.resolve():
        raise RuntimeError("recheck run requires the dedicated preflight and receipt paths")
    if output.exists():
        raise RuntimeError("recheck receipt already exists (write-once; no retries)")
    preflight = json.loads(preflight_path.read_text(encoding="utf-8"))
    source_head = (preflight.get("source") or {}).get("head", "")
    if not recheck_decision_authorized(source_head):
        raise RuntimeError("the exact recheck series decision no longer authorizes this source candidate")
    preflight_errors = check_recheck_preflight(preflight, preflight_path)
    if preflight_errors or preflight.get("result", {}).get("status") != "VALID":
        raise RuntimeError("recheck preflight is not valid: " + ";".join(preflight_errors))
    source_errors = validate_recheck_source(preflight)
    if source_errors:
        raise RuntimeError("recheck source changed after preflight: " + ";".join(source_errors))
    reservation = json.loads(RECHECK_RESERVATION.read_text(encoding="utf-8"))
    series_started_ns = reservation.get("series_started_monotonic_ns")
    if not isinstance(series_started_ns, int) or reservation.get("series_budget_seconds") != TOTAL_SECONDS:
        raise RuntimeError("recheck series reservation lacks a valid original budget")
    head = preflight["source"]["head"]
    binding = recheck_source_binding(head)
    receipt = {"schema": RECHECK_SCHEMA, "plan": "247-23", "source": preflight["source"],
               "producer": preflight["producer"], "hashes": preflight["hashes"],
               "historical_sha256": HISTORICAL_HASHES, "image": preflight["image"],
               "runtime": {"elixir": ELIXIR_VERSION, "otp": OTP_VERSION},
               "preflight": {"path": preflight_path.name,
                             "sha256": sha256(preflight_path.read_bytes()),
                             "result": preflight["result"], "runtime": preflight.get("runtime"),
                             "compile_smoke": preflight.get("compile_smoke"),
                             "compile_smoke_result": preflight.get("compile_smoke_result")},
               "reservation": {"path": RECHECK_RESERVATION.name,
                               "sha256": sha256(RECHECK_RESERVATION.read_bytes())},
               "budgets": {"child_seconds": CHILD_SECONDS, "overall_seconds": TOTAL_SECONDS,
                           "max_warmups": MAX_WARMUPS, "pairs": PAIR_SCHEDULE,
                           "max_controls": 2},
               "arms": [], "attempted_count": 0,
               "result": {"status": "INVALID", "reason": "run_not_started"},
               "historical_ci_cause": "UNPROVEN", "ci_02": "INCOMPLETE", "ci_03": "MISS",
               "reservation_id": reservation.get("series_id"), "output": output.name}
    started = time.monotonic()
    series_elapsed_s = max(0, (time.monotonic_ns() - series_started_ns) / 1_000_000_000)
    deadline = started + max(0, TOTAL_SECONDS - series_elapsed_s)
    schedule = [("warmup", "async", None, make_case(True)),
                ("warmup", "sync", None, make_case(False))]
    schedule.extend(("pair", mode, None, make_case(mode == "async"))
                    for pair in PAIR_SCHEDULE for mode in pair)
    schedule.extend([("control", "sync", "pre_exunit", make_case(False)),
                     ("control", "sync", "setup_all", make_case(False, True))])
    with tempfile.TemporaryDirectory(prefix="threadline-24723-run-") as private:
        root = Path(private)
        for index, (kind, mode, control, case_bytes) in enumerate(schedule, start=1):
            if time.monotonic() >= deadline:
                break
            arm = run_owned_arm(root, receipt, f"attempt-{index:02d}", kind, mode, control,
                                case_bytes, deadline, binding["runner"], binding["formatter"])
            receipt["arms"].append(arm)
            receipt["attempted_count"] += 1
            arm_errors = recheck_arm_errors(receipt["arms"][:-1], arm)
            if arm_errors:
                receipt["early_stop"] = {"after": arm["id"],
                                         "reason": ";".join(dict.fromkeys(arm_errors))}
                break
            if time.monotonic() >= deadline:
                break
    status, reason = derive_validation_status(receipt["arms"])
    receipt["result"] = {"status": status, "reason": reason}
    receipt["collection"] = {"elapsed_ms": round((time.monotonic() - started) * 1000),
                             "ended_at_utc": utc_now()}
    verification_errors = check_recheck_receipt(receipt, output)
    if verification_errors:
        receipt["result"] = {"status": "INVALID",
                             "reason": ";".join(dict.fromkeys(verification_errors))}
    write_once(output, receipt)
    print(f"recheck: {status} ({reason})")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--run", action="store_true")
    parser.add_argument("--recheck-preflight", action="store_true")
    parser.add_argument("--recheck-run", action="store_true")
    parser.add_argument("--render-report", metavar="RECEIPT")
    parser.add_argument("--verify", metavar="RECEIPT")
    parser.add_argument("--preflight", nargs="?", const="__GENERATE__", metavar="PREFLIGHT")
    parser.add_argument("--output")
    parser.add_argument("--report")
    args = parser.parse_args()
    mode_count = sum((args.self_test, args.run, args.recheck_preflight, args.recheck_run,
                      args.render_report is not None, args.verify is not None,
                      args.preflight == "__GENERATE__"))
    if mode_count != 1:
        parser.error("choose exactly one mode: --self-test, --preflight, --run, or --verify")
    if args.self_test:
        self_test()
    elif args.preflight == "__GENERATE__":
        if not args.output:
            parser.error("--preflight requires --output")
        validation_preflight(Path(args.output).resolve())
    elif args.run:
        if not args.output or not args.preflight or args.preflight == "__GENERATE__":
            parser.error("--run requires --preflight <receipt> and --output")
        output = Path(args.output).resolve()
        try:
            execute_validation_run(Path(args.preflight).resolve(), output)
        except Exception as exc:
            print(f"validation run refused or failed: {type(exc).__name__}: {exc}", file=sys.stderr)
            raise SystemExit(1)
    elif args.recheck_preflight:
        if not args.output:
            parser.error("--recheck-preflight requires --output")
        try:
            recheck_preflight(Path(args.output).resolve())
        except Exception as exc:
            print(f"recheck preflight refused or failed: {type(exc).__name__}: {exc}", file=sys.stderr)
            raise SystemExit(1)
    elif args.recheck_run:
        if not args.output or not args.preflight or args.preflight == "__GENERATE__":
            parser.error("--recheck-run requires --preflight <receipt> and --output")
        try:
            execute_recheck(Path(args.preflight).resolve(), Path(args.output).resolve())
        except Exception as exc:
            print(f"recheck run refused or failed: {type(exc).__name__}: {exc}", file=sys.stderr)
            raise SystemExit(1)
    elif args.render_report:
        if not args.output:
            parser.error("--render-report requires --output")
        try:
            render_recheck_report(Path(args.render_report), Path(args.output))
        except Exception as exc:
            print(f"report render refused or failed: {type(exc).__name__}: {exc}", file=sys.stderr)
            raise SystemExit(1)
    elif args.preflight:
        parser.error("--preflight <receipt> is valid only together with --run")
    elif args.verify:
        verify(Path(args.verify), Path(args.report) if args.report else None)
    else:
        parser.error("choose exactly one mode")


if __name__ == "__main__":
    main()
