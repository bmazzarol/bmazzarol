# Shared CI

Every repository in this monorepo runs the same workflows. They are
written once, here in the root repository, and copied out. Nothing is
hand edited in a project repo.

## What is shared

| Thing | Source of truth | How it reaches a project |
| --- | --- | --- |
| Workflow templates | `.github/ci/workflows/` | `ci-sync.sh workflows apply` writes them into `.github/workflows/` |
| Markdownlint config | `.github/ci/config/.markdownlint-cli2.jsonc` | the same command, written to the repo root |
| Husky hooks | `.github/ci/config/husky/` | the same command, written into `.husky/` |
| Composite actions | `.github/actions/` | referenced by every workflow, never copied |
| docfx metadata | `.github/ci/config/docfx-global-metadata.json` | merged into each `docfx.json` by `docs apply` |
| docfx theme | `docs/theme/public/` | copied into each docs project's `template/public` |
| Landing copy | `.github/ci/config/landing-copy.json` | written into each README and each docs `index.md` |
| Project icons | `docs/theme/images/` | copied in by `docs apply` |

The workflows read per-repo values from repository variables
(`SONAR_PROJECT_KEY`, `DOCS_PROJECT_PATH`, `CS_PROJ_FILE_NAME`,
`MARKDOWN_GLOBS`, `DOTNET_VERSION`) instead of hard-coding them, so one
template file works for every repository.

## Checks

Run the drift checks before changing anything:

```bash
./scripts/ci-sync.sh workflows check
./scripts/ci-sync.sh docs check
./scripts/ci-sync.sh landing check
```

Each prints one line per repository. "in sync" means the repo matches the
template; anything else names the file that differs. Fix it with `apply`,
and add `--commit` to commit and push the change in each submodule:

```bash
./scripts/ci-sync.sh workflows apply --commit
./scripts/ci-sync.sh docs apply --commit
./scripts/ci-sync.sh landing apply --commit
```

`apply` pushes the submodule commits and stages the pointer bumps here.
Commit those separately, after the submodules are pushed.

## Secrets

Two secrets are shared: `SONAR_TOKEN` and `NUGET_API_KEY`. They live in
`~/.config/bmazzarol/ci-secrets.env` on the machine that runs the sync,
and are never committed. `ci-sync.sh sync` pushes them to every repo, and
`ci-sync.sh settings` pushes the per-repo variables.

The scheduled `CI Sync` job does this daily. It needs a fine-grained token
stored as `CI_SYNC_TOKEN`, because the default `GITHUB_TOKEN` cannot write
secrets into sibling repositories. Without it the job still reports drift
and skips the pushes.

## What runs in each repo

| Workflow | What it does |
| --- | --- |
| CI Build | builds, runs the tests, uploads the Sonar analysis |
| Test Reporter | turns the CI Build results into a status check |
| Check Code Format | runs CSharpier over the C# sources |
| Check Commit Message | enforces the conventional commit format |
| Check Markdown | runs markdownlint, then a table structure check, over the documentation |
| Check Docs | builds the docfx site with warnings as errors |
| Build and Deploy Docs | publishes the site to GitHub Pages |
| CD Build | packs a release and pushes it to NuGet |

Repos without a docs project skip `Check Docs` and `Build and Deploy Docs`,
as the sync script does when it writes the templates.
