"""Parsers for the Phase 246 close check (called by verify-phase.sh via python3 -I).

Subcommands (exit 0 = pass, 1 = fail, 2 = usage/parse error; all fail closed):
  windows <WINDOWS.md>
  register <register.md> counts
  register <register.md> cells
  register <register.md> routes
  register <register.md> unique
  register <register.md> coverage <w-spec> <prefix>:<min> <required-id> ...
  d09-filter <hits-file> <contributing-file> <retired-heading> [allow-entry ...]

The register is the first-column-id markdown table(s) whose header row has a
"disposition" cell. Row order never changes a verdict.
"""

import json
import re
import sys
from collections import Counter

DISPOSITIONS = ("closed", "waived", "routed")
ROUTE_RX = re.compile(r"v1\.(48|49|50|51)\b|SEED-[0-9]{3}")
COUNT_RX = re.compile(r"^\s*(closed|waived|routed|total):\s*(\S*)\s*$")


def read(path):
    with open(path, encoding="utf-8") as fh:
        return fh.read()


def frontmatter(text):
    if not text.startswith("---\n"):
        return None
    end = text.find("\n---\n", 4)
    if end < 0:
        return None
    return text[4:end]


# --------------------------------------------------------------------------- WINDOWS

def windows(path):
    text = read(path)
    fm = frontmatter(text)
    problems = []
    if fm is None:
        problems.append("no frontmatter block")
    elif not re.search(r"^open_count: 0$", fm, re.M):
        line = re.search(r"^open_count:.*$", fm, re.M)
        problems.append("frontmatter: %s" % (line.group(0) if line else "no open_count line"))
    fence = re.search(r"^(`{3,})json[ \t]*\n(.*?)^\1[ \t]*$", text, re.M | re.S)
    if not fence:
        print("no ```json block found")
        return 1
    try:
        entries = json.loads(fence.group(2))
    except ValueError as err:
        print("WINDOWS json block does not parse: %s" % err)
        return 1
    if not isinstance(entries, list):
        print("WINDOWS json block is not a list")
        return 1
    open_ids = [e.get("id") for e in entries if isinstance(e, dict) and e.get("status") == "open"]
    if open_ids:
        problems.append("%d open rows: %s" % (len(open_ids), ", ".join(str(i) for i in open_ids)))
    for p in problems:
        print(p)
    return 1 if problems else 0


# --------------------------------------------------------------------------- register

def split_cells(line):
    body = line.strip()
    if body.startswith("|"):
        body = body[1:]
    if body.endswith("|") and not body.endswith("\\|"):
        body = body[:-1]
    return [c.strip() for c in re.split(r"(?<!\\)\|", body)]


def norm_id(cell):
    return re.sub(r"<[^>]*>", "", cell).replace("`", "").replace("*", "").strip()


def register_rows(text):
    """Return a list of (line_no, id, disposition, reason) for every register row."""
    lines = text.splitlines()
    rows = []
    i = 0
    while i < len(lines):
        if not lines[i].lstrip().startswith("|"):
            i += 1
            continue
        block = []
        while i < len(lines) and lines[i].lstrip().startswith("|"):
            block.append((i + 1, lines[i]))
            i += 1
        if len(block) < 2:
            continue
        header = [c.lower() for c in split_cells(block[0][1])]
        sep = split_cells(block[1][1])
        if "disposition" not in header or not all(re.fullmatch(r":?-{3,}:?", c) for c in sep):
            continue
        d_col = header.index("disposition")
        r_col = next((k for k, h in enumerate(header) if "reason" in h or "route" in h), len(header) - 1)
        for line_no, line in block[2:]:
            cells = split_cells(line)
            cells += [""] * (len(header) - len(cells))
            rows.append((line_no, norm_id(cells[0]), cells[d_col], cells[r_col]))
    return rows


def expand_spec(spec):
    out = set()
    for part in spec.replace(",", " ").split():
        if "-" in part:
            lo, hi = part.split("-", 1)
            out.update(range(int(lo), int(hi) + 1))
        else:
            out.add(int(part))
    return out


