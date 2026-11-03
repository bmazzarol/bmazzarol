#!/usr/bin/env bash
#
# ci-sync.sh - one source of truth for CI settings and secrets across every
#              repo in the bmazzarol monorepo.
#
# Sources:
#   .github/ci/repos.json                 canonical repo list + per-repo settings
#   .github/ci/workflows/                 canonical workflow templates, byte
#                                         identical for every repo; the per-repo
#                                         values come from repo variables instead
#                                         of being hard-coded in each workflow
#   ~/.config/bmazzarol/ci-secrets.env    local secret vault (never committed)
#
# The vault may also be supplied as plain environment variables, which is how
# the scheduled .github/workflows/ci-sync.yml job works.
#
# Usage:
#   ci-sync.sh repos                       list the managed repos and settings
#   ci-sync.sh vault                       show vault keys (values masked)
#   ci-sync.sh rotate NAME                 prompt for a value, store it, push it
#   ci-sync.sh set NAME VALUE              store a value, push it
#   ci-sync.sh sync [NAME...]              push every vault value to every repo
#   ci-sync.sh check                       report drift (missing secrets / vars)
#   ci-sync.sh verify                      confirm the vault's Sonar token is accepted
#   ci-sync.sh settings                    push per-repo settings as repo variables
#   ci-sync.sh workflows check             compare each repo to the templates
#   ci-sync.sh workflows apply [--commit]  write the templates into each repo
#   ci-sync.sh docs check                  report docfx theme + metadata drift
#   ci-sync.sh docs apply                  sync theme and metadata into every docs project
#   ci-sync.sh landing check               report README/docs landing page drift
#   ci-sync.sh landing apply               rewrite landing heroes from the shared copy
#   ci-sync.sh status                      last workflow run per repo
#
# Options:
#   --repos=a,b,c   limit to these repos
#   --dry-run       show what would be written
#
set -euo pipefail

OWNER="bmazzarol"
ROOT="$(git rev-parse --show-toplevel)"
CONFIG="${CI_CONFIG:-$ROOT/.github/ci/repos.json}"
TEMPLATES="${CI_TEMPLATES:-$ROOT/.github/ci/workflows}"
SHARED_CONFIG="${CI_SHARED_CONFIG:-$ROOT/.github/ci/config}"
DOCS_METADATA="${CI_DOCS_METADATA:-$ROOT/.github/ci/config/docfx-global-metadata.json}"
DOCS_THEME="${CI_DOCS_THEME:-$ROOT/docs/theme/public}"
LANDING_COPY="${CI_LANDING_COPY:-$ROOT/.github/ci/config/landing-copy.json}"
HUSKY_CONFIG="${CI_HUSKY_CONFIG:-$ROOT/.github/ci/config/husky}"
VAULT="${CI_SECRETS_FILE:-${XDG_CONFIG_HOME:-$HOME/.config}/bmazzarol/ci-secrets.env}"

FILTER_REPOS=""
DRY_RUN=0

SETTINGS="sonarProjectKey:SONAR_PROJECT_KEY docsProjectPath:DOCS_PROJECT_PATH csProjFileName:CS_PROJ_FILE_NAME markdownGlobs:MARKDOWN_GLOBS dotnetVersion:DOTNET_VERSION"

declare -A SECRET       # name -> value
declare -A SECRET_SRC   # name -> vault | env

die() { printf '%s\n' "$*" >&2; exit 1; }

need_tools() {
  for t in gh jq git; do
    if ! command -v "$t" >/dev/null; then
      die "$t is required but not installed"
    fi
  done
}

# ---------------------------------------------------------------- config ----
repo_names()     { jq -r '.repos[].name' "$CONFIG"; }
all_secrets()    { jq -r '.secrets[]' "$CONFIG"; }
repo_setting()   { jq -r --arg r "$1" --arg k "$2" '.repos[] | select(.name == $r) | .[$k] // empty' "$CONFIG"; }

target_repos() {
  if [[ -n "$FILTER_REPOS" ]]; then
    printf '%s\n' "$FILTER_REPOS" | tr ',' '\n'
  else
    repo_names
  fi
}

