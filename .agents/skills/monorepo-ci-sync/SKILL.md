---
name: monorepo-ci-sync
description: Operate the shared CI, secrets, docfx theme, icons and landing copy for every repo under projects/dotnet. Use when a workflow, secret, lint rule, theme or landing page needs changing, when drift checks fail, or when submodule pointers need bumping.
---

# Monorepo CI sync

Ten repositories are managed from this one. Nothing is hand edited in a project
repo: the root repo is the source of truth and `scripts/ci-sync.sh` copies it
out. Changing a project file by hand creates drift that the next sync overwrites.

| Thing | Source of truth | How it reaches a project |
| --- | --- | --- |
| Repo list and settings | `.github/ci/repos.json` | repository variables |
| Workflow templates | `.github/ci/workflows/` | `ci-sync.sh workflows apply` |
| Composite actions | `.github/actions/` | referenced by every workflow, never copied |
| docfx theme | `docs/theme/public/` | `ci-sync.sh docs apply` |
| docfx metadata | `.github/ci/config/docfx-global-metadata.json` | merged into each `docfx.json` by `docs apply` |
| Landing copy | `.github/ci/config/landing-copy.json` | `landing apply` rewrites README, docs index and NuGet README |
| Icons | `docs/theme/images/` | copied by `docs apply` |
| Git hooks | `.github/ci/config/husky/` | written into each `.husky/` |
| Secrets | `~/.config/bmazzarol/ci-secrets.env` (never committed) | `ci-sync.sh sync` |

## Always check first

```bash
./scripts/ci-sync.sh repos          # what is managed and its settings
./scripts/ci-sync.sh check          # secret/variable drift
./scripts/ci-sync.sh workflows check
./scripts/ci-sync.sh docs check     # theme and metadata drift
./scripts/ci-sync.sh landing check
./scripts/ci-sync.sh status         # last workflow run per repo
```

Then repair with `apply` (`--dry-run` shows the writes without performing them):

```bash
./scripts/ci-sync.sh workflows apply --commit   # copies workflows, hooks and markdownlint config
./scripts/ci-sync.sh docs apply                 # copies theme, merges metadata, commits
./scripts/ci-sync.sh landing apply              # rewrites README, docs index, NuGet README
```

`workflows apply` only writes files; it commits and pushes when `--commit` is
passed. `docs apply` and `landing apply` commit in the submodule themselves.

## Rules that are not obvious

- **Workflows are byte identical across repos.** Per-repo values
  (`SONAR_PROJECT_KEY`, `DOCS_PROJECT_PATH`, `CS_PROJ_FILE_NAME`,
  `MARKDOWN_GLOBS`, `DOTNET_VERSION`) come from repository variables, so a
  difference between two repos is a `repos.json` edit, not a workflow edit.
- **Globs are ordered.** markdownlint negations only remove files already
  included, so put includes first and the `!` exclusions last.
- **Fork pull requests cannot read secrets or variables.** CI deliberately
  skips Sonar and docs checks with a warning in that case; that is correct, not
  a bug to fix.
- **Submodule pointer bumps are a separate commit.** `apply --commit` pushes the
  submodule commits and stages the pointer changes here; commit those in this
  repo afterwards, with `chore: bump submodule pointers ...`.
- **Sync commits use `--no-verify`,** so commitlint never sees them. Write the
  message yourself in conventional form (`ci:`, `docs:`, `chore:`).
- **The daily CI Sync job needs `CI_SYNC_TOKEN`** (fine-grained PAT with secrets
  read/write on the project repos). Without it the job reports drift and stops.
- **Never edit a project's `template/public/main.css` or `main.js`.** They are
  generated from `docs/theme/public`; the next `docs apply` discards the edit.

## Secrets

```bash
./scripts/ci-sync.sh vault            # keys present, values masked
./scripts/ci-sync.sh rotate SONAR_TOKEN
./scripts/ci-sync.sh set NUGET_API_KEY <key>
./scripts/ci-sync.sh sync             # push every value to every repo
./scripts/ci-sync.sh verify           # confirm SonarCloud accepts the token
```

Values are stored in the vault file or taken from the environment. Only
`SONAR_TOKEN` and `NUGET_API_KEY` are shared; anything else belongs in the
repo's own secrets.

## Before you finish

- [ ] All four `check` commands exit clean.
- [ ] The change was made in the root repo, not in a submodule file.
- [ ] Submodule commits are pushed and the pointer bump is committed here.
- [ ] `./scripts/ci-sync.sh status` shows the workflows running in each repo.