def register(path, check, extra):
    text = read(path)
    rows = register_rows(text)
    if not rows:
        print("no register rows parsed from %s (an empty register fails closed)" % path)
        return 1
    problems = []
    if check == "counts":
        fm = frontmatter(text)
        if fm is None:
            print("register has no frontmatter block")
            return 1
        declared = {}
        for line in fm.splitlines():
            m = COUNT_RX.match(line)
            if m:
                if m.group(1) in declared:
                    problems.append("frontmatter key %s: appears twice" % m.group(1))
                declared[m.group(1)] = m.group(2)
        actual = Counter(r[2] for r in rows)
        actual_map = {d: actual.get(d, 0) for d in DISPOSITIONS}
        actual_map["total"] = len(rows)
        for key in DISPOSITIONS + ("total",):
            if key not in declared:
                problems.append("frontmatter key %s: missing" % key)
            elif declared[key] != str(actual_map[key]):
                problems.append("frontmatter %s: %s but table has %d" % (key, declared[key], actual_map[key]))
    elif check == "cells":
        for line_no, rid, disp, reason in rows:
            if disp not in DISPOSITIONS:
                problems.append("line %d (%s): disposition %r not in %s" % (line_no, rid or "<no id>", disp, "/".join(DISPOSITIONS)))
            if not reason:
                problems.append("line %d (%s): blank reason" % (line_no, rid or "<no id>"))
            if not rid:
                problems.append("line %d: blank id" % line_no)
    elif check == "routes":
        for line_no, rid, disp, reason in rows:
            if disp == "routed" and not ROUTE_RX.search(reason):
                problems.append("line %d (%s): routed reason names no v1.48-v1.51 milestone or SEED-NNN: %r" % (line_no, rid, reason))
    elif check == "unique":
        seen = Counter(r[1] for r in rows)
        for rid, n in sorted(seen.items()):
            if n > 1:
                lines = [str(r[0]) for r in rows if r[1] == rid]
                problems.append("duplicate id %s on lines %s" % (rid, ", ".join(lines)))
    elif check == "coverage":
        if len(extra) < 2:
            print("coverage needs <w-spec> <prefix>:<min> [required ...]")
            return 2
        want_w = expand_spec(extra[0])
        prefix, _, minimum = extra[1].rpartition(":")
        required = extra[2:]
        if not want_w or not required:
            print("coverage: empty expected id list (would pass vacuously)")
            return 2
        ids = {r[1] for r in rows}
        have_w = {int(i[1:]) for i in ids if re.fullmatch(r"W\d+", i)}
        missing_w = sorted(want_w - have_w)
        extra_w = sorted(have_w - want_w)
        if missing_w:
            problems.append("missing W ids: %s" % ", ".join("W%d" % n for n in missing_w))
        if extra_w:
            problems.append("unexpected W ids: %s" % ", ".join("W%d" % n for n in extra_w))
        missing = [i for i in required if i not in ids]
        if missing:
            problems.append("missing required ids: %s" % ", ".join(missing))
        n_prefix = sum(1 for i in ids if i.startswith(prefix))
        if n_prefix < int(minimum):
            problems.append("only %d ids start with %s (need >= %s)" % (n_prefix, prefix, minimum))
    else:
        print("unknown register check %r" % check)
        return 2
    for p in problems:
        print(p)
    return 1 if problems else 0


# --------------------------------------------------------------------------- D-09

def retired_range(contributing, heading):
    """1-based [start, end) line range of the retired section, or None (fail closed)."""
    try:
        lines = read(contributing).splitlines()
    except OSError:
        return None
    starts = [n for n, line in enumerate(lines, 1) if line == heading]
    if len(starts) != 1:
        return None
    start = starts[0]
    end = next((n for n, line in enumerate(lines, 1) if n > start and line.startswith("## ")), len(lines) + 1)
    return (start, end)


def d09_filter(hits_path, contributing, heading, allow):
    rules = []
    for entry in allow:
        path, sep, pattern = entry.partition(":")
        rules.append((path, re.compile(pattern) if sep else None))
    section = retired_range(contributing, heading)
    unexempt = []
    for line in read(hits_path).splitlines():
        if not line:
            continue
        parts = line.split(":", 2)
        if len(parts) < 3 or not parts[1].isdigit():
            unexempt.append(line)
            continue
        path, lineno, content = parts[0], int(parts[1]), parts[2]
        if any(rp == path and (rx is None or rx.search(content)) for rp, rx in rules):
            continue
        if path == "CONTRIBUTING.md" and section and section[0] <= lineno < section[1]:
            continue
        unexempt.append(line)
    if section is None:
        print("note: no single %r heading; no CONTRIBUTING.md line is exempt" % heading)
    for line in unexempt:
        print(line)
    if unexempt:
        print("%d unallowlisted D-09 hits" % len(unexempt))
        return 1
    return 0


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 2
    cmd, args = argv[1], argv[2:]
    if cmd == "windows" and len(args) == 1:
        return windows(args[0])
    if cmd == "register" and len(args) >= 2:
        return register(args[0], args[1], args[2:])
    if cmd == "d09-filter" and len(args) >= 3:
        return d09_filter(args[0], args[1], args[2], args[3:])
    print(__doc__)
    return 2


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv))
    except (OSError, UnicodeDecodeError, ValueError) as err:
        print("register-check: %s" % err)
        sys.exit(2)
