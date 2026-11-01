#!/usr/bin/env python3
"""Check that every Markdown table is well formed.

markdownlint does not parse tables, so a header split across several lines -
the kind docfx quietly renders as a paragraph - passes linting and ships.
This walks the same globs as markdownlint and reports tables whose rows do not
agree with their delimiter row.

Usage: check-tables.py "**/*.md" "!**/_site/**" ...
"""

import glob
import re
import sys

DELIMITER = re.compile(r"^\|(\s*:?-{1,}:?\s*\|)+$")
ROW = re.compile(r"^\|.+\|$")
FENCE = re.compile(r"^\s*(```|~~~)")


def files(patterns):
    included, excluded = set(), set()
    for pattern in patterns:
        target = excluded if pattern.startswith("!") else included
        target.update(glob.glob(pattern.lstrip("!"), recursive=True))
    return sorted(included - excluded)


def check(path):
    problems = []
    with open(path, encoding="utf-8") as handle:
        lines = handle.read().splitlines()

    inside_fence = False
    line = 0
    while line < len(lines):
        if FENCE.match(lines[line]):
            inside_fence = not inside_fence
            line += 1
            continue

        if not inside_fence and ROW.match(lines[line].strip()):
            start = line
            while line < len(lines) and ROW.match(lines[line].strip()):
                line += 1
            rows = lines[start:line]

            delimiter = next(
                (i for i, row in enumerate(rows) if DELIMITER.match(row.strip())),
                None,
            )
            if delimiter is None:
                problems.append(f"{path}:{start + 1} no delimiter row after the header")
            elif delimiter != 1:
                problems.append(
                    f"{path}:{start + delimiter + 1} delimiter row is not the second row"
                )
            else:
                cells = rows[delimiter].strip().count("|")
                for offset, row in enumerate(rows):
                    if offset == delimiter:
                        continue
                    if row.strip().count("|") != cells:
                        problems.append(
                            f"{path}:{start + offset + 1} has {row.strip().count('|') - 1} "
                            f"cells, the delimiter row has {cells - 1}"
                        )
        line += 1

    return problems


def main():
    patterns = sys.argv[1:] or ["**/*.md"]
    problems = []
    for path in files(patterns):
        problems.extend(check(path))

    if problems:
        print("Markdown tables are malformed:")
        for problem in problems:
            print(f"  {problem}")
        return 1

    print(f"tables ok in {len(files(patterns))} files")
    return 0


if __name__ == "__main__":
    sys.exit(main())