# ---------------------------------------------------------------- vault ----
load_vault() {
  SECRET=()
  SECRET_SRC=()

  if [[ -f "$VAULT" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
      line="${line%%$'\r'}"
      if [[ -z "$line" || "${line:0:1}" == "#" ]]; then
        continue
      fi
      key="${line%%=*}"
      val="${line#*=}"
      if [[ "$key" == "$line" ]]; then
        continue
      fi
      key="${key// /}"
      SECRET["$key"]="$val"
      SECRET_SRC["$key"]="vault"
    done < "$VAULT"
  fi

  # Environment always wins, so CI can run without a vault file.
  for name in $(all_secrets); do
    env_val="${!name:-}"
    if [[ -n "$env_val" ]]; then
      SECRET["$name"]="$env_val"
      SECRET_SRC["$name"]="env"
    fi
  done
}

vault_write() { # name value
  mkdir -p "$(dirname "$VAULT")"
  if [[ -f "$VAULT" ]] && grep -q "^${1}=" "$VAULT";
    then
    awk -v k="$1" -v v="$2" 'index($0, k "=") == 1 { print k "=" v; next } { print }' "$VAULT" > "$VAULT.tmp"
    mv "$VAULT.tmp" "$VAULT"
  else
    printf '%s=%s\n' "$1" "$2" >> "$VAULT"
  fi
  chmod 600 "$VAULT"
}

mask() {
  local v="$1"
  if [[ -z "$v" ]]; then
    printf '(empty)'
  else
    printf '%s...%s (%d chars)' "${v:0:4}" "${v: -4}" "${#v}"
  fi
}

# ------------------------------------------------------------ gh helpers ----
gh_repo() { printf '%s/%s\n' "$OWNER" "$1"; }

secret_names_for() {
  gh api "repos/$(gh_repo "$1")/actions/secrets" --jq '.secrets[].name' 2>/dev/null || true
}

variable_value_for() {
  gh api "repos/$(gh_repo "$1")/actions/variables/$2" --jq '.value' 2>/dev/null || true
}

push_secret() { # repo name value
  if (( DRY_RUN )); then
    printf '    [dry-run] %s=%s\n' "$2" "$(mask "$3")"
  else
    gh secret set "$2" --body "$3" -R "$(gh_repo "$1")"
  fi
}

push_variable() { # repo name value
  if (( DRY_RUN )); then
    printf '    [dry-run] %s=%s\n' "$2" "$3"
  else
    gh variable set "$2" --body "$3" -R "$(gh_repo "$1")"
  fi
}

# ------------------------------------------------------------ commands ----
cmd_verify() {
  load_vault
  ok=0
  token="${SECRET[SONAR_TOKEN]:-}"
  if [[ -z "$token" ]]; then
    printf 'SONAR_TOKEN: not in the vault or environment\n'
    ok=1
  else
    valid="$(curl -sS -m 20 -H "Authorization: Bearer $token" https://sonarcloud.io/api/authentication/validate | jq -r .valid)"
    if [[ "$valid" == "true" ]]; then
      printf 'SONAR_TOKEN: valid (%s)\n' "$(mask "$token")"
    else
      printf 'SONAR_TOKEN: REJECTED by SonarCloud (%s)\n' "$(mask "$token")"
      ok=1
    fi
  fi
  return $ok
}

cmd_repos() {
  printf 'owner:  %s\nvault:  %s\ntemplates: %s\n\n' "$OWNER" "$VAULT" "$TEMPLATES"
  for r in $(repo_names); do
    printf '%s/%s\n' "$OWNER" "$r"
    for pair in $SETTINGS; do
      printf '  %-16s %s\n' "${pair##*:}" "$(repo_setting "$r" "${pair%%:*}")"
    done
  done
}

cmd_vault() {
  load_vault
  for name in $(all_secrets); do
    if [[ -n "${SECRET[$name]:-}" ]]; then
      printf '  %-12s %-28s (%s)\n' "$name" "$(mask "${SECRET[$name]}")" "${SECRET_SRC[$name]}"
    else
      printf '  %-12s (not set)\n' "$name"
    fi
  done
  if [[ ${#SECRET[@]} -eq 0 ]]; then
    printf '\nSeed the vault with:\n  %s rotate SONAR_TOKEN\n  %s set NUGET_API_KEY <key>\n' "$0" "$0"
    return 1
  fi
}

cmd_rotate() {
  name="${1:-}"
  [[ -n "$name" ]] || die "rotate needs a secret name, e.g. rotate SONAR_TOKEN"
  if [[ -n "${CI_SECRET_VALUE:-}" ]]; then
    value="$CI_SECRET_VALUE"
  elif [[ -t 0 ]]; then
    read -r -p "New value for $name: " value
  else
    value="${!name:-}"
  fi
  [[ -n "$value" ]] || die "empty value, nothing stored"
  vault_write "$name" "$value"
  for r in $(target_repos); do
    printf '%s\n' "$r"
    push_secret "$r" "$name" "$value"
  done
}

cmd_set() {
  name="${1:-}"
  value="${2:-}"
  [[ -n "$name" && -n "$value" ]] || die "set needs NAME VALUE"
  vault_write "$name" "$value"
  for r in $(target_repos); do
    printf '%s\n' "$r"
    push_secret "$r" "$name" "$value"
  done
}

cmd_sync() {
  load_vault
  if [[ $# -gt 0 ]]; then
    names="$*"
  else
    names="$(all_secrets)"
  fi
  for name in $names; do
    value="${SECRET[$name]:-}"
    if [[ -z "$value" ]]; then
      printf 'skipping %s: no value in the vault or environment\n' "$name"
      continue
    fi
    printf '%s\n' "$name"
    for r in $(target_repos); do
      printf '  %s\n' "$r"
      push_secret "$r" "$name" "$value"
    done
  done
}

cmd_check() {
  load_vault
  drift=0
  for r in $(target_repos); do
    have="$(secret_names_for "$r")"
    missing=""
    for name in $(all_secrets); do
      if ! grep -qx "$name" <<< "$have"; then
        missing="$missing $name"
      fi
    done

    stale=""
    for pair in $SETTINGS; do
        want="$(repo_setting "$r" "${pair%%:*}")"
        var="${pair##*:}"
        if [[ -z "$want" || "$want" == "null" ]]; then
            continue
        fi
        if [[ "$(variable_value_for "$r" "$var")" != "$want" ]]; then
            stale="$stale $var"
        fi
    done
    if [[ -z "$missing" && -z "$stale" ]]; then
      printf '  %-32s ok\n' "$r"
    else
      drift=1
      printf '  %-32s drift\n' "$r"
      if [[ -n "$missing" ]]; then
        printf '      missing secrets:%s\n' "$missing"
      fi
      if [[ -n "$stale" ]]; then
        printf '      settings out of sync:%s\n' "$stale"
      fi
    fi
  done
  if (( drift )); then
    return 1
  fi
}

cmd_settings() {
  for r in $(target_repos); do
    printf '%s\n' "$r"
    for pair in $SETTINGS; do
      want="$(repo_setting "$r" "${pair%%:*}")"
      if [[ -z "$want" || "$want" == "null" ]]; then
        continue
      fi
      push_variable "$r" "${pair##*:}" "$want"
    done
  done
}

submodule_path() {
  git config -f "$ROOT/.gitmodules" --get-regexp '^submodule\.' |
    awk -v n="$1" '{ p = $2; split(p, a, "/"); if (a[length(a)] == n) print p }'
}

repo_path() {
  p="$(repo_setting "$1" path)"
  if [[ -z "$p" || "$p" == "null" ]]; then
    p="$(submodule_path "$1")"
  fi
  printf '%s' "$p"
}

# Submodules are checked out detached at their pinned commit. Any write into a
# submodule has to start from the branch we actually push to.
ensure_main() {
  p="$ROOT/$1"
  [[ -d "$p/.git" ]] || return 0
  git -C "$p" checkout main >/dev/null 2>&1 || true
  git -C "$p" pull origin main >/dev/null 2>&1 || true
}

cmd_workflows() {
  action="${1:-check}"
  commit="${2:-}"
  for r in $(target_repos); do
    path="$(repo_path "$r")"
    if [[ -z "$path" ]]; then
      printf '  %-32s no local checkout, skipping\n' "$r"
      continue
    fi
    if [[ "$action" == "apply" ]]; then
      ensure_main "$path"
    fi
    diffs=0
    synced=()
    for tpl in "$TEMPLATES"/*.yml "$SHARED_CONFIG"/.* "$SHARED_CONFIG"/* "$HUSKY_CONFIG"/*; do
      [[ -f "$tpl" ]] || continue
      name="$(basename "$tpl")"
      # root-only sources of truth: the docfx metadata is written into docfx.json by
      # `docs apply`, and the landing copy is applied to each repo's README/docs page
      # by scripts/apply-landing-copy.py. Neither is copied into a repo as a file.
      [[ "$name" == "docfx-global-metadata.json" ]] && continue
      [[ "$name" == "landing-copy.json" ]] && continue
      if [[ "$tpl" == "$TEMPLATES"/* ]]; then
        docs="$(repo_setting "$r" docsProjectPath)"
        if [[ ("$name" == "check-docs.yml" || "$name" == "build-deploy-docs.yml") && ( -z "$docs" || "$docs" == "null" ) ]]; then
          printf '  %-32s %s skipped (no docs project)\n' "$r" "$name"
          continue
        fi
        rel=".github/workflows/$name"
      elif [[ "$tpl" == "$HUSKY_CONFIG"/* ]]; then
        rel=".husky/$name"
      else
        rel="$name"
      fi
      local_file="$ROOT/$path/$rel"
      if [[ ! -f "$local_file" ]]; then
        printf '  %-32s %s missing\n' "$r" "$rel"
        diffs=1
        synced+=("$rel")
      elif ! diff -q "$tpl" "$local_file" >/dev/null; then
        printf '  %-32s %s differs\n' "$r" "$rel"
        diffs=1
        synced+=("$rel")
      fi
      if [[ "$action" == "apply" ]]; then
        mkdir -p "$(dirname "$local_file")"
        cp "$tpl" "$local_file"
        [[ "$tpl" == "$HUSKY_CONFIG"/* ]] && chmod +x "$local_file"
      fi
    done
    if (( diffs == 0 )); then
      printf '  %-32s workflows in sync\n' "$r"
    fi

    if [[ "$action" == "apply" ]]; then
      printf '  %-32s templates written\n' "$r"
      if [[ "$commit" == "--commit" ]]; then
        git -C "$ROOT/$path" add .github/workflows
        for cfg in "${synced[@]}"; do
          git -C "$ROOT/$path" add "$cfg"
        done
        if git -C "$ROOT/$path" diff --cached --quiet; then
          printf '  %-32s nothing to commit\n' "$r"
        else
          git -C "$ROOT/$path" commit --no-verify -m "chore(ci): sync workflow templates and shared config from bmazzarol/bmazzarol"
          git -C "$ROOT/$path" push origin main
          if git config -f "$ROOT/.gitmodules" --get-regexp path | grep -q "$path"; then
            git -C "$ROOT" add "$path"
          fi
        fi
      fi
    fi
  done
  if [[ "$action" == "apply" && "$commit" == "--commit" ]]; then
    printf '\nSubmodule pointers are staged. Commit them with:\n  git commit -m "chore: bump submodule pointers after ci-sync"\n'
  fi
}

cmd_docs() {
  action="${1:-check}"
  [[ -d "$DOCS_THEME" ]] || die "missing theme directory: $DOCS_THEME"
  [[ -f "$DOCS_METADATA" ]] || die "missing docfx metadata: $DOCS_METADATA"

  drift=0
  for r in $(target_repos); do
    path="$(repo_path "$r")"
    docs="$(repo_setting "$r" docsProjectPath)"
    if [[ -z "$path" || -z "$docs" || "$docs" == "null" ]]; then
      printf '  %-32s no docs project, skipping\n' "$r"
      continue
    fi
    if [[ "$action" == "apply" ]]; then
      ensure_main "$path"
    fi

    cfg="$ROOT/$path/$docs/docfx.json"
    dest="$ROOT/$path/$docs/template/public"
    differs=0

    if [[ ! -d "$dest" ]]; then
      printf '  %-32s template/public missing\n' "$r"
      differs=1
    elif ! diff -rq "$DOCS_THEME" "$dest" >/dev/null; then
      printf '  %-32s theme differs (css, js, fonts)\n' "$r"
      differs=1
    fi

    if [[ -d "$DOCS_THEME/../images" ]]; then
      for img in "$DOCS_THEME/../images"/*.png; do
        if [[ -f "$dest/../images/$(basename "$img")" ]] &&
           ! cmp -s "$img" "$dest/../images/$(basename "$img")"; then
          printf '  %-32s %s differs\n' "$r" "images/$(basename "$img")"
          differs=1
        fi
      done
    fi

    if [[ -f "$cfg" ]]; then
      for key in $(jq -r 'keys[]' "$DOCS_METADATA"); do
        want="$(jq -r --arg k "$key" '.[$k]' "$DOCS_METADATA")"
        have="$(jq -r --arg k "$key" '.build.globalMetadata | .[$k] // "missing"' "$cfg")"
        if [[ "$have" != "$want" ]]; then
          printf '  %-32s docfx.json %s: %s (want %s)\n' "$r" "$key" "$have" "$want"
          differs=1
        fi
      done
    else
      printf '  %-32s docfx.json not found\n' "$r"
      differs=1
    fi

    if (( differs == 0 )); then
      printf '  %-32s docs in sync\n' "$r"
    else
      drift=1
    fi

    if [[ "$action" != "apply" ]]; then
      continue
    fi
    if (( DRY_RUN )); then
      printf '    [dry-run] would sync theme and metadata into %s/%s\n' "$path" "$docs"
      continue
    fi

    mkdir -p "$dest"
    cp -r "$DOCS_THEME"/. "$dest"

    logo="$(jq -r '.build.globalMetadata._appLogoPath // empty' "$cfg")"
    if [[ -n "$logo" ]]; then
      canon="$DOCS_THEME/../images/$(basename "$logo")"
      if [[ -f "$canon" ]]; then
        mkdir -p "$(dirname "$ROOT/$path/$docs/$logo")"
        cp "$canon" "$ROOT/$path/$docs/$logo"
      fi
    fi
    tmp="$(mktemp)"
    jq --indent 4 --argjson meta "$(cat "$DOCS_METADATA")" \
      '.build.globalMetadata = ((.build.globalMetadata // {}) + $meta)' "$cfg" > "$tmp"
    mv "$tmp" "$cfg"

    git -C "$ROOT/$path" add "$docs/template/public" "$docs/docfx.json"
    if [[ -n "$logo" ]]; then
      git -C "$ROOT/$path" add "$docs/$logo"
    fi
    if git -C "$ROOT/$path" diff --cached --quiet; then
      printf '  %-32s nothing to commit\n' "$r"
    else
      git -C "$ROOT/$path" commit --no-verify -m "docs(theme): sync the shared docfx theme and metadata from bmazzarol/bmazzarol"
      git -C "$ROOT/$path" push origin main
      git -C "$ROOT" add "$path"
      printf '  %-32s docs synced and pushed\n' "$r"
    fi
  done

  if (( drift )) && [[ "$action" == "check" ]]; then
    return 1
  fi
}

cmd_landing() {
  action="${1:-check}"
  script="$ROOT/scripts/apply-landing-copy.py"
  [[ -f "$script" ]] || die "missing landing copy script: $script"
  [[ -f "$LANDING_COPY" ]] || die "missing landing copy: $LANDING_COPY"

  if [[ "$action" == "apply" ]]; then
    for r in $(target_repos); do
      path="$(repo_path "$r")"
      [[ -n "$path" ]] && ensure_main "$path"
    done
    python3 "$script" --write
    for r in $(target_repos); do
      path="$(repo_path "$r")"
      [[ -n "$path" ]] && git -C "$ROOT" add "$path"
    done
    printf '\nSubmodule pointers are staged. Commit them with:\n  git commit -m "chore: bump submodule pointers after landing copy sync"\n'
  else
    python3 "$script" --check
  fi
}

cmd_status() {
  for r in $(target_repos); do
    printf '== %s\n' "$r"
    gh api "repos/$(gh_repo "$r")/actions/runs?per_page=3" \
      --jq '.workflow_runs[] | "  " + .name + " | " + .status + " | " + (.conclusion // "-")' 2>/dev/null
  done
}

# ------------------------------------------------------------------- main ----
need_tools
[[ -f "$CONFIG" ]] || die "missing config: $CONFIG"

args=()
for a in "$@"; do
  case "$a" in
    --dry-run)   DRY_RUN=1 ;;
    --repos=*)   FILTER_REPOS="${a#--repos=}" ;;
    *)           args+=("$a") ;;
  esac
done

cmd="${args[0]:-check}"
rest=()
if (( ${#args[@]} > 1 )); then
  rest=("${args[@]:1}")
fi

case "$cmd" in
  repos)     cmd_repos ;;
  vault)     cmd_vault ;;
  rotate)    cmd_rotate "${rest[0]:-}" ;;
  set)       cmd_set "${rest[0]:-}" "${rest[1]:-}" ;;
  sync)      cmd_sync ${rest[@]+"${rest[@]}"} ;;
  check)     cmd_check ;;
  verify)    cmd_verify ;;
  settings)  cmd_settings ;;
  workflows) cmd_workflows "${rest[0]:-check}" "${rest[1]:-}" ;;
  docs)      cmd_docs "${rest[0]:-check}" ;;
  landing)   cmd_landing "${rest[0]:-check}" ;;
  docs-theme) cmd_docs "${rest[0]:-check}" ;;
  status)    cmd_status ;;
  *)         die "unknown command: $cmd (try repos, vault, rotate, set, sync, check, settings, workflows, docs, status)" ;;
esac
