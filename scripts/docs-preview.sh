#!/usr/bin/env bash
#
# docs-preview.sh - build the staging documentation site and look at it before
#                   any theme or copy change is rolled out to the project sites.
#
# Usage:
#   ./scripts/docs-preview.sh              build docs/_site
#   ./scripts/docs-preview.sh --serve      build and serve on http://localhost:8080
#   ./scripts/docs-preview.sh --shot       build and write a screenshot of the
#                                          landing page to docs/_site/preview.png
#
# Environment:
#   PORT        port for --serve (default 8080)
#   DARK=1      render the screenshot in dark mode
#
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
DOCS="$ROOT/docs"
PORT="${PORT:-8080}"

build() {
  cd "$DOCS"
  dotnet tool restore >/dev/null
  dotnet docfx build docfx.json --warningsAsErrors
  printf 'built: %s/_site\n' "$DOCS"
}

serve() {
  printf 'serving %s/_site at http://localhost:%s\n' "$DOCS" "$PORT"
  python3 -m http.server "$PORT" --directory "$DOCS/_site"
}

shot() {
  if ! command -v chromium >/dev/null && ! command -v google-chrome >/dev/null; then
    printf 'chromium is not available, cannot take a screenshot\n' >&2
    return 1
  fi
  browser="$(command -v chromium || command -v google-chrome)"
  flags=(--headless=new --no-sandbox --disable-gpu --window-size=1200,1200)
  if [[ "${DARK:-0}" == "1" ]]; then
    flags+=(--force-dark-mode)
  fi
  "$browser" "${flags[@]}" --screenshot="$DOCS/_site/preview.png" \
    "file://$DOCS/_site/index.html"
  printf 'screenshot: %s/_site/preview.png\n' "$DOCS"
}

action="${1:-build}"
build
case "$action" in
  build) ;;
  serve|--serve) serve ;;
  shot|--shot) shot ;;
  *) printf 'unknown action: %s (build, --serve, --shot)\n' "$action" >&2; exit 1 ;;
esac
