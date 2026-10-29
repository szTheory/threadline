import json
import shutil
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

import exunit_boundary_probe as probe


class ProbeHarnessTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="probe-tests-")
        self.root = Path(self.temp.name)
        self.phase = self.root / "phase"
        self.phase.mkdir()
        for name in probe.HISTORICAL_HASHES:
            shutil.copyfile(probe.PHASE_DIR / name, self.phase / name)
        self.preflight_path = self.phase / "247-LOCAL-CANARY-VALIDATION-PREFLIGHT.json"
        self.output = self.phase / "247-LOCAL-CANARY-VALIDATION.json"
        self.decision_path = self.phase / "247-LOCAL-CANARY-VALIDATION-DECISION.md"
        self.decision_path.write_text("Decision: authorize-one-local-series\n", encoding="utf-8")
        self.patches = [
            mock.patch.object(probe, "PHASE_DIR", self.phase),
            mock.patch.object(probe, "VALIDATION_PREFLIGHT", self.preflight_path),
            mock.patch.object(probe, "DECISION", self.decision_path),
            mock.patch.object(probe, "RECHECK_PREFLIGHT", self.phase / "247-LOCAL-CANARY-RECHECK-PREFLIGHT.json"),
            mock.patch.object(probe, "RECHECK_RESERVATION", self.phase / "247-LOCAL-CANARY-RECHECK.reservation.json"),
            mock.patch.object(probe, "RECHECK_RECEIPT", self.phase / "247-LOCAL-CANARY-RECHECK.json"),
            mock.patch.object(probe, "RECHECK_REPORT", self.phase / "247-LOCAL-CANARY-RECHECK.md"),
            mock.patch.object(probe, "RECHECK_DECISION", self.phase / "247-LOCAL-CANARY-RECHECK-DECISION.md"),
        ]
        for patcher in self.patches:
            patcher.start()
        self.addCleanup(self.cleanup_patches)
        self.head = probe.run_cmd(["git", "rev-parse", "HEAD"])
        self.image = {"tag": probe.IMAGE_TAG, "id": "sha256:" + "a" * 64,
                      "repo_digests": ["hexpm/elixir@sha256:" + "b" * 64],
                      "os": "linux", "architecture": "arm64", "size_bytes": 1}
        self.real_committed_file = probe.committed_file

        def committed(commit, path):
            if path in {".planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_probe.py",
                        ".planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_case.exs",
                        "test/support/partition_monitor.ex"}:
                return {".planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_probe.py":
                            Path(probe.__file__).read_bytes(),
                        ".planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_case.exs":
                            probe.ELIXIR.read_bytes(),
                        "test/support/partition_monitor.ex": probe.FORMATTER.read_bytes()}[path]
            return self.real_committed_file(commit, path)

        self.committed_patch = mock.patch.object(probe, "committed_file", side_effect=committed)
        self.committed_patch.start()
        self.addCleanup(self.committed_patch.stop)
        self.coordinator_path = ".planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_probe.py"
        self.coordinator = Path(probe.__file__).read_bytes()
        self.runner = probe.ELIXIR.read_bytes()
        self.formatter = probe.FORMATTER.read_bytes()
        self.write_preflight()

    def cleanup_patches(self):
        for patcher in reversed(self.patches):
            patcher.stop()
        self.temp.cleanup()

    def write_preflight(self, **changes):
        preflight = {"schema": "threadline.exunit-boundary-preflight/1", "plan": "247-22",
            "collected_at_utc": "2026-10-27T00:00:00.000Z", "source": {"head": self.head},
            "image": self.image, "image_inspection": self.image,
            "runtime": {"elixir": probe.ELIXIR_VERSION, "otp": probe.OTP_VERSION,
                        "architecture": "aarch64-unknown-linux-gnu"},
            "producer": {"commit": self.head, "path": self.coordinator_path,
                         "sha256": probe.sha256(self.coordinator)},
            "hashes": {"runner_sha256": probe.sha256(self.runner),
                       "formatter_sha256": probe.sha256(self.formatter)},
            "historical_sha256": probe.HISTORICAL_HASHES,
            "result": {"status": "VALID", "reason": "synthetic mocked inspection"}}
        preflight.update(changes)
        probe.write_once(self.preflight_path, preflight)
        return preflight

    def synthetic_arm(self, arm_id, kind, mode, control, index, signal_pattern=None):
        base = 1000 + index * 10000
        async_mode = mode == "async"
        module_offset = 100 if async_mode else 2100
        if signal_pattern is not None:
            module_offset = 1900 if signal_pattern else 2100
        events = [{"name": "helper_start", "mono_ms": base},
                  {"name": "exunit_start", "mono_ms": base + 1},
                  {"name": "require_start", "mono_ms": base + 2},
                  {"name": "registration_" + mode, "mono_ms": base + 3},
                  {"name": "require_return", "mono_ms": base + 4},
                  {"name": "barrier_start", "mono_ms": base + 5},
                  {"name": "module_started", "mono_ms": base + module_offset},
                  {"name": "barrier_release", "mono_ms": base + 2005},
                  {"name": "suite_finished", "mono_ms": base + 2100}]
        events.sort(key=lambda event: event["mono_ms"])
        boot_ms, wall_ms = ((1000 if mode == "sync" else 100), 2100)
        if control == "pre_exunit":
            boot_ms = 3000
        elif control == "setup_all":
            boot_ms, wall_ms = 1100, 4100
        header = (f"# {probe.FORMAT} partition=1 lane=local boot_ms={boot_ms} wall_ms={wall_ms}")
        raw_tsv = f"{header}\nlocal.exs\t1\t1\n"
        stdout = "\n".join([f"THREADLINE_RUNTIME|{probe.ELIXIR_VERSION}|{probe.OTP_VERSION}|aarch64-unknown-linux-gnu"] +
                            [f"THREADLINE_EVENT|{event['name']}|{event['mono_ms']}" for event in events])
        started = 9_100_000_000 + index * 20_000_000
        arm = {"id": arm_id, "kind": kind, "mode": mode, "control": control,
               "exit_code": 0, "timed_out": False, "events": events,
               "runtime": {"elixir": probe.ELIXIR_VERSION, "otp": probe.OTP_VERSION,
                           "architecture": "aarch64-unknown-linux-gnu"},
               "stdout_excerpt": stdout, "stderr_excerpt": "", "raw_tsv_excerpt": raw_tsv,
               "formatter": probe.parse_tsv(raw_tsv), "error_code": None, "parse_error": None,
               "started_monotonic_ns": started, "child_started_monotonic_ns": started + 1_000_000,
               "child_ended_monotonic_ns": started + 11_000_000, "ended_monotonic_ns": started + 20_000_000,
               "child_duration_ms": 10, "duration_ms": 20, "cleanup_duration_ms": 10}
        return arm

    def run_with_mocked_children(self, child_factory):
        reservation = self.output.with_name("247-LOCAL-CANARY-VALIDATION.reservation.json")
        monotonic_values = mock.patch.object(probe.time, "monotonic_ns",
                                             side_effect=[9_000_000_000, 20_000_000_000])
        utc_values = mock.patch.object(probe, "utc_now",
                                       side_effect=["2026-10-27T00:00:00.000Z", "2026-10-27T00:00:11.000Z"])
        with monotonic_values, utc_values, mock.patch.object(probe, "docker_image", return_value=self.image), \
                mock.patch.object(probe, "run_child", side_effect=child_factory) as run_child:
            probe.execute_validation_run(self.preflight_path, self.output)
        return run_child, reservation

    def test_cli_dispatches_documented_preflight_syntax_without_docker(self):
        with mock.patch.object(probe.sys, "argv", ["probe.py", "--preflight", "--output", str(self.preflight_path)]), \
                mock.patch.object(probe, "validation_preflight") as preflight, \
                mock.patch.object(probe, "docker_image") as inspect_image:
            probe.main()
        preflight.assert_called_once_with(self.preflight_path.resolve())
        inspect_image.assert_not_called()

    def test_cli_dispatches_run_with_preflight_path(self):
        with mock.patch.object(probe.sys, "argv", ["probe.py", "--run", "--preflight", str(self.preflight_path),
                                                       "--output", str(self.output)]), \
                mock.patch.object(probe, "execute_validation_run") as run:
            probe.main()
        run.assert_called_once_with(self.preflight_path.resolve(), self.output.resolve())

    def test_valid_mocked_run_passes_committed_runner_and_formatter_bytes(self):
        def child(*args):
            _root, _receipt, arm_id, kind, mode, control, _case, _deadline, runner, formatter = args
            self.assertEqual(runner, self.runner)
            self.assertEqual(formatter, self.formatter)
            return self.synthetic_arm(arm_id, kind, mode, control, len(calls))

        calls = []

        def record(*args):
            calls.append(args)
            return child(*args)

        run_child, reservation = self.run_with_mocked_children(record)
        self.assertEqual(run_child.call_count, 10)
        self.assertTrue(reservation.is_file())
        receipt = json.loads(self.output.read_text(encoding="utf-8"))
        self.assertEqual(receipt["result"]["status"], "VALID_SEMANTIC")
        self.assertEqual(probe.check_validation_receipt(receipt, self.output), [])

    def test_dirty_runner_or_formatter_preflight_refuses_before_child_launch(self):
        for name, target in (("runner", probe.ELIXIR), ("formatter", probe.FORMATTER)):
            with self.subTest(name=name), tempfile.TemporaryDirectory(prefix="dirty-source-") as temp:
                dirty = Path(temp) / target.name
                dirty.write_bytes(target.read_bytes() + b"\n# altered after preflight\n")
                old_preflight, old_output = self.preflight_path, self.output
                self.preflight_path = self.phase / f"{name}-preflight.json"
                self.write_preflight()
                self.output = self.phase / f"{name}-validation.json"
                self.output = self.phase / "247-LOCAL-CANARY-VALIDATION.json"
                # Use the canonical output once per fresh phase fixture; source mismatch must fail before reservation.
                with mock.patch.object(probe, "ELIXIR" if name == "runner" else "FORMATTER", dirty), \
                        mock.patch.object(probe, "docker_image") as inspect_image, \
                        mock.patch.object(probe, "run_child") as run_child:
                    with self.assertRaises(RuntimeError):
                        probe.execute_validation_run(self.preflight_path, self.output)
                inspect_image.assert_not_called()
                run_child.assert_not_called()
                self.preflight_path, self.output = old_preflight, old_output

    def test_pair_inconsistency_stops_before_next_pair_or_control(self):
        def child(*args):
            _root, _receipt, arm_id, kind, mode, control, _case, _deadline, _runner, _formatter = args
            if kind == "pair":
                pair_index = (len([call for call in calls if call[3] == "pair"]) - 1) // 2
                pattern = True if pair_index == 1 and mode == "sync" else None
            else:
                pattern = None
            return self.synthetic_arm(arm_id, kind, mode, control, len(calls), pattern)

        calls = []

        def record(*args):
            calls.append(args)
            return child(*args)

        self.run_with_mocked_children(record)
        self.assertEqual(len(calls), 6, repr([(arm["kind"], arm["mode"],
            probe.event_map(arm["events"])["module_started"] -
            probe.event_map(arm["events"])["barrier_release"])
            for arm in json.loads(self.output.read_text(encoding="utf-8"))["arms"]]))
        receipt = json.loads(self.output.read_text(encoding="utf-8"))
        self.assertEqual(receipt["result"]["status"], "INVALID")
        self.assertIn("pair_boundary_signal_inconsistent", receipt["result"]["reason"])
        self.assertEqual(receipt["early_stop"]["after"], receipt["arms"][-1]["id"])

    def test_healthy_truncated_receipt_is_not_terminal_invalid_evidence(self):
        self.test_valid_mocked_run_passes_committed_runner_and_formatter_bytes()
        receipt = json.loads(self.output.read_text(encoding="utf-8"))
        receipt["arms"] = receipt["arms"][:1]
        receipt["attempted_count"] = 1
        receipt["result"] = {"status": "INVALID", "reason": "fixed_schedule_incomplete"}
        errors = probe.check_validation_receipt(receipt, self.output)
        self.assertIn("incomplete_schedule_has_no_terminal_raw_failure", errors)

    def test_arbitrary_run_failure_cannot_justify_zero_observations(self):
        self.test_valid_mocked_run_passes_committed_runner_and_formatter_bytes()
        receipt = json.loads(self.output.read_text(encoding="utf-8"))
        receipt.update({"arms": [], "attempted_count": 0,
                        "run_failure": {"type": "FakeFailure", "message": "forged failure"},
                        "result": {"status": "INVALID", "reason": "run_failure:FakeFailure"}})
        self.assertIn("run_failure_has_no_verifiable_raw_failure",
                      probe.check_validation_receipt(receipt, self.output))

    def test_receipt_rejects_preflight_from_different_producer_commit(self):
        self.test_valid_mocked_run_passes_committed_runner_and_formatter_bytes()
        receipt = json.loads(self.output.read_text(encoding="utf-8"))
        preflight = json.loads(self.preflight_path.read_text(encoding="utf-8"))
        previous = probe.run_cmd(["git", "rev-parse", "HEAD^"])
        preflight["source"]["head"] = previous
        preflight["producer"]["commit"] = previous
        self.preflight_path.write_text(json.dumps(preflight), encoding="utf-8")
        receipt["preflight"]["sha256"] = probe.sha256(self.preflight_path.read_bytes())
        reservation = self.output.with_name(receipt["reservation"]["path"])
        reserved = json.loads(reservation.read_text(encoding="utf-8"))
        reserved["preflight_sha256"] = receipt["preflight"]["sha256"]
        reservation.write_text(json.dumps(reserved), encoding="utf-8")
        receipt["reservation"]["sha256"] = probe.sha256(reservation.read_bytes())
        # The preflight is independently valid; only its cross-receipt binding differs.
        self.assertEqual(probe.validate_preflight(preflight, self.preflight_path), [])
        self.assertIn("validation_preflight_source_differs_from_receipt",
                      probe.check_validation_receipt(receipt, self.output))

    def test_forged_valid_preflight_is_rejected_for_each_binding_family(self):
        valid = json.loads(self.preflight_path.read_text(encoding="utf-8"))
        mutations = [
            lambda p: p["producer"].update({"sha256": "0" * 64}),
            lambda p: p["hashes"].update({"runner_sha256": "0" * 64}),
            lambda p: p["runtime"].update({"otp": "wrong"}),
            lambda p: p["image"].update({"tag": "other/image:latest"}),
            lambda p: p["image"].update({"id": "sha256:bad"}),
            lambda p: p["image"].update({"repo_digests": []}),
        ]
        for mutate in mutations:
            changed = json.loads(json.dumps(valid))
            mutate(changed)
            self.assertTrue(probe.validate_preflight(changed, self.preflight_path))

    def test_collection_and_child_cap_mutations_are_rejected(self):
        self.test_valid_mocked_run_passes_committed_runner_and_formatter_bytes()
        receipt = json.loads(self.output.read_text(encoding="utf-8"))
        for mutate in (
            lambda value: value["collection"].update({"ended_at_utc": "not-a-time"}),
            lambda value: value["collection"].update({"ended_monotonic_ns": value["collection"]["started_monotonic_ns"] - 1}),
            lambda value: value.update({"elapsed_ms": 151_000}),
            lambda value: value["arms"][0].update({"child_duration_ms": 16_000}),
            lambda value: value["arms"][0].update({"duration_ms": 16_001}),
        ):
            changed = json.loads(json.dumps(receipt))
            mutate(changed)
            self.assertTrue(probe.check_validation_receipt(changed, self.output))

    def test_reservation_and_terminal_receipt_survive_child_exception_and_block_retry(self):
        def fail_child(*_args):
            raise RuntimeError("synthetic child launch failure")

        run_child, reservation = self.run_with_mocked_children(fail_child)
        self.assertEqual(run_child.call_count, 1)
        self.assertTrue(reservation.is_file())
        self.assertTrue(self.output.is_file())
        receipt = json.loads(self.output.read_text(encoding="utf-8"))
        self.assertEqual(receipt["result"]["status"], "INVALID")
        self.assertEqual(receipt["run_failure"]["type"], "RuntimeError")
        with mock.patch.object(probe, "run_child") as retry_child:
            with self.assertRaises(RuntimeError):
                probe.execute_validation_run(self.preflight_path, self.output)
        retry_child.assert_not_called()

    def test_timeout_cleanup_waits_and_container_removal_are_bounded(self):
        class FakeProcess:
            pid = 1234
            returncode = -9

            def communicate(self, timeout=None):
                raise probe.subprocess.TimeoutExpired("docker", timeout, output=b"stdout", stderr=b"stderr")

        with tempfile.TemporaryDirectory(prefix="timeout-cleanup-") as temp, \
                mock.patch.object(probe.subprocess, "Popen", return_value=FakeProcess()), \
                mock.patch.object(probe.os, "killpg"), \
                mock.patch.object(probe.subprocess, "run", side_effect=probe.subprocess.TimeoutExpired("docker rm", 0.1)):
            started = probe.time.monotonic()
            arm = probe.run_child(Path(temp), {"image": {"id": "sha256:" + "a" * 64}},
                "timeout-arm", "pair", "async", None, probe.make_case(True),
                probe.time.monotonic() + 10, b"runner", b"formatter")
            self.assertLess(probe.time.monotonic() - started, 1)
            self.assertTrue(arm["timed_out"])
            self.assertEqual(arm["cleanup_error"], "owned_container_remove_timeout")
            self.assertIn("stderr", arm["stderr_excerpt"])
            self.assertLessEqual(arm["cleanup_duration_ms"], probe.CHILD_CLEANUP_MS)


