#!/usr/bin/env python3
"""Read-only verifier for the Phase 248 retained-candidate baseline."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
PHASE_DIR = ROOT / ".planning/phases/248-reconcile-the-base-and-safety-proof-ownership"
ISOLATION_PATH = PHASE_DIR / "248-ISOLATION.json"
BASELINE_PATH = PHASE_DIR / "248-CANDIDATE-BASELINE.md"
RESEARCH_PATH = ROOT / ".planning/research/2026-11-10-brand-admin/248-candidate-research.md"
FIRST_PATH = "examples/threadline_phoenix/e2e/support/operator-browser-evidence.ts"
BRAND_PATHS = ("brand/BRAND.md", "brand/brand.json", "brand/assets/README.md")


class VerificationError(Exception):
    pass


def git(*args: str, cwd: Path = ROOT, check: bool = True) -> str:
    result = subprocess.run(
        ["git", *args], cwd=cwd, text=True, capture_output=True, check=False
    )
    if check and result.returncode:
        raise VerificationError(
            f"git {' '.join(args)} failed ({result.returncode}): {result.stderr.strip()}"
        )
    return result.stdout.strip()


def git_succeeds(*args: str, cwd: Path = ROOT) -> bool:
    return subprocess.run(
        ["git", *args], cwd=cwd, text=True, capture_output=True, check=False
    ).returncode == 0


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def load_json(path: Path) -> dict:
    try:
        return json.loads(path.read_text())
    except (OSError, json.JSONDecodeError) as exc:
        raise VerificationError(f"cannot read {path.name}: {exc}") from exc


def worktree_for_branch(branch: str) -> Path:
    output = git("worktree", "list", "--porcelain")
    matches: list[Path] = []
    for block in output.split("\n\n"):
        fields = dict(
            line.split(" ", 1) for line in block.splitlines() if " " in line
        )
        if fields.get("branch") == f"refs/heads/{branch}" and fields.get("worktree"):
            matches.append(Path(fields["worktree"]).resolve())
    if len(matches) != 1:
        raise VerificationError(
            f"expected one registered worktree for {branch}; found {len(matches)}"
        )
    return matches[0]


def research_rows() -> list[tuple[str, str]]:
    try:
        lines = RESEARCH_PATH.read_text().splitlines()
    except OSError as exc:
        raise VerificationError(f"cannot read candidate research: {exc}") from exc
    in_table = False
    rows: list[tuple[str, str]] = []
    for line in lines:
        if line.startswith("| # | Repo-relative path | Verified candidate edit"):
            in_table = True
            continue
        if not in_table:
            continue
        if line.startswith("|---"):
            continue
        if not line.startswith("|"):
            break
        cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
        if len(cells) < 5 or not cells[0].isdigit():
            continue
        path = cells[1].strip("`")
        match = re.search(r"`([0-9a-f]{40})`", cells[2])
        if not match:
            raise VerificationError(f"candidate research row has no blob hash: {path}")
        rows.append((path, match.group(1)))
    if not rows:
        raise VerificationError("candidate research inventory table is missing")
    return rows


def baseline_trace() -> tuple[str, str]:
    text = BASELINE_PATH.read_text()
    match = re.search(
        r"^\| `([^`]+)` \| `([0-9a-f]{40})` \| DEFER", text, re.MULTILINE
    )
    if not match:
        raise VerificationError("baseline tracer row is missing or malformed")
    return match.group(1), match.group(2)


def baseline_brand_rows() -> dict[str, str]:
    text = BASELINE_PATH.read_text()
    rows = re.findall(
        r"^\| `(brand/[^`]+)` \| `([0-9a-f]{40})` \|$", text, re.MULTILINE
    )
    return dict(rows)


def check_receipt(isolation: dict, root: Path) -> list[str]:
    executor = isolation["executor"]
    adapter = isolation["adapter"]
    evidence = isolation["launch_evidence"]
    expected_repo_path = executor["repository_relative_path"]
    repo_root = Path(git("rev-parse", "--git-common-dir")).resolve().parent
    actual_relative = root.relative_to(repo_root).as_posix()
    if actual_relative != expected_repo_path:
        raise VerificationError("observed worktree path differs from adapter identity")
    if adapter["mode"] != "orchestrator-worktree" or adapter["base_ref"] != "head":
        raise VerificationError("recorded adapter mode/baseRef is not the approved isolated fork")
    if not adapter["created"] or not adapter["fork_equals_expected_base"]:
        raise VerificationError("adapter creation or initial fork proof is absent")
    if adapter["expected_base"] != adapter["observed_initial_head"]:
        raise VerificationError("recorded initial HEAD differs from the expected base")
    if not executor["descriptor_target_matches_observed_root"] or not executor["descriptor_cwd_matches_observed_cwd"]:
        raise VerificationError("recorded descriptor/root/cwd agreement is absent")
    for key in ("receipt_sha256", "manifest_sha256", "worker_record_sha256_at_observation"):
        if not re.fullmatch(r"[0-9a-f]{64}", evidence[key]):
            raise VerificationError(f"recorded launch evidence hash is malformed: {key}")
    if not executor.get("agent_id") or not executor.get("worker_pid"):
        raise VerificationError("adapter worker identity is incomplete")
    return [
        "launch receipt, manifest and worker record identities are captured by SHA-256",
        "observed git root/cwd and resolved descriptor target share the recorded worktree ID",
        "adapter worker identity and initial fork metadata are internally consistent",
    ]


def check_candidate(isolation: dict) -> list[str]:
    source = isolation["preserved_candidate"]
    candidate = worktree_for_branch(source["branch"])
    common_root = Path(git("rev-parse", "--git-common-dir")).resolve().parent
    if candidate.relative_to(common_root).as_posix() != source["repository_relative_path"]:
        raise VerificationError("preserved candidate worktree ID/path differs from recorded source")
    head = git("rev-parse", "HEAD", cwd=candidate)
    if head != source["head"]:
        raise VerificationError("preserved candidate HEAD changed")
    if git("rev-parse", "HEAD^{tree}", cwd=candidate) != source["head_tree"]:
        raise VerificationError("preserved candidate tree changed")
    rows = research_rows()
    paths = [path for path, _ in rows]
    if len(paths) != 31 or len(set(paths)) != 31 or paths != sorted(paths):
        raise VerificationError("research source inventory is not 31 unique sorted paths")
    current_dirty = git("diff", "--name-only", "HEAD", "--", "examples", "guides", "lib", "test", cwd=candidate).splitlines()
    if sorted(current_dirty) != paths:
        raise VerificationError("preserved dirty product/docs/test paths differ from inventory")
    for path, expected_blob in rows:
        actual_blob = git("hash-object", "--", path, cwd=candidate)
        if actual_blob != expected_blob:
            raise VerificationError(f"preserved blob mismatch: {path}")
    patch = subprocess.run(
        ["git", "diff", "--binary", "HEAD", "--", *paths],
        cwd=candidate,
        capture_output=True,
        check=True,
    ).stdout
    if sha256(patch) != source["retained_patch_sha256"]:
        raise VerificationError("preserved 31-path binary patch fingerprint changed")
    status = subprocess.run(
        ["git", "status", "--porcelain=v1"],
        cwd=candidate,
        capture_output=True,
        check=True,
    ).stdout
    if sha256(status) != source["complete_status_sha256"]:
        raise VerificationError("preserved complete Git status fingerprint changed")
    merge_base = git("merge-base", "HEAD", source["current_main_sha"], cwd=candidate)
    if merge_base != source["base_sha"]:
        raise VerificationError("preserved candidate base identity changed")
    return [
        "preserved candidate branch/HEAD/tree and ancestry match",
        "31 research paths equal the preserved dirty product/docs/test path set",
        "all 31 blob IDs and the binary patch fingerprint match",
        "complete preserved status fingerprint is unchanged",
    ]


def check_brands(rows: dict[str, str]) -> list[str]:
    if set(rows) != set(BRAND_PATHS):
        raise VerificationError("baseline must contain exactly the three approved brand sources")
    for path in BRAND_PATHS:
        actual = git("hash-object", "--", path)
        if actual != rows[path]:
            raise VerificationError(f"approved brand source blob differs: {path}")
    return ["all three approved brand-source blob IDs match the current checkout"]


def check_tracer() -> list[str]:
    isolation = load_json(ISOLATION_PATH)
    root = Path(git("rev-parse", "--show-toplevel")).resolve()
    if root != ROOT.resolve() or Path.cwd().resolve() != root:
        raise VerificationError("validator cwd or git root differs from its bound worktree")
    executor = isolation["executor"]
    adapter = isolation["adapter"]
    if git("branch", "--show-current") != executor["branch"]:
        raise VerificationError("executor branch differs from launch record")
    if git("rev-parse", adapter["expected_base"]) != adapter["expected_base"]:
        raise VerificationError("expected executor base is unavailable")
    if git("rev-parse", adapter["expected_base"] + "^{tree}") != adapter["observed_initial_tree"]:
        raise VerificationError("executor starting tree differs from launch record")
    if not git_succeeds("merge-base", "--is-ancestor", adapter["expected_base"], "HEAD"):
        raise VerificationError("current executor HEAD is not descended from expected base")
    if git("merge-base", adapter["current_main_sha"], adapter["expected_base"]) != adapter["current_main_sha"]:
        raise VerificationError("executor fork does not descend from observed current main")
    receipt_checks = check_receipt(isolation, root)
    candidate_checks = check_candidate(isolation)
    trace_path, trace_hash = baseline_trace()
    rows = research_rows()
    if trace_path != FIRST_PATH or (trace_path, trace_hash) != rows[0]:
        raise VerificationError("baseline tracer is not the first sorted candidate inventory row")
    if git("hash-object", "--", trace_path, cwd=worktree_for_branch(isolation["preserved_candidate"]["branch"])) != trace_hash:
        raise VerificationError("first retained edit no longer matches its recorded blob")
    brand_checks = check_brands(baseline_brand_rows())
    return [
        "executor fork equals expected base and is a descendant of current main",
        *receipt_checks,
        *candidate_checks,
        "first sorted retained edit traces to its dirty Git blob",
        *brand_checks,
    ]


def check_recorded_provenance(isolation: dict) -> list[str]:
    adapter = isolation["adapter"]
    executor = isolation["executor"]
    if adapter.get("mode") != "orchestrator-worktree" or adapter.get("base_ref") != "head":
        raise VerificationError("isolation record does not name the negotiated head-based worktree")
    if not adapter.get("created") or not adapter.get("fork_equals_expected_base"):
        raise VerificationError("isolation record lacks successful worktree creation/fork evidence")
    if adapter.get("expected_base") != adapter.get("observed_initial_head"):
        raise VerificationError("recorded initial executor HEAD differs from expected base")
    if git("rev-parse", adapter["expected_base"]) != adapter["expected_base"]:
        raise VerificationError("recorded executor base is unavailable in this repository")
    if git("rev-parse", adapter["expected_base"] + "^{tree}") != adapter["observed_initial_tree"]:
        raise VerificationError("recorded executor starting tree differs from expected base")
    if not git_succeeds("merge-base", "--is-ancestor", adapter["current_main_sha"], adapter["expected_base"]):
        raise VerificationError("recorded executor base does not descend from current main")
    if not executor.get("descriptor_target_matches_observed_root") or not executor.get("descriptor_cwd_matches_observed_cwd"):
        raise VerificationError("isolation record lacks descriptor/root/cwd agreement")
    return ["recorded isolation provenance and current-main ancestry match Git"]


def inventory_rows() -> list[dict[str, str | int]]:
    lines = BASELINE_PATH.read_text().splitlines()
    active = False
    rows: list[dict[str, str | int]] = []
    for line in lines:
        if line == "<!-- candidate-matrix:start -->":
            active = True
            continue
        if line == "<!-- candidate-matrix:end -->":
            break
        if not active or not line.startswith("|") or line.startswith("|---"):
            continue
        raw = line.strip()[1:-1]
        cells = [re.sub(r"\\\|", "|", cell.strip()) for cell in re.split(r"(?<!\\)\|", raw)]
        if not cells or not cells[0].isdigit():
            continue
        if len(cells) != 8:
            raise VerificationError(f"inventory row {cells[0]} has {len(cells)} columns, expected 8")
        path_match = re.fullmatch(r"`([^`]+)`", cells[1])
        blob_match = re.fullmatch(r"`([0-9a-f]{40})`", cells[3])
        if not path_match or not blob_match:
            raise VerificationError(f"inventory row {cells[0]} has malformed path or blob")
        rows.append({
            "number": int(cells[0]),
            "path": path_match.group(1),
            "edit": cells[2],
            "hash": blob_match.group(1),
            "status": cells[4],
            "disposition": cells[5],
            "implementation_owner": cells[6],
            "proof_owner": cells[7],
        })
    if not active or "<!-- candidate-matrix:end -->" not in lines:
        raise VerificationError("candidate inventory markers are missing")
    return rows


def inventory_errors(
    rows: list[dict[str, str | int]],
    expected_rows: list[tuple[str, str]],
    expected_dirty: set[str],
) -> list[str]:
    errors: list[str] = []
    paths = [str(row.get("path", "")) for row in rows]
    if len(rows) != 31:
        errors.append(f"expected exactly 31 rows, found {len(rows)}")
    if len(set(paths)) != len(paths):
        errors.append("duplicate path exists")
    if paths != sorted(paths):
        errors.append("rows are not sorted by repository-relative path")
    if set(paths) != expected_dirty:
        errors.append("matrix path set differs from preserved dirty product/docs/test set")
    if [(str(row.get("path", "")), str(row.get("hash", ""))) for row in rows] != expected_rows:
        errors.append("matrix path/hash ordering differs from candidate research")
    for index, row in enumerate(rows, start=1):
        if row.get("number") != index:
            errors.append(f"row numbering is not deterministic at position {index}")
        path = str(row.get("path", ""))
        if path.startswith("/") or ".." in Path(path).parts:
            errors.append(f"path is not repository-relative: {path}")
        disposition = str(row.get("disposition", ""))
        if not re.match(r"^\*\*(PORT|REPLACE|DEFER)\s+[—-]", disposition):
            errors.append(f"invalid or empty disposition at row {index}")
        if not disposition.strip() or len(disposition.split("**", 2)) < 3 or not disposition.split("**", 2)[2].strip():
            errors.append(f"disposition rationale is empty at row {index}")
        for field in ("implementation_owner", "proof_owner"):
            owner = str(row.get(field, "")).strip()
            if not owner or not re.search(r"Phases?\s+\d+", owner):
                errors.append(f"missing or invalid {field.replace('_', ' ')} at row {index}")
    return errors


def check_inventory() -> tuple[list[str], list[dict[str, str | int]], list[tuple[str, str]], set[str]]:
    isolation = load_json(ISOLATION_PATH)
    checks = check_recorded_provenance(isolation)
    source = isolation["preserved_candidate"]
    candidate = worktree_for_branch(source["branch"])
    common_root = Path(git("rev-parse", "--git-common-dir")).resolve().parent
    if candidate.relative_to(common_root).as_posix() != source["repository_relative_path"]:
        raise VerificationError("preserved candidate worktree ID/path differs from recorded source")
    source_rows = research_rows()
    expected_paths = [path for path, _ in source_rows]
    actual_dirty = set(
        git("diff", "--name-only", "HEAD", "--", "examples", "guides", "lib", "test", cwd=candidate).splitlines()
    )
    if actual_dirty != set(expected_paths):
        raise VerificationError("preserved product/docs/test dirty path set differs from source inventory")
    rows = inventory_rows()
    problems = inventory_errors(rows, source_rows, actual_dirty)
    if problems:
        raise VerificationError("; ".join(problems))
    if git("rev-parse", "HEAD", cwd=candidate) != source["head"]:
        raise VerificationError("preserved candidate HEAD changed")
    if git("rev-parse", "HEAD^{tree}", cwd=candidate) != source["head_tree"]:
        raise VerificationError("preserved candidate tree changed")
    for path, expected_blob in source_rows:
        actual_blob = git("hash-object", "--", path, cwd=candidate)
        if actual_blob != expected_blob:
            raise VerificationError(f"preserved blob mismatch: {path}")
    patch = subprocess.run(
        ["git", "diff", "--binary", "HEAD", "--", *expected_paths],
        cwd=candidate,
        capture_output=True,
        check=True,
    ).stdout
    if sha256(patch) != source["retained_patch_sha256"]:
        raise VerificationError("preserved 31-path binary patch fingerprint changed")
    status = subprocess.run(
        ["git", "status", "--porcelain=v1"],
        cwd=candidate,
        capture_output=True,
        check=True,
    ).stdout
    if sha256(status) != source["complete_status_sha256"]:
        raise VerificationError("preserved complete Git status fingerprint changed")
    if git("merge-base", "HEAD", source["current_main_sha"], cwd=candidate) != source["base_sha"]:
        raise VerificationError("preserved candidate base identity changed")
    brand_checks = check_brands(baseline_brand_rows())
    baseline = BASELINE_PATH.read_text()
    for required in (
        "operator-accessibility.spec.ts",
        "operator-motion.spec.ts",
        "~> 1.1.0",
        ":repo_contract",
        "focus assertions",
    ):
        if required not in baseline:
            raise VerificationError(f"required upstream replay safeguard is missing: {required}")
    for requirement in ("ADM-01", "ADM-02", "ADM-03", "ADM-04"):
        if f"| {requirement} |" not in baseline:
            raise VerificationError(f"proof ledger row missing for {requirement}")
    checks.extend([
        "matrix has exactly 31 unique, path-sorted rows with dispositions and two owners",
        "matrix path set equals all retained tracked product/docs/test paths",
        "all 31 blob identities and preserved patch/status fingerprints match",
        "four current-main overlaps and required replay safeguards are recorded",
        "proof ledger contains ADM-01 through ADM-04 rows (presence only; proof status reviewed separately)",
        *brand_checks,
    ])
    return checks, rows, source_rows, actual_dirty


def run_self_test(rows: list[dict[str, str | int]], source_rows: list[tuple[str, str]], dirty: set[str]) -> list[str]:
    cases: list[tuple[str, list[dict[str, str | int]]]] = []
    cases.append(("missing row", rows[:-1]))
    extra = [dict(row) for row in rows]
    extra.append({**dict(rows[-1]), "number": 32, "path": "z/extra.txt"})
    cases.append(("extra row", extra))
    duplicate = [dict(row) for row in rows]
    duplicate[-1]["path"] = duplicate[0]["path"]
    cases.append(("duplicate path", duplicate))
    reordered = [dict(row) for row in rows]
    reordered[0], reordered[1] = reordered[1], reordered[0]
    cases.append(("reordered rows", reordered))
    empty_disposition = [dict(row) for row in rows]
    empty_disposition[0]["disposition"] = ""
    cases.append(("empty disposition", empty_disposition))
    wrong_hash = [dict(row) for row in rows]
    wrong_hash[0]["hash"] = "0" * 40
    cases.append(("wrong blob hash", wrong_hash))
    results: list[str] = []
    for name, altered in cases:
        errors = inventory_errors(altered, source_rows, dirty)
        if not errors:
            raise VerificationError(f"self-test negative control unexpectedly passed: {name}")
        results.append(f"negative control rejected: {name}")
    if inventory_errors(rows, source_rows, dirty):
        raise VerificationError("self-test genuine inventory failed")
    results.append("genuine inventory passed self-test")
    return results


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    modes = parser.add_mutually_exclusive_group(required=True)
    modes.add_argument("--check-tracer", action="store_true")
    modes.add_argument("--check", action="store_true")
    modes.add_argument("--check-inventory", action="store_true")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    try:
        if args.check_tracer:
            checks = check_tracer()
        else:
            checks, rows, source_rows, dirty = check_inventory()
            if args.self_test:
                checks.extend(run_self_test(rows, source_rows, dirty))
            if args.check:
                checks.extend(check_tracer())
            else:
                checks.append("inventory-only mode does not assert the historical executor cwd")
    except (VerificationError, OSError, KeyError, ValueError, subprocess.CalledProcessError) as exc:
        print(f"FAIL: {exc}", file=sys.stderr)
        return 1
    for check in checks:
        print(f"PASS: {check}")
    mode = "tracer" if args.check_tracer else "inventory"
    print(f"PASS: {mode} verification ({len(checks)} checks)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
