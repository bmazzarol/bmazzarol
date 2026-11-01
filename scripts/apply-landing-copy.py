#!/usr/bin/env python3
"""
apply-landing-copy.py - rewrite the hero of every README, docs landing page and
NuGet package README from the shared copy in .github/ci/config/landing-copy.json.

Usage:
  ./scripts/apply-landing-copy.py --check            # report heroes that differ
  ./scripts/apply-landing-copy.py --write            # rewrite them in place
  ./scripts/apply-landing-copy.py --write --repos=Tuxedo,Cutout

The README keeps its badge shields, the docs landing page does not. Both get the
same title, tagline, description and logo so a repo and its docs site read the
same way.

A repo's README hero is rewritten by this script. Everything below the first H2
is hand written and is left alone.

Docs landing pages are markdown (index.md) or Polyglot Notebook markdown cells
(index.ipynb). Both are rewritten from the same copy.

Package READMEs (the README.md packed into a NuGet package by
Common.Release.props) get the same title, tagline and description, plus the
install command and a link to the docs site.
"""

import argparse
import difflib
import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
COPY_FILE = os.path.join(ROOT, ".github/ci/config/landing-copy.json")
REPOS_FILE = os.path.join(ROOT, ".github/ci/repos.json")
ICONS_DIR = os.path.join(ROOT, "docs/theme/images")

OWNER = "bmazzarol"
ICON_BASE = f"https://raw.githubusercontent.com/{OWNER}/"

BADGE_RE = re.compile(r"\[!\[[^\]]*\]\([^)]*\)\]\([^)]*\)")
DIV_START = re.compile(r'<div align="center">')
DIV_END = re.compile(r'</div>')
LINT_DISABLE = re.compile(r"<!--\s*markdownlint-disable")
LINT_ENABLE = re.compile(r"<!--\s*markdownlint-enable")


def submodule_paths():
    out = subprocess.run(
        ["git", "config", "-f", ".gitmodules", "--get-regexp", r"^submodule\."],
        capture_output=True,
        text=True,
        cwd=ROOT,
    ).stdout
    paths = {}
    for line in out.splitlines():
        _, path = line.split()
        paths[path.split("/")[-1]] = path
    return paths


def default_badges(repo, sonar_key, package):
    badges = []
    if package:
        badges.append(
            f"[![Nuget](https://img.shields.io/nuget/v/{package})]"
            f"(https://www.nuget.org/packages/{package}/)"
        )
    if sonar_key:
        badges.append(
            f"[![Coverage](https://sonarcloud.io/api/project_badges/measure?"
            f"project={sonar_key}&metric=coverage)]"
            f"(https://sonarcloud.io/summary/new_code?id={sonar_key})"
        )
        badges.append(
            f"[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?"
            f"project={sonar_key}&metric=alert_status)]"
            f"(https://sonarcloud.io/summary/new_code?id={sonar_key})"
        )
    badges.append(
        f"[![CD Build](https://github.com/{OWNER}/{repo}/actions/workflows/"
        f"cd-build.yml/badge.svg)](https://github.com/{OWNER}/{repo}/actions/workflows/cd-build.yml)"
    )
    badges.append(
        f"[![Check Markdown](https://github.com/{OWNER}/{repo}/actions/workflows/"
        f"check-markdown.yml/badge.svg)](https://github.com/{OWNER}/{repo}/actions/workflows/check-markdown.yml)"
    )
    return " ".join(badges)


def hero_region(lines):
    """Return (start, end) of the hero block, or None if there is not one.

    Old heroes are the centred <div> blocks. New heroes are simply everything
    before the first H2, so a canonical file is recognised as canonical.
    """
    start = None
    for i, line in enumerate(lines[:5]):
        if DIV_START.search(line) or LINT_DISABLE.search(line):
            start = i
            break
    if start is None:
        for i, line in enumerate(lines):
            if line.startswith("## "):
                return 0, i - 1
        return None
    end = None
    for j in range(start, len(lines)):
        if DIV_END.search(lines[j]):
            end = j
            break
    if end is None:
        return None
    if end + 1 < len(lines) and LINT_ENABLE.search(lines[end + 1]):
        end += 1
    return start, end


def readme_hero(repo, copy, sonar_key, docs_url, getting_started):
    badges = default_badges(repo, sonar_key, copy.get("package"))
    links = []
    if getting_started:
        links.append(f"[:running: **_Getting Started_**]({getting_started})")
    if docs_url:
        links.append(f"[:books: **_Documentation_**]({docs_url})")

    hero = [
        f"![{copy['title']}]({copy['icon']})",
        "",
        f"# {copy['title']}",
        "",
        f"**{copy['tagline']}**",
        "",
        copy["description"],
        "",
        badges,
    ]
    if links:
        hero += ["", " | ".join(links)]
    hero.append("")
    return hero


