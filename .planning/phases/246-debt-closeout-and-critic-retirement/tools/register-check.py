"""Parsers for the Phase 246 close check (called by verify-phase.sh via python3 -I).

Subcommands (exit 0 = pass, 1 = fail, 2 = usage/parse error; all fail closed):
  windows <WINDOWS.md>
  d09-filter <hits-file> [allow-entry ...]
"""

import json
import re
import sys


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


def d09_filter(hits_path, allow):
    rules = []
    for entry in allow:
        path, sep, pattern = entry.partition(":")
        rules.append((path, re.compile(pattern) if sep else None))
    unexempt = []
    for line in read(hits_path).splitlines():
        if not line:
            continue
        parts = line.split(":", 2)
        if len(parts) < 3:
            unexempt.append(line)
            continue
        path, _lineno, content = parts
        if any(rp == path and (rx is None or rx.search(content)) for rp, rx in rules):
            continue
        unexempt.append(line)
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
    if cmd == "d09-filter" and len(args) >= 1:
        return d09_filter(args[0], args[1:])
    print(__doc__)
    return 2


if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv))
    except (OSError, UnicodeDecodeError) as err:
        print("register-check: %s" % err)
        sys.exit(2)
