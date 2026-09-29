#!/usr/bin/env python3
"""inert-share.py - share of merged PRs that touch only provably inert paths (BASE-01, re-measured for SEED-006).

Usage (from the repo root):
  python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/inert-share.py --window all
  python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/inert-share.py --window 30d
  python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/inert-share.py --window at-214
  python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/inert-share.py --window since-214
  python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/inert-share.py --window 30d-now
  python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/inert-share.py --last 20
  python3 .planning/phases/222-seed-006-change-aware-lanes-conditional/tools/inert-share.py --self-test

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

Windows (fixed, so output is deterministic; the measurement date is this phase's raw/prs/manifest.json
collection_date, 2026-09-29):
  all         every merged PR in index.json
  30d         PRs with mergedAt on or after 2026-08-27T00:00:00Z and on or before 2026-09-26T23:59:59Z
              (Phase 214's original 30d window, frozen; re-run here as a regression check on the
              fresh snapshot, not a live recomputation)
  at-214      PRs with mergedAt on or before 2026-09-26T17:21:09Z (Phase 214's last merged PR),
              i.e. the exact PR set Phase 214 measured
  since-214   PRs with mergedAt on or after 2026-09-26T17:21:10Z (one second after at-214's bound)
              and on or before 2026-09-29T23:59:59Z (this phase's collection_date) — informational
              only; n is below the D-02 gate's n>=10 floor and this window does not vote
  30d-now     PRs with mergedAt on or after 2026-08-30T00:00:00Z (collection_date minus 30 days)
              and on or before 2026-09-29T23:59:59Z (collection_date) — the D-02 gate's window

--last N mode: selects the last N merged PRs ordered by (mergedAt, number) ascending (ties on
identical mergedAt broken by ascending PR number), then reports on that selection. N must be a
positive integer, else exit 64.

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
    "at-214": (None, "2026-09-26T17:21:09Z"),
    "since-214": ("2026-09-26T17:21:10Z", "2026-09-29T23:59:59Z"),
    "30d-now": ("2026-08-30T00:00:00Z", "2026-09-29T23:59:59Z"),
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


def summarize_selected(selected, globs, header):
    lines = [header]
    if not selected:
        lines.append("n=0 — not measured")
        return lines
    inert = [p["number"] for p in selected if is_inert_pr(p["files"], globs)]
    lines.append(f"{len(inert)} of {len(selected)} merged PRs touch only inert paths")
    lines.append("inert PRs: " + (", ".join(f"#{n}" for n in inert) if inert else "none"))
    return lines


def summarize(prs, globs, window):
    selected = [p for p in prs if in_window(p, window)]
    lo, hi = WINDOWS[window]
    if selected:
        first = min(p["mergedAt"] for p in selected)[:10]
        last = max(p["mergedAt"] for p in selected)[:10]
        span = f"merged {first} to {last}"
    else:
        span = "no merged PRs"
    if lo is None and hi is None:
        bounds = "all merged PRs into main"
    elif lo is None:
        bounds = f"mergedAt on or before {hi[:10]}"
    elif hi is None:
        bounds = f"mergedAt on or after {lo[:10]}"
    else:
        # A bound with a non-midnight/non-end-of-day time component (e.g.
        # since-214's lo = "...T17:21:10Z") must print in full: truncating
        # to the date alone would read as an inclusive whole-day bound and
        # over-state the window by up to a day (WR-02).
        lo_str = lo if not lo.endswith("T00:00:00Z") else lo[:10]
        hi_str = hi if not hi.endswith("T23:59:59Z") else hi[:10]
        bounds = f"mergedAt {lo_str} to {hi_str}"
    header = f"window: {window} ({bounds}; {span})"
    return summarize_selected(selected, globs, header)


def select_last_n(prs, n):
    if n <= 0:
        return []
    ordered = sorted(prs, key=lambda p: (p["mergedAt"], p["number"]))
    return ordered[-n:]


def summarize_last(prs, globs, n):
    selected = select_last_n(prs, n)
    if selected:
        first = min(p["mergedAt"] for p in selected)[:10]
        last = max(p["mergedAt"] for p in selected)[:10]
        span = f"merged {first} to {last}"
    else:
        span = "no merged PRs"
    header = f"window: last {n} ({span})"
    return summarize_selected(selected, globs, header)


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

    # --last tie on identical mergedAt is ordered by PR number (222 addition).
    tie_prs = [
        {"number": 3, "mergedAt": "2026-01-01T00:00:00Z", "files": ["x"]},
        {"number": 1, "mergedAt": "2026-01-01T00:00:00Z", "files": ["x"]},
        {"number": 2, "mergedAt": "2026-01-01T00:00:00Z", "files": ["x"]},
    ]
    last_two = [p["number"] for p in select_last_n(tie_prs, 2)]
    got_tie = last_two == [2, 3]
    print(f"self-test --last tie on identical mergedAt orders by PR number: {last_two} (want [2, 3]) {'ok' if got_tie else 'FAIL'}")
    ok = ok and got_tie

    # at-214 and since-214 bounds are disjoint (222 addition).
    at214_hi = WINDOWS["at-214"][1]
    since214_lo = WINDOWS["since-214"][0]
    got_disjoint = at214_hi < since214_lo
    print(f"self-test at-214 and since-214 bounds are disjoint: {at214_hi} < {since214_lo} = {got_disjoint} (want True) {'ok' if got_disjoint else 'FAIL'}")
    ok = ok and got_disjoint

    # Same-second collision at the at-214/since-214 boundary (222 IN-01):
    # two PRs merged in the exact same second as the at-214 cutoff must both
    # land in at-214 and neither in since-214 — no split across the boundary.
    boundary_prs = [
        {"number": 101, "mergedAt": "2026-09-26T17:21:09Z", "files": ["x"]},
        {"number": 102, "mergedAt": "2026-09-26T17:21:09Z", "files": ["x"]},
    ]
    got_boundary = all(in_window(p, "at-214") and not in_window(p, "since-214") for p in boundary_prs)
    print(f"self-test same-second at-214 boundary PRs land only in at-214: {got_boundary} (want True) {'ok' if got_boundary else 'FAIL'}")
    ok = ok and got_boundary

    # One second later (the since-214 lower bound) must fall the other way.
    next_second_pr = {"number": 103, "mergedAt": "2026-09-26T17:21:10Z", "files": ["x"]}
    got_next_second = in_window(next_second_pr, "since-214") and not in_window(next_second_pr, "at-214")
    print(f"self-test one second after at-214 boundary lands only in since-214: {got_next_second} (want True) {'ok' if got_next_second else 'FAIL'}")
    ok = ok and got_next_second

    return 0 if ok else 1


def main(argv):
    if len(argv) == 2 and argv[1] == "--self-test":
        return self_test()
    if len(argv) == 3 and argv[1] == "--window" and argv[2] in WINDOWS:
        try:
            globs = load_allowlist(ALLOWLIST)
            prs = load_prs(PRS_DIR)
        except DataError as err:
            print(f"ERROR: {err}", file=sys.stderr)
            return 2
        print("\n".join(summarize(prs, globs, argv[2])))
        return 0
    if len(argv) == 3 and argv[1] == "--last":
        try:
            n = int(argv[2])
        except ValueError:
            n = None
        if n is None or n <= 0:
            print(__doc__, file=sys.stderr)
            return 64
        try:
            globs = load_allowlist(ALLOWLIST)
            prs = load_prs(PRS_DIR)
        except DataError as err:
            print(f"ERROR: {err}", file=sys.stderr)
            return 2
        print("\n".join(summarize_last(prs, globs, n)))
        return 0
    print(__doc__, file=sys.stderr)
    return 64


if __name__ == "__main__":
    sys.exit(main(sys.argv))