def docs_hero(copy):
    hero = [
        f"# {copy['title']}",
        "",
        f"![{copy['title']}](images/{copy['icon']})",
        "",
        f"**{copy['tagline']}**",
        "",
        copy["description"],
    ]
    package = copy.get("package")
    if package:
        hero += ["", "```shell", f"dotnet add package {package}", "```"]
    hero.append("")
    return hero


def notebook_hero(copy):
    """Hero for a Polyglot Notebook landing page.

    The notebook is rendered by the Polyglot docfx plugin, so the icon is an
    image in the markdown cell; the install snippet is left to the README.
    """
    return [
        f"# {copy['title']}",
        "",
        f"![{copy['title']}](images/{copy['icon']})",
        "",
        f"**{copy['tagline']}**",
        "",
        copy["description"],
        "",
    ]


def package_hero(repo, copy, entry, docs_url, getting_started):
    """Hero for a README that ships inside a NuGet package.

    The icon cannot be a relative path, because the icon is not packed into the
    package, so it points at the repo on GitHub.
    """
    title = entry.get("title") or copy["title"]
    description = entry.get("description") or copy["description"]
    relative = entry.get("gettingStarted")
    if relative and docs_url:
        getting_started = f"{docs_url}{relative}"
    hero = [
        f"![{title}]({ICON_BASE}{repo}/main/{entry['icon']})",
        "",
        f"# {title}",
        "",
        f"**{copy['tagline']}**",
        "",
        description,
        "",
    ]
    package = entry.get("package")
    if package:
        hero += [
            f"[![Nuget](https://img.shields.io/nuget/v/{package})]"
            f"(https://www.nuget.org/packages/{package}/)",
            "",
            "```shell",
            f"dotnet add package {package}",
            "```",
            "",
        ]
    links = []
    if getting_started:
        links.append(f"[Getting started]({getting_started})")
    if docs_url:
        links.append(f"[Full documentation]({docs_url})")
    if links:
        hero += [" - ".join(links), ""]
    return hero


def rewrite_package_readme(path, hero, label, check_only, show_diff=False):
    """Replace everything before the first H2 of a package README."""
    if not os.path.isfile(path):
        return f"{label}: missing {os.path.relpath(path, ROOT)}"
    with open(path, encoding="utf-8", newline="") as fh:
        text = fh.read()
    lines = text.splitlines()
    first_h2 = next((i for i, line in enumerate(lines) if line.startswith("## ")), len(lines))
    current = [line for line in lines[:first_h2] if line.strip()]
    wanted = [line for line in hero if line.strip()]
    if current == wanted:
        return f"{label}: already canonical"
    if check_only:
        if show_diff:
            print("\n".join(difflib.unified_diff(lines[:first_h2], hero, lineterm="")))
        return f"{label}: hero differs"
    new = "\n".join(hero + lines[first_h2:]).rstrip("\n") + "\n"
    with open(path, "w", encoding="utf-8", newline="") as fh:
        fh.write(new)
    return f"{label}: hero updated"


def rewrite_notebook(path, hero, label, check_only, show_diff=False):
    if not os.path.isfile(path):
        return f"{label}: missing {os.path.relpath(path, ROOT)}"
    with open(path, encoding="utf-8") as fh:
        nb = json.load(fh)
    cells = nb.get("cells", [])
    if not cells:
        return f"{label}: notebook has no cells"
    cell = cells[0]
    if cell.get("cell_type") != "markdown":
        return f"{label}: first cell is not markdown, skipping"
    text = "".join(cell["source"])
    lines = text.split("\n")
    region = hero_region(lines)
    if region:
        tail = lines[region[1] + 1:]
        while tail and not tail[0].strip():
            tail = tail[1:]
        wanted = hero + tail
    else:
        wanted = hero + lines
    new = strip_redundant_lint_comments("\n".join(wanted).rstrip("\n") + "\n")
    if text.rstrip("\n") == new.rstrip("\n"):
        return f"{label}: already canonical"
    if check_only:
        if show_diff:
            print("\n".join(difflib.unified_diff(lines, new.split("\n"), lineterm="")))
        return f"{label}: hero differs"
    cell["source"] = new.splitlines(keepends=True)
    with open(path, "w", encoding="utf-8") as fh:
        json.dump(nb, fh, indent=2, ensure_ascii=False)
        fh.write("\n")
    return f"{label}: rewritten"