class ParseEventsTests(unittest.TestCase):
    def test_preserves_event_receipt_order_when_occurrence_clocks_arrive_out_of_order(self):
        parsed = probe.parse_events(
            "THREADLINE_EVENT|require_return|2\n"
            "THREADLINE_EVENT|registration_async|1\n"
        )
        self.assertEqual([event["name"] for event in parsed],
                         ["require_return", "registration_async"])


class RecheckContractTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="recheck-controls-")
        phase = Path(self.temp.name)
        self.addCleanup(self.temp.cleanup)
        for name, value in (
            ("PHASE_DIR", phase),
            ("RECHECK_PREFLIGHT", phase / "247-LOCAL-CANARY-RECHECK-PREFLIGHT.json"),
            ("RECHECK_RESERVATION", phase / "247-LOCAL-CANARY-RECHECK.reservation.json"),
            ("RECHECK_RECEIPT", phase / "247-LOCAL-CANARY-RECHECK.json"),
            ("RECHECK_REPORT", phase / "247-LOCAL-CANARY-RECHECK.md"),
            ("RECHECK_DECISION", phase / "247-LOCAL-CANARY-RECHECK-DECISION.md"),
        ):
            patcher = mock.patch.object(probe, name, value)
            patcher.start()
            self.addCleanup(patcher.stop)

    def saved_preflight(self):
        original = Path(__file__).resolve().parents[1]
        for target in (probe.RECHECK_PREFLIGHT, probe.RECHECK_RESERVATION, probe.RECHECK_DECISION):
            shutil.copyfile(original / target.name, target)
        return json.loads(probe.RECHECK_PREFLIGHT.read_text(encoding="utf-8"))

    def test_invalid_preflight_rejects_a_forged_failure_reason(self):
        receipt = self.saved_preflight()
        with mock.patch.object(probe, "validate_recheck_source", return_value=[]):
            self.assertEqual(probe.check_recheck_preflight(receipt, probe.RECHECK_PREFLIGHT), [])
            receipt["result"]["reason"] = "forged-invalid-reason"
            self.assertIn("recheck_preflight_result_not_derived_from_raw_evidence",
                          probe.check_recheck_preflight(receipt, probe.RECHECK_PREFLIGHT))

    def test_invalid_preflight_rejects_fabricated_compile_and_runtime_projections(self):
        original = self.saved_preflight()
        mutations = (
            ("compile_smoke_result", {"status": "COMPILE_OK", "reason": "invented", "events": []},
             "recheck_compile_smoke_result_not_bound_to_raw_output"),
            ("runtime", {"elixir": "invented"}, "recheck_runtime_not_bound_to_raw_output"),
        )
        with mock.patch.object(probe, "validate_recheck_source", return_value=[]):
            for field, value, expected in mutations:
                with self.subTest(field=field):
                    receipt = json.loads(json.dumps(original))
                    receipt[field] = value
                    self.assertIn(expected, probe.check_recheck_preflight(receipt, probe.RECHECK_PREFLIGHT))

    def test_historical_preflight_verifies_against_its_committed_source_without_rewriting_it(self):
        receipt = self.saved_preflight()
        original = Path(__file__).resolve().parents[1]
        shutil.copyfile(original / probe.RECHECK_REPORT.name, probe.RECHECK_REPORT)
        before = probe.RECHECK_PREFLIGHT.read_bytes()
        probe.verify(probe.RECHECK_PREFLIGHT, probe.RECHECK_REPORT)
        self.assertEqual(probe.RECHECK_PREFLIGHT.read_bytes(), before)
        self.assertNotIn("timing", receipt)

    def test_preflight_schema_version_is_bound_to_its_historical_producer(self):
        receipt = self.saved_preflight()
        receipt["schema"] = probe.RECHECK_PREFLIGHT_SCHEMA
        self.assertIn("recheck_preflight_schema_not_bound_to_producer",
                      probe.validate_recheck_source(receipt, require_current=False))

    def test_compile_smoke_requires_exact_marker_and_zero_exit_without_events(self):
        self.assertEqual(probe.compile_smoke_result(0, "THREADLINE_COMPILE_SMOKE|ok\n", ""),
                         {"status": "COMPILE_OK", "reason": "marker_and_exit_passed", "events": []})
        self.assertIn("compile_smoke_marker_missing",
                      probe.compile_smoke_errors(0, "", ""))
        errors = probe.compile_smoke_errors(1, "", "** (CompileError) runner.exs: syntax error\n")
        self.assertIn("compile_smoke_child_failed", errors)
        self.assertTrue(probe.compile_smoke_errors(0, "THREADLINE_COMPILE_SMOKE|ok\nTHREADLINE_EVENT|module_started|1\n", ""))

    def test_recheck_preflight_cli_dispatch_is_pure_until_explicit_invocation(self):
        output = probe.RECHECK_PREFLIGHT
        with mock.patch.object(probe.sys, "argv", ["probe.py", "--recheck-preflight", "--output", str(output)]), \
                mock.patch.object(probe, "recheck_preflight") as preflight, \
                mock.patch.object(probe, "docker_image") as inspect_image:
            probe.main()
        preflight.assert_called_once_with(output.resolve())
        inspect_image.assert_not_called()

    def mocked_preflight(self, image_elapsed_ns=0):
        clock = [1_000_000_000]
        head = probe.run_cmd(["git", "rev-parse", "HEAD"])
        probe.RECHECK_DECISION.write_text(self.approved_decision(head), encoding="utf-8")
        runner, formatter, producer = b"runner fixture", b"formatter fixture", b"producer fixture"
        binding = {"producer": {"commit": head, "path": probe.RECHECK_PRODUCER_PATH,
                                "sha256": probe.sha256(producer)},
                   "hashes": {"runner_sha256": probe.sha256(runner),
                              "formatter_sha256": probe.sha256(formatter)},
                   "runner": runner, "formatter": formatter}
        image = {"tag": probe.IMAGE_TAG, "id": "sha256:" + "a" * 64,
                 "repo_digests": ["hexpm/elixir@sha256:" + "b" * 64],
                 "os": "linux", "architecture": "arm64", "size_bytes": 1}
        cid = "c" * 64
        smoke_stdout = (f"THREADLINE_RUNTIME|{probe.ELIXIR_VERSION}|{probe.OTP_VERSION}|"
                        "aarch64-unknown-linux-gnu\nTHREADLINE_COMPILE_SMOKE|ok\n")
        launch_record = {"name": "", "id": cid, "inspected_name": "",
                         "launch_exit_code": 0, "inspect_exit_code": 0,
                         "cleanup_exit_code": 0, "cleanup": "removed",
                         "stdout_excerpt": smoke_stdout, "stderr_excerpt": "",
                         "parse_error": None, "retained_unverified": False,
                         "ownership_disclosure": None, "cidfile_absent_before_launch": True}

        def fake_launch(*args, **_kwargs):
            self.assertTrue(probe.RECHECK_RESERVATION.is_file())
            self.assertFalse(probe.RECHECK_PREFLIGHT.exists())
            started = clock[0]
            clock[0] += 1_000_000
            return {**launch_record, "name": args[0], "inspected_name": "/" + args[0],
                    "timing": {"started_monotonic_ns": started, "ended_monotonic_ns": clock[0],
                               "elapsed_ns": clock[0] - started, "limit_ns": int(args[3] * 1_000_000_000)}}

        def fake_image(**_kwargs):
            clock[0] += image_elapsed_ns
            return image

        with mock.patch.object(probe, "recheck_source_binding", return_value=binding), \
                mock.patch.object(probe.time, "monotonic_ns", side_effect=lambda: clock[0]), \
                mock.patch.object(probe, "docker_image", side_effect=fake_image), \
                mock.patch.object(probe, "run_owned_container", side_effect=fake_launch) as launch, \
                mock.patch.object(probe, "validate_recheck_source", return_value=[]):
            probe.recheck_preflight(probe.RECHECK_PREFLIGHT)
            preflight = json.loads(probe.RECHECK_PREFLIGHT.read_text(encoding="utf-8"))
            self.assertEqual(probe.check_recheck_preflight(preflight, probe.RECHECK_PREFLIGHT), [])
        self.assertEqual(launch.call_count, 0 if image_elapsed_ns >= 45_000_000_000 else 1)
        return preflight

    def test_mocked_preflight_reserves_before_child_and_is_write_once(self):
        self.assertEqual(self.mocked_preflight()["result"]["status"], "VALID")
        with self.assertRaises(RuntimeError):
            probe.recheck_preflight(probe.RECHECK_PREFLIGHT)

    def test_new_preflight_records_verifiable_elapsed_time(self):
        receipt = self.mocked_preflight()
        timing = receipt["timing"]
        self.assertEqual(timing["elapsed_ns"], timing["ended_monotonic_ns"] - timing["started_monotonic_ns"])
        self.assertLessEqual(timing["elapsed_ns"], timing["limit_ns"])
        self.assertEqual(timing["limit_ns"], 45_000_000_000)
        changed = json.loads(json.dumps(receipt))
        changed["timing"]["elapsed_ns"] += 1
        with mock.patch.object(probe, "validate_recheck_source", return_value=[]):
            self.assertIn("preflight_timing_inconsistent",
                          probe.check_recheck_preflight(changed, probe.RECHECK_PREFLIGHT))

    def test_preflight_verifier_rejects_forged_child_elapsed_time(self):
        receipt = self.mocked_preflight()
        receipt["compile_smoke"]["timing"]["elapsed_ns"] += 1
        with mock.patch.object(probe, "validate_recheck_source", return_value=[]):
            self.assertIn("compile_smoke_timing_inconsistent",
                          probe.check_recheck_preflight(receipt, probe.RECHECK_PREFLIGHT))

    def test_preflight_cannot_claim_valid_when_owned_launch_evidence_failed(self):
        original = self.mocked_preflight()
        for field, value in (("parse_error", "docker_timeout"),
                             ("cidfile_absent_before_launch", False),
                             ("inspect_exit_code", 1), ("cleanup_exit_code", 1)):
            with self.subTest(field=field), mock.patch.object(probe, "validate_recheck_source", return_value=[]):
                receipt = json.loads(json.dumps(original))
                receipt["compile_smoke"][field] = value
                self.assertIn("recheck_preflight_result_not_derived_from_raw_evidence",
                              probe.check_recheck_preflight(receipt, probe.RECHECK_PREFLIGHT))

    def test_image_inspection_uses_the_same_preflight_deadline_and_stops_before_child(self):
        receipt = self.mocked_preflight(image_elapsed_ns=46_000_000_000)
        self.assertEqual(receipt["result"]["status"], "INVALID")
        self.assertIn("preflight_time_limit_exceeded", receipt["result"]["reason"])
        self.assertIsNone(receipt["compile_smoke"])

    def test_preflight_clock_is_bound_to_the_consumed_reservation(self):
        receipt = self.mocked_preflight()
        for timing in (receipt["timing"], receipt["compile_smoke"]["timing"]):
            timing["started_monotonic_ns"] += 100
            timing["ended_monotonic_ns"] += 100
        with mock.patch.object(probe, "validate_recheck_source", return_value=[]):
            self.assertIn("recheck_reservation_source_mismatch",
                          probe.check_recheck_preflight(receipt, probe.RECHECK_PREFLIGHT))

    @staticmethod
    def approved_decision(head):
        return (f"Decision: authorize-one-recheck-series\n"
                f"Source-Head: {head}\n"
                f"Schedule: warmup=async,sync;pair=async/sync,sync/async,async/sync;control=pre_exunit,setup_all\n"
                f"Limits: child={probe.CHILD_SECONDS}s,total={probe.TOTAL_SECONDS}s;warmups={probe.MAX_WARMUPS};"
                "controls=2;series=1\n")

    def test_unapproved_decision_variants_never_reserve_or_launch(self):
        head = probe.run_cmd(["git", "rev-parse", "HEAD"])
        approved = self.approved_decision(head)
        invalid_documents = (
            approved + "Stop: true\n",
            approved.replace("Decision: authorize-one-recheck-series",
                              "Decision: do not authorize-one-recheck-series"),
            approved.replace(f"Source-Head: {head}", f"Source-Head: {head}0"),
            approved + "Decision: authorize-one-recheck-series\n",
            approved.replace("Schedule:", "Note: authorize-one-recheck-series\nSchedule:"),
            "Decision: authorize-one-recheck-series\n",
        )
        for index, decision in enumerate(invalid_documents):
            with self.subTest(index=index):
                probe.RECHECK_DECISION.write_text(decision, encoding="utf-8")
                with mock.patch.object(probe, "recheck_source_binding") as source, \
                        mock.patch.object(probe, "docker_image") as image:
                    with self.assertRaises(RuntimeError):
                        probe.recheck_preflight(probe.RECHECK_PREFLIGHT)
                source.assert_not_called()
                image.assert_not_called()
                self.assertFalse(probe.RECHECK_RESERVATION.exists())

    def test_current_coordinator_bytes_are_bound_and_dirty_bytes_block_before_reservation(self):
        head = probe.run_cmd(["git", "rev-parse", "HEAD"])
        binding = probe.recheck_source_binding(head)
        self.assertEqual(binding["coordinator"], probe.committed_file(head, probe.RECHECK_COORDINATOR_PATH))
        receipt = {"source": {"head": head}, "producer": binding["producer"],
                   "hashes": binding["hashes"]}
        with tempfile.TemporaryDirectory(prefix="dirty-coordinator-") as temp:
            dirty_file = Path(temp) / "exunit_boundary_probe.py"
            dirty_file.write_bytes(binding["coordinator"] + b"\n# uncommitted coordinator mutation\n")
            with mock.patch.object(probe, "__file__", str(dirty_file)):
                errors = probe.validate_recheck_source(receipt)
        self.assertIn("recheck_coordinator_worktree_differs_from_committed_bytes", errors)

        probe.RECHECK_DECISION.write_text(self.approved_decision(head), encoding="utf-8")
        with tempfile.TemporaryDirectory(prefix="dirty-coordinator-preflight-") as temp:
            dirty_file = Path(temp) / "exunit_boundary_probe.py"
            dirty_file.write_bytes(binding["coordinator"] + b"\n# uncommitted coordinator mutation\n")
            with mock.patch.object(probe, "__file__", str(dirty_file)), \
                    mock.patch.object(probe, "docker_image") as image:
                with self.assertRaises(RuntimeError):
                    probe.recheck_preflight(probe.RECHECK_PREFLIGHT)
        image.assert_not_called()
        self.assertFalse(probe.RECHECK_RESERVATION.exists())

    def mocked_failed_series(self):
        head = probe.run_cmd(["git", "rev-parse", "HEAD"])
        probe.RECHECK_DECISION.write_text(self.approved_decision(head), encoding="utf-8")
        preflight = {"schema": probe.RECHECK_PREFLIGHT_SCHEMA, "plan": "247-23",
                     "source": {"head": head}, "producer": {}, "hashes": {},
                     "image": {"id": "sha256:" + "a" * 64},
                     "runtime": {"elixir": probe.ELIXIR_VERSION, "otp": probe.OTP_VERSION},
                     "compile_smoke": {"id": "b" * 64}, "compile_smoke_result": {},
                     "result": {"status": "VALID", "reason": "synthetic preflight"}}
        probe.write_once(probe.RECHECK_PREFLIGHT, preflight)
        probe.write_once(probe.RECHECK_RESERVATION, {"series_id": "series-1",
                           "series_started_monotonic_ns": probe.time.monotonic_ns(),
                           "series_budget_seconds": probe.TOTAL_SECONDS})
        arm = ProbeHarnessTests.synthetic_arm(self, "attempt-01", "warmup", "async", None, 0)
        arm["events"] = []
        arm["stdout_excerpt"] = f"THREADLINE_RUNTIME|{probe.ELIXIR_VERSION}|{probe.OTP_VERSION}|aarch64-unknown-linux-gnu"
        arm["formatter"] = None
        arm["raw_tsv_excerpt"] = ""
        name, cid = probe.RECHECK_NAME_PREFIX + "a" * 12, "c" * 64
        arm["container"] = {"name": name, "id": cid, "inspected_name": "/" + name,
                            "cleanup": "removed", "launch_exit_code": 0,
                            "cidfile_absent_before_launch": True, "parse_error": None,
                            "stderr_excerpt": "", "retained_unverified": False}
        arm["stderr_excerpt"] = ""
        with mock.patch.object(probe, "check_recheck_preflight", return_value=[]), \
                mock.patch.object(probe, "validate_recheck_source", return_value=[]), \
                mock.patch.object(probe, "recheck_source_binding", return_value={"runner": b"runner",
                                                                                  "formatter": b"formatter"}), \
                mock.patch.object(probe, "run_owned_arm", return_value=arm) as child, \
                mock.patch.object(probe, "check_recheck_receipt", return_value=[]):
            probe.execute_recheck(probe.RECHECK_PREFLIGHT, probe.RECHECK_RECEIPT)
        self.assertEqual(child.call_count, 1)
        receipt = json.loads(probe.RECHECK_RECEIPT.read_text(encoding="utf-8"))
        self.assertEqual(receipt["attempted_count"], 1)
        self.assertEqual(receipt["result"]["status"], "INVALID")
        self.assertIn("required_event_missing", receipt["early_stop"]["reason"])
        return receipt

    def test_semantically_invalid_first_arm_stops_recheck_without_second_launch(self):
        self.mocked_failed_series()

    def test_invalid_series_reason_is_derived_from_its_observed_arm(self):
        receipt = self.mocked_failed_series()
        with mock.patch.object(probe, "check_recheck_preflight", return_value=[]), \
                mock.patch.object(probe, "validate_recheck_source", return_value=[]):
            self.assertEqual(probe.check_recheck_receipt(receipt, probe.RECHECK_RECEIPT), [])
            receipt["result"]["reason"] = "invented cause"
            self.assertIn("recheck_status_reason_not_derived_from_arms",
                          probe.check_recheck_receipt(receipt, probe.RECHECK_RECEIPT))

    def test_invalid_preflight_has_verifiable_write_once_no_arm_report(self):
        preflight = {"schema": probe.RECHECK_PREFLIGHT_SCHEMA, "plan": "247-23",
                     "source": {"head": "candidate"}, "producer": {"sha256": "1" * 64},
                     "hashes": {}, "historical_sha256": probe.HISTORICAL_HASHES,
                     "image": None, "runtime": None, "compile_smoke": None,
                     "result": {"status": "INVALID", "reason": "preflight_failed:ImageInspection"},
                     "stderr_excerpt": "synthetic image inspect stderr",
                     "reservation": {"path": probe.RECHECK_RESERVATION.name, "sha256": "2" * 64}}
        probe.write_once(probe.RECHECK_PREFLIGHT, preflight)
        with mock.patch.object(probe, "check_recheck_preflight", return_value=[]):
            probe.render_recheck_report(probe.RECHECK_PREFLIGHT, probe.RECHECK_REPORT)
            probe.verify(probe.RECHECK_PREFLIGHT, probe.RECHECK_REPORT)
            with self.assertRaises(RuntimeError):
                probe.render_recheck_report(probe.RECHECK_PREFLIGHT, probe.RECHECK_REPORT)
        rendered = probe.RECHECK_REPORT.read_text(encoding="utf-8")
        projection_text = rendered.split("<!-- receipt-projection:start -->", 1)[1].split(
            "<!-- receipt-projection:end -->", 1)[0].strip()
        projection = json.loads(projection_text)
        self.assertEqual(projection["result"], preflight["result"])
        self.assertEqual(projection["arms"], [])
        self.assertEqual(projection["attempted_count"], 0)
        self.assertEqual(projection["stderr_excerpt"], preflight["stderr_excerpt"])

    def test_collision_does_not_inspect_or_remove_preexisting_same_name_container(self):
        with tempfile.TemporaryDirectory(prefix="collision-control-") as temp:
            cidfile = Path(temp) / "owned.cid"
            name = probe.RECHECK_NAME_PREFIX + "c" * 12
            preexisting = {"name": name, "alive": True}
            with mock.patch.object(probe, "docker_result", return_value=probe.subprocess.CompletedProcess(
                    ["docker", "run"], 125, "", "Conflict. name already in use")) as docker:
                result = probe.run_owned_container(name, cidfile, ["sha256:" + "a" * 64], 2)
            self.assertEqual(docker.call_count, 1)
            self.assertNotIn("rm", docker.call_args.args[0])
            self.assertTrue(preexisting["alive"])
            self.assertEqual(result["launch_exit_code"], 125)
            self.assertEqual(result["parse_error"], "cid_missing")
            self.assertIn("Conflict", result["stderr_excerpt"])

    def test_unverified_cid_controls_never_call_name_or_unverified_id_removal(self):
        cid = "d" * 64
        for case in ("missing", "malformed", "mismatch"):
            with self.subTest(case=case), tempfile.TemporaryDirectory(prefix="cid-control-") as temp:
                cidfile = Path(temp) / "owned.cid"
                name = probe.RECHECK_NAME_PREFIX + "e" * 12

                def docker(argv, _timeout):
                    if argv[1] == "run":
                        if case == "malformed":
                            cidfile.write_text("not-a-cid\n", encoding="ascii")
                        elif case == "mismatch":
                            cidfile.write_text(cid + "\n", encoding="ascii")
                        return probe.subprocess.CompletedProcess(argv, 125 if case == "missing" else 0,
                                                                 "", "synthetic stderr")
                    if argv[1] == "inspect":
                        return probe.subprocess.CompletedProcess(argv, 0, "/other-container\n", "")
                    self.fail("unverified identity must never reach docker rm")

                with mock.patch.object(probe, "docker_result", side_effect=docker) as call:
                    result = probe.run_owned_container(name, cidfile, ["image"], 2)
                self.assertTrue(result["retained_unverified"])
                self.assertTrue(result["ownership_disclosure"])
                self.assertIn("synthetic stderr", result["stderr_excerpt"])
                self.assertTrue(result["cidfile_absent_before_launch"])
                self.assertFalse(any(args[0][1:3] == ["rm", "-f"] for args in call.call_args_list))

    def test_matching_inspected_cid_is_the_only_cleanup_argument_and_no_auto_rm(self):
        cid = "f" * 64
        with tempfile.TemporaryDirectory(prefix="owned-control-") as temp:
            cidfile = Path(temp) / "owned.cid"
            name = probe.RECHECK_NAME_PREFIX + "0" * 12

            def docker(argv, _timeout):
                if argv[1] == "run":
                    self.assertIn("--cidfile", argv)
                    self.assertIn("--name", argv)
                    self.assertNotIn("--rm", argv)
                    cidfile.write_text(cid + "\n", encoding="ascii")
                    return probe.subprocess.CompletedProcess(argv, 0, "child output", "")
                if argv[1] == "inspect":
                    self.assertEqual(argv[-1], cid)
                    return probe.subprocess.CompletedProcess(argv, 0, f"/{name}\n", "")
                if argv[1] == "rm":
                    return probe.subprocess.CompletedProcess(argv, 0, "", "")
                self.fail(f"unexpected docker operation: {argv}")

            with mock.patch.object(probe, "docker_result", side_effect=docker) as call:
                result = probe.run_owned_container(name, cidfile, ["image"], 2)
            self.assertEqual(result["id"], cid)
            self.assertEqual(result["cleanup"], "removed")
            remove_calls = [item.args[0] for item in call.call_args_list
                            if item.args[0][1] == "rm"]
            self.assertEqual(remove_calls, [["docker", "rm", "-f", cid]])
            timing = result["timing"]
            self.assertEqual(timing["elapsed_ns"], timing["ended_monotonic_ns"] - timing["started_monotonic_ns"])
            self.assertEqual(timing["limit_ns"], 2_000_000_000)
            self.assertTrue(all(0 < item.args[1] <= 2 for item in call.call_args_list))

    def test_inspection_failure_does_not_erase_the_child_stderr(self):
        with tempfile.TemporaryDirectory(prefix="inspect-failure-") as temp:
            cidfile = Path(temp) / "owned.cid"

            def docker(argv, _timeout):
                if argv[1] == "run":
                    cidfile.write_text("a" * 64 + "\n", encoding="ascii")
                    return probe.subprocess.CompletedProcess(argv, 0, "compile output", "compiler warning")
                raise OSError("inspection failed")

            with mock.patch.object(probe, "docker_result", side_effect=docker):
                result = probe.run_owned_container(probe.RECHECK_NAME_PREFIX + "0" * 12,
                                                   cidfile, ["image"], 2)
            self.assertEqual(result["stderr_excerpt"], "compiler warning")
            self.assertIn("inspection failed", result["operation_error"])
            self.assertTrue(result["retained_unverified"])

    def test_owned_child_cannot_extend_its_parent_absolute_deadline(self):
        clock = [10_000_000_000]
        deadline = clock[0] + 1_000_000_000
        name, cid = probe.RECHECK_NAME_PREFIX + "1" * 12, "a" * 64
        with tempfile.TemporaryDirectory(prefix="absolute-deadline-") as temp:
            cidfile = Path(temp) / "owned.cid"

            def docker(argv, timeout):
                self.assertLessEqual(timeout, (deadline - clock[0]) / 1_000_000_000)
                clock[0] += 100_000_000
                if argv[1] == "run":
                    cidfile.write_text(cid + "\n", encoding="ascii")
                return probe.subprocess.CompletedProcess(argv, 0, "/" + name if argv[1] == "inspect" else "", "")

            with mock.patch.object(probe.time, "monotonic_ns", side_effect=lambda: clock[0]), \
                    mock.patch.object(probe, "docker_result", side_effect=docker):
                result = probe.run_owned_container(name, cidfile, ["image"], 15, deadline_ns=deadline)
            self.assertEqual(result["cleanup"], "removed")
            self.assertEqual(result["timing"]["limit_ns"], 1_000_000_000)
            self.assertLessEqual(result["timing"]["ended_monotonic_ns"], deadline)

    def test_recheck_projection_renderer_is_exact_and_write_once(self):
        receipt = {"schema": probe.RECHECK_SCHEMA, "plan": "247-23",
                   "source": {"head": "abc"}, "producer": {"sha256": "1" * 64},
                   "hashes": {"runner_sha256": "2" * 64},
                   "reservation": {"path": probe.RECHECK_RESERVATION.name},
                   "attempted_count": 1,
                   "preflight": {"sha256": "3" * 64,
                                 "compile_smoke": {"exit_code": 1, "stdout_excerpt": "",
                                                      "stderr_excerpt": "** (CompileError) saved fixture\n"},
                                 "compile_smoke_result": probe.compile_smoke_result(
                                     1, "", "** (CompileError) saved fixture\n")},
                   "arms": [{"container": {"name": "owned", "id": "a" * 64,
                                              "inspected_name": "/owned", "cleanup": "removed"}}],
                   "result": {"status": "INVALID", "reason": "synthetic raw failure"},
                   "historical_ci_cause": "UNPROVEN", "ci_02": "INCOMPLETE", "ci_03": "MISS"}
        receipt_path = probe.RECHECK_RECEIPT
        report_path = probe.RECHECK_REPORT
        probe.write_once(receipt_path, receipt)
        with mock.patch.object(probe, "check_recheck_receipt", return_value=[]):
            probe.render_recheck_report(receipt_path, report_path)
            probe.verify(receipt_path, report_path)
            with self.assertRaises(RuntimeError):
                probe.render_recheck_report(receipt_path, report_path)
        rendered = report_path.read_text(encoding="utf-8")
        projection = rendered.split("<!-- receipt-projection:start -->", 1)[1].split(
            "<!-- receipt-projection:end -->", 1)[0].strip()
        self.assertEqual(projection, json.dumps(probe.recheck_report_projection(receipt),
                                                indent=2, sort_keys=True))
        self.assertEqual(probe.recheck_report_projection(receipt)["preflight"]["compile_smoke"][
            "stderr_excerpt"], "** (CompileError) saved fixture\n")
        self.assertIn("## Limits", rendered)
        self.assertEqual((probe.RECHECK_RECEIPT.name, probe.RECHECK_REPORT.name),
                         ("247-LOCAL-CANARY-RECHECK.json", "247-LOCAL-CANARY-RECHECK.md"))

    def test_receipt_rejects_reused_container_id_and_fabricated_semantic_status(self):
        preflight = {"schema": probe.RECHECK_PREFLIGHT_SCHEMA,
                     "result": {"status": "VALID", "reason": "synthetic preflight"},
                     "compile_smoke": {"id": "9" * 64}}
        probe.write_once(probe.RECHECK_PREFLIGHT, preflight)
        cid = "9" * 64
        name = probe.RECHECK_NAME_PREFIX + "1" * 12
        arms = []
        for index in range(2):
            arm = ProbeHarnessTests.synthetic_arm(self, f"attempt-{index}", "pair", "async", None, index)
            arm["container"] = {"name": name, "id": cid, "inspected_name": "/" + name,
                                "cleanup": "removed", "cidfile_absent_before_launch": True,
                                "stderr_excerpt": "", "parse_error": None}
            arms.append(arm)
        receipt = {"schema": probe.RECHECK_SCHEMA, "plan": "247-23",
                   "source": {"head": "test-head"}, "producer": {"commit": "test-head", "path": probe.RECHECK_PRODUCER_PATH,
                                                                         "sha256": "a" * 64},
                   "hashes": {}, "historical_sha256": probe.HISTORICAL_HASHES,
                   "preflight": {"path": probe.RECHECK_PREFLIGHT.name,
                                 "sha256": probe.sha256(probe.RECHECK_PREFLIGHT.read_bytes())},
                   "arms": arms, "attempted_count": 2,
                   "result": {"status": "INVALID", "reason": "synthetic truncated schedule"},
                   "historical_ci_cause": "UNPROVEN", "ci_02": "INCOMPLETE", "ci_03": "MISS"}
        with mock.patch.object(probe, "validate_recheck_source", return_value=[]), \
                mock.patch.object(probe, "check_recheck_preflight", return_value=[]):
            errors = probe.check_recheck_receipt(receipt, probe.RECHECK_RECEIPT)
            self.assertIn("recheck_container_id_reused", errors)
            self.assertIn("recheck_preflight_container_id_reused", errors)
            receipt["arms"] = [dict(arms[0], container={**arms[0]["container"], "id": "8" * 64}),
                               dict(arms[1], container={**arms[1]["container"], "id": "7" * 64})]
            receipt["result"] = {"status": "VALID_SEMANTIC", "reason": "forged"}
            errors = probe.check_recheck_receipt(receipt, probe.RECHECK_RECEIPT)
            self.assertIn("recheck_false_status_projection", errors)


if __name__ == "__main__":
    unittest.main()
