#!/usr/bin/env bash
#
# audit-project.sh - report where a project in projects/dotnet diverges from the
#                    monorepo conventions.
#
#   ./audit-project.sh              # every repo in .github/ci/repos.json
#   ./audit-project.sh Cutout       # one project
#   ./audit-project.sh --slnx       # also check the solution file
#
# Non-zero exit when anything is missing.

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
P="$ROOT/projects/dotnet"
REPOS="$ROOT/.github/ci/repos.json"
COPY="$ROOT/.github/ci/config/landing-copy.json"
ICONS="$ROOT/docs/theme/images"
TOTAL_FAIL=0
WANT_SLNX=0
NAMES=()

fail()  { printf '  MISSING  %s\n' "$1"; LOCAL_FAIL=1; }
warn()  { printf '  warn     %s\n' "$1"; }
csprojs() { find "$1" -name '*.csproj' -not -path '*/node_modules/*' -not -path '*/bin/*' -not -path '*/obj/*'; }

audit() {
  name="$1"
  dir="$P/$name"
  LOCAL_FAIL=0
  printf '\n== %s\n' "$name"

  [[ "$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)" != "$ROOT" ]] \
    || fail "$name is not a git submodule (scripts/add-dotnet-project.nu $name)"

  for f in LICENSE.md CODE_OF_CONDUCT.md SECURITY.md README.md commitlint.config.js \
           Common.Release.props Common.Test.props Common.Docs.props Common.Benchmark.props \
           Directory.Packages.props Parent.Directory.Packages.props global.json; do
    [[ -f "$dir/$f" ]] || fail "$name/$f"
  done

  grep -q 'Microsoft.Testing.Platform' "$dir/global.json" 2>/dev/null \
    || fail "$name/global.json does not set the MTP test runner"

  ([[ -f "$dir/.config/dotnet-tools.json" ]] && grep -q csharpier "$dir/.config/dotnet-tools.json") \
    || fail "csharpier in $name/.config/dotnet-tools.json"

  for h in commit-msg pre-commit; do
    [[ -f "$dir/.husky/$h" ]] || fail ".husky/$h in $name (ci-sync.sh workflows apply)"
  done

  if ! jq -e --arg r "$name" '.repos[] | select(.name == $r)' "$REPOS" >/dev/null; then
    fail "$name is not in .github/ci/repos.json"
  else
    docs="$(jq -r --arg r "$name" '.repos[] | select(.name == $r) | .docsProjectPath // empty' "$REPOS")"
    if [[ -n "$docs" ]]; then
      [[ -f "$dir/$docs/docfx.json" ]] || fail "$docs/docfx.json"
      [[ -f "$dir/$docs/toc.yml" ]]    || fail "$docs/toc.yml"
      [[ -d "$dir/$docs/template/public" ]] || warn "no template/public in $docs (ci-sync.sh docs apply)"
    fi
  fi

  icon="$(jq -r --arg r "$name" '.[$r].icon // empty' "$COPY")"
  [[ -n "$icon" ]] || fail "$name is not in landing-copy.json"
  [[ -z "$icon" || -f "$ICONS/$icon" ]] || fail "docs/theme/images/$icon (scripts/normalise-icons.py)"

  [[ "$(csprojs "$dir" | wc -l)" -gt 0 ]] || fail "no .csproj files in $name"
  find "$dir" -maxdepth 3 -name '*.Tests' -type d 2>/dev/null | grep -q . || warn "no *.Tests project"

  if [[ "$WANT_SLNX" == 1 ]]; then
    if [[ -f "$dir/$name.slnx" ]]; then
      csprojs "$dir" | while read -r proj; do
        grep -qF "${proj#"$dir"/}" "$dir/$name.slnx" || warn "${proj#"$dir"/} is not in $name.slnx"
      done
    else
      warn "no $name.slnx"
    fi
  fi

  TOTAL_FAIL=$((TOTAL_FAIL + LOCAL_FAIL))
  [[ "$LOCAL_FAIL" == 0 ]] && printf '  conventions ok\n'
}

for a in "$@"; do
  case "$a" in
    --slnx) WANT_SLNX=1 ;;
    *) NAMES+=("$a") ;;
  esac
done

if [[ ${#NAMES[@]} == 0 ]]; then
  while read -r r; do audit "$r"; done < <(jq -r '.repos[].name' "$REPOS")
else
  for n in "${NAMES[@]}"; do audit "$n"; done
fi

exit "$TOTAL_FAIL"