def rewrite(path, hero, label, check_only, show_diff=False):
    if not os.path.isfile(path):
        return f"{label}: missing {os.path.relpath(path, ROOT)}"
    with open(path, encoding="utf-8") as fh:
        text = fh.read()
    lines = text.split("\n")
    region = hero_region(lines)
    if region:
        tail = lines[region[1] + 1:]
        while tail and not tail[0].strip():
            tail = tail[1:]
        wanted = hero + tail
    else:
        wanted = hero + lines
    new = "\n".join(wanted).rstrip("\n") + "\n"
    if text.rstrip("\n") == new.rstrip("\n"):
        return f"{label}: already canonical"
    if check_only:
        if show_diff:
            print("\n".join(difflib.unified_diff(text.split("\n"), new.split("\n"), lineterm="")))
        return f"{label}: hero differs"
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(strip_redundant_lint_comments(new))
    return f"{label}: rewritten"


def strip_redundant_lint_comments(text):
    """MD013 is disabled in the shared markdownlint config, so the inline
    disable/enable comments that used to guard long lines are noise."""
    out = []
    for line in text.split("\n"):
        if re.match(r"^\s*<!--\s*markdownlint-(disable|enable)\s+MD013\s*-->\s*$", line):
            continue
        out.append(line)
    return "\n".join(out)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--write", action="store_true")
    parser.add_argument("--diff", action="store_true", help="print the hero diff")
    parser.add_argument("--repos", help="comma separated repo names")
    args = parser.parse_args()
    check_only = not args.write

    copy = json.load(open(COPY_FILE, encoding="utf-8"))
    repos = json.load(open(REPOS_FILE, encoding="utf-8"))
    paths = submodule_paths()

    selected = args.repos.split(",") if args.repos else [r["name"] for r in repos["repos"]]

    for repo in selected:
        if repo not in copy:
            print(f"{repo:<32} no copy entry, skipping")
            continue
        entry = next((r for r in repos["repos"] if r["name"] == repo), None)
        path = paths.get(repo)
        if not path:
            print(f"{repo:<32} not a submodule, skipping")
            continue
        repo_dir = os.path.join(ROOT, path)
        c = copy[repo]
        sonar = entry.get("sonarProjectKey") if entry else None
        docs_path = entry.get("docsProjectPath") if entry else None
        docs_url = f"https://bmazzarol.github.io/{repo}/" if docs_path else None

        getting_started = None
        if docs_path and c.get("gettingStarted"):
            getting_started = f"{docs_url}{c['gettingStarted']}"

        readme = os.path.join(repo_dir, "README.md")
        result = rewrite(readme, readme_hero(repo, c, sonar, docs_url, getting_started), "README", check_only, args.diff)
        print(f"{repo:<32} {result}")

        for entry in c.get("packageReadmes", []):
            package_readme = os.path.join(repo_dir, entry["path"])
            if not os.path.isfile(package_readme):
                print(f"{repo:<32} package readme {entry['path']} missing")
                continue
            result = rewrite_package_readme(
                package_readme,
                package_hero(repo, c, entry, docs_url, getting_started),
                entry["path"],
                check_only,
                args.diff,
            )
            print(f"{repo:<32} {result}")

        if docs_path:
            landing = c.get("docsLanding", "index.md")
            index = os.path.join(repo_dir, docs_path, landing)
            if os.path.isfile(index):
                if index.endswith(".ipynb"):
                    result = rewrite_notebook(index, notebook_hero(c), f"docs/{landing}", check_only, args.diff)
                else:
                    result = rewrite(index, docs_hero(c), f"docs/{landing}", check_only, args.diff)
                print(f"{repo:<32} {result}")

        icon = os.path.join(ICONS_DIR, c["icon"])
        root_icon = os.path.join(repo_dir, c["icon"])
        if docs_path:
            docs_icon = os.path.join(repo_dir, docs_path, "images", c["icon"])
            if os.path.isfile(icon) and os.path.isfile(docs_icon):
                print(f"{repo:<32} {rewrite_docs_icon(docs_icon, icon, check_only)}")
        if os.path.isfile(icon) and os.path.isfile(root_icon):
            print(f"{repo:<32} {rewrite_docs_icon(root_icon, icon, check_only)}")

    return 0


def rewrite_docs_icon(target, canonical, check_only):
    import hashlib

    a = hashlib.sha256(open(canonical, "rb").read()).hexdigest()
    b = hashlib.sha256(open(target, "rb").read()).hexdigest()
    if a == b:
        return "icon already canonical"
    if check_only:
        return "icon differs (not resized)"
    with open(target, "wb") as fh:
        fh.write(open(canonical, "rb").read())
    return "icon replaced with the canonical 128px version"


if __name__ == "__main__":
    sys.exit(main())
