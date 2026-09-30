#!/usr/bin/env python3
"""Order-only job mover for .github/workflows/ci.yml (phase 221, D-08).

A chunk is one job header `^  <id>:$`, plus the contiguous column-2 comment
lines (`  #`) and blank lines directly above it, plus its body up to the next
chunk. Comments above a job travel with that job; comments inside a body stay
inside it.

Subcommands:
  apply <ci.yml>            rewrite the file with its chunks in TARGET order,
                            joined by one blank line; header line 2 (the job id
                            roster) is rewritten in the same order
  prove <before> <after>    exit 0 only when (a) the sorted line lists differ
                            in exactly one removed and one added line, both
                            starting `# verify-` (the roster), (b) the
                            {id: chunk text} dicts are equal, and (c) the
                            after file's job ids read in TARGET order

YAML order has no runtime effect; this move is for readability only (221 D-05).
The proof also needs a parsed-map `==` check, which the plan runs through
yaml_elixir (the parser the contracts use).
"""

import re
import sys
from collections import Counter

# D-06: the measured time-to-red order (`time-to-red.py order`), then ci-required.
TARGET = [
    "verify-release-shape",
    "verify-repo-hygiene",
    "verify-format",
    "verify-deps-audit",
    "verify-compile-no-optional",
    "verify-hex-evaluator",
    "verify-pgbouncer-topology",
    "verify-credo",
    "verify-bump-rehearsal",
    "verify-dialyzer",
    "verify-test",
    "verify-capture",
    "verify-example-browser",
    "ci-required",
]

HEADER = re.compile(r"^  ([A-Za-z_][A-Za-z0-9_-]*):\s*$")
LEAD = re.compile(r"^(  #.*|\s*)$")
JOBS_SPLIT = "\njobs:\n"


def split_jobs(text):
    if not text.endswith("\n"):
        raise SystemExit("file must end with a newline")
    if text.count(JOBS_SPLIT) != 1:
        raise SystemExit("expected exactly one top-level `jobs:` line")
    pre, body = text.split(JOBS_SPLIT, 1)
    lines = body.split("\n")[:-1]
    # IN-07 (221 review): every chunk runs to the next job or the end of file,
    # so a top-level key after `jobs:` would be swallowed into the last job and
    # moved with it. Refuse rather than move it silently.
    stray = [line for line in lines if line[:1] not in ("", " ", "#")]
    if stray:
        raise SystemExit(f"top-level content after `jobs:` is not supported: {stray[0]!r}")
    return pre, lines


def chunk_list(lines):
    """[(id, [lines])] in file order, blank lines stripped at both ends."""
    starts = [i for i, line in enumerate(lines) if HEADER.match(line)]
    if not starts:
        raise SystemExit("no job headers found")
    chunk_starts = []
    for h in starts:
        s = h
        floor = chunk_starts[-1] + 1 if chunk_starts else 0
        while s > floor and LEAD.match(lines[s - 1]):
            s -= 1
        chunk_starts.append(s)
    if any(line.strip() for line in lines[: chunk_starts[0]]):
        raise SystemExit("unexpected content between `jobs:` and the first job")
    out = []
    for n, s in enumerate(chunk_starts):
        e = chunk_starts[n + 1] if n + 1 < len(chunk_starts) else len(lines)
        block = lines[s:e]
        while block and not block[0].strip():
            block.pop(0)
        while block and not block[-1].strip():
            block.pop()
        out.append((HEADER.match(lines[starts[n]]).group(1), block))
    return out


def chunks(text):
    """{id: chunk text} with leading and trailing blank lines stripped."""
    _pre, lines = split_jobs(text)
    listed = chunk_list(lines)
    ids = [i for i, _ in listed]
    if len(ids) != len(set(ids)):
        raise SystemExit(f"duplicate job ids: {sorted(k for k, v in Counter(ids).items() if v > 1)}")
    return {i: "\n".join(block) for i, block in listed}


def cmd_apply(path):
    with open(path, encoding="utf-8") as fh:
        text = fh.read()
    pre, _lines = split_jobs(text)
    by_id = chunks(text)
    if sorted(by_id) != sorted(TARGET):
        raise SystemExit(f"chunk ids {sorted(by_id)} != target {sorted(TARGET)}")
    pre_lines = pre.split("\n")
    if len(pre_lines) < 2 or not pre_lines[1].startswith("# verify-"):
        raise SystemExit("header line 2 is not the `# verify-...` job id roster")
    pre_lines[1] = "# " + ", ".join(TARGET)
    new_text = "\n".join(pre_lines) + JOBS_SPLIT + "\n\n".join(by_id[i] for i in TARGET) + "\n"
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(new_text)
    print(f"reordered {len(TARGET)} jobs in {path}")
    return 0


def cmd_prove(before_path, after_path):
    with open(before_path, encoding="utf-8") as fh:
        before = fh.read()
    with open(after_path, encoding="utf-8") as fh:
        after = fh.read()
    ok = True

    b_lines = Counter(before.split("\n"))
    a_lines = Counter(after.split("\n"))
    removed = list((b_lines - a_lines).elements())
    added = list((a_lines - b_lines).elements())
    if (
        len(removed) == 1
        and len(added) == 1
        and removed[0].startswith("# verify-")
        and added[0].startswith("# verify-")
    ):
        print("line multiset: only the header roster line differs")
    else:
        ok = False
        print("line multiset differs beyond the header roster:")
        for line in removed:
            print(f"  - {line}")
        for line in added:
            print(f"  + {line}")

    b_chunks = chunks(before)
    a_chunks = chunks(after)
    if b_chunks == a_chunks:
        print(f"chunk multiset: {len(a_chunks)} chunks equal")
    else:
        ok = False
        for i in sorted(set(b_chunks) | set(a_chunks)):
            if b_chunks.get(i) != a_chunks.get(i):
                print(f"chunk differs: {i}")

    # IN-07 (221 review): content equality alone would "prove" an apply that
    # wrote the chunks in the wrong order.
    _pre, a_body = split_jobs(after)
    a_order = [i for i, _ in chunk_list(a_body)]
    if a_order == TARGET:
        print(f"job order: {len(a_order)} ids in TARGET order")
    else:
        ok = False
        print(f"job order differs from TARGET: {a_order}")

    return 0 if ok else 1


def main(argv):
    if len(argv) == 2 and argv[0] == "apply":
        return cmd_apply(argv[1])
    if len(argv) == 3 and argv[0] == "prove":
        return cmd_prove(argv[1], argv[2])
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
