#!/usr/bin/env python3
"""inert-share.py - share of merged PRs that touch only provably inert paths (BASE-01).

Usage (from the repo root):
  python3 .planning/phases/214-baseline-measurement/tools/inert-share.py --window all
  python3 .planning/phases/214-baseline-measurement/tools/inert-share.py --window 30d
  python3 .planning/phases/214-baseline-measurement/tools/inert-share.py --self-test

Inputs (committed, read-only):
  raw/prs/index.json      merged PRs into main, from
                          gh pr list --repo szTheory/threadline --state merged --base main --limit 500
                            --json number,title,mergedAt,headRefName,changedFiles
  raw/prs/<n>.files.txt   every file of PR <n>, from
                          gh api --paginate repos/szTheory/threadline/pulls/<n>/files?per_page=100 --jq '.[].filename'
  tools/inert-allowlist.txt  one fnmatch glob per line followed by " # proof: <command>"

Fail-closed classification: a PR is inert only if it has at least one file and EVERY file matches an
admitted allowlist entry. Any unmatched file makes the PR non-inert. An allowlist line without a
" # proof: " command is an error (exit 2), never silently admitted. A PR whose file list is missing
or whose line count differs from changedFiles is an error (exit 2).

Windows (fixed, so output is deterministic; the measurement date is 2026-09-26):
  all   every merged PR in index.json
  30d   PRs with mergedAt on or after 2026-08-27T00:00:00Z and on or before 2026-09-26T23:59:59Z

Output: the window line, "<k> of <n> merged PRs touch only inert paths" (or "n=0 — not measured"),
and the sorted inert PR numbers. Standard library only.
"""
import fnmatch
import json
import os
import sys

TOOLS_DIR = os.path.dirname(os.path.abspath(__file__))
PHASE_DIR = os.path.dirname(TOOLS_DIR)
PRS_DIR = os.path.join(PHASE_DIR, "raw", "prs")
ALLOWLIST = os.path.join(TOOLS_DIR, "inert-allowlist.txt")
PROOF_SEP = " # proof: "
WINDOWS = {
    "all": (None, None),
    "30d": ("2026-08-27T00:00:00Z", "2026-09-26T23:59:59Z"),
}


class DataError(Exception):
    pass


def load_allowlist(path):
    globs = []
    with open(path, encoding="utf-8") as fh:
        for lineno, raw in enumerate(fh, 1):
            line = raw.rstrip("\n")
            if not line.strip() or line.lstrip().startswith("#"):
                continue
            if PROOF_SEP not in line:
                raise DataError(f"{path}:{lineno}: allowlist entry has no proof command: {line}")
            glob, proof = line.split(PROOF_SEP, 1)
            if not glob.strip() or not proof.strip():
                raise DataError(f"{path}:{lineno}: empty glob or proof: {line}")
            globs.append(glob.strip())
    return globs


def is_inert_path(path, globs):
    return any(fnmatch.fnmatchcase(path, g) for g in globs)


def is_inert_pr(files, globs):
    return bool(files) and all(is_inert_path(f, globs) for f in files)


def load_prs(prs_dir):
    with open(os.path.join(prs_dir, "index.json"), encoding="utf-8") as fh:
        index = json.load(fh)
    prs = []
    for entry in index:
        number = entry["number"]
        path = os.path.join(prs_dir, f"{number}.files.txt")
        if not os.path.exists(path):
            raise DataError(f"missing file list for PR {number}: {path}")
        with open(path, encoding="utf-8") as fh:
            files = [ln.rstrip("\n") for ln in fh if ln.strip()]
        if len(files) != entry["changedFiles"]:
            raise DataError(f"PR {number}: {len(files)} files listed, changedFiles={entry['changedFiles']}")
        prs.append({"number": number, "mergedAt": entry["mergedAt"], "files": files})
    return sorted(prs, key=lambda p: p["number"])


def in_window(pr, window):
    lo, hi = WINDOWS[window]
    merged = pr["mergedAt"]
    return (lo is None or merged >= lo) and (hi is None or merged <= hi)


def summarize(prs, globs, window):
    selected = [p for p in prs if in_window(p, window)]
    lines = []
    lo, hi = WINDOWS[window]
    if selected:
        first = min(p["mergedAt"] for p in selected)[:10]
        last = max(p["mergedAt"] for p in selected)[:10]
        span = f"merged {first} to {last}"
    else:
        span = "no merged PRs"
    bounds = "all merged PRs into main" if lo is None else f"mergedAt {lo[:10]} to {hi[:10]}"
    lines.append(f"window: {window} ({bounds}; {span})")
    if not selected:
        lines.append("n=0 — not measured")
        return lines
    inert = [p["number"] for p in selected if is_inert_pr(p["files"], globs)]
    lines.append(f"{len(inert)} of {len(selected)} merged PRs touch only inert paths")
    lines.append("inert PRs: " + (", ".join(f"#{n}" for n in inert) if inert else "none"))
    return lines


def self_test():
    globs = [".planning/STATE.md", ".planning/seeds/*"]
    cases = [
        ("allowlisted + unknown file is non-inert",
         is_inert_pr([".planning/STATE.md", "lib/threadline.ex"], globs), False),
        ("only allowlisted files is inert",
         is_inert_pr([".planning/STATE.md", ".planning/seeds/SEED-006.md"], globs), True),
        ("empty file list is non-inert", is_inert_pr([], globs), False),
        ("unmatched sibling of an entry is non-inert",
         is_inert_pr([".planning/STATE.md.bak"], globs), False),
    ]
    ok = True
    for name, got, want in cases:
        status = "ok" if got == want else "FAIL"
        print(f"self-test {name}: {got} (want {want}) {status}")
        ok = ok and got == want
    empty = summarize([], globs, "all")
    got_empty = empty[-1] == "n=0 — not measured"
    print(f"self-test empty PR set yields n=0 line: {got_empty} (want True) {'ok' if got_empty else 'FAIL'}")
    ok = ok and got_empty
    zero_in_window = summarize([{"number": 1, "mergedAt": "2026-05-28T15:13:42Z", "files": ["x"]}], globs, "30d")
    got_zw = zero_in_window[-1] == "n=0 — not measured"
    print(f"self-test window with no PRs yields n=0 line: {got_zw} (want True) {'ok' if got_zw else 'FAIL'}")
    ok = ok and got_zw
    try:
        import tempfile
        with tempfile.NamedTemporaryFile("w", suffix=".txt", delete=False) as tmp:
            tmp.write(".planning/STATE.md\n")
            tmp_path = tmp.name
        load_allowlist(tmp_path)
        got_proofless = False
    except DataError:
        got_proofless = True
    finally:
        os.unlink(tmp_path)
    print(f"self-test entry without proof is rejected: {got_proofless} (want True) {'ok' if got_proofless else 'FAIL'}")
    ok = ok and got_proofless
    return 0 if ok else 1


def main(argv):
    if len(argv) == 2 and argv[1] == "--self-test":
        return self_test()
    if len(argv) != 3 or argv[1] != "--window" or argv[2] not in WINDOWS:
        print(__doc__, file=sys.stderr)
        return 64
    try:
        globs = load_allowlist(ALLOWLIST)
        prs = load_prs(PRS_DIR)
    except DataError as err:
        print(f"ERROR: {err}", file=sys.stderr)
        return 2
    print("\n".join(summarize(prs, globs, argv[2])))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
