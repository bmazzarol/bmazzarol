# CI settings and secrets sync

Everything the submodule repos need from GitHub (secrets, workflow files,
per-repo settings) lives here in the root repo. The submodule repos stay where
they are; they just receive their configuration from this repo.

## What lives where

| Thing | Source of truth |
| --- | --- |
| Repo list + per-repo settings | `.github/ci/repos.json` |
| Workflow files | `.github/ci/workflows/*.yml` |
| Landing page copy and logos | `.github/ci/config/landing-copy.json` |
| docfx theme (css, js, fonts) | `docs/theme/public` |
| docfx global metadata | `.github/ci/config/docfx-global-metadata.json` |
| Git hooks (husky) | `.github/ci/config/husky/*` |
| Secrets (Sonar, NuGet, ...) | `~/.config/bmazzarol/ci-secrets.env` locally, or this repo's secrets in CI |
| Shared CI actions | `.github/actions/*` |

The workflow templates are identical for every repo. Values that used to be
hard-coded in each repo's workflow (Sonar project key, docs path, markdown
globs) are now read from **repository variables**, so changing them is a
one-line edit in `repos.json` instead of nine file edits.

Repository variables used by the templates:

- `SONAR_PROJECT_KEY`
- `DOCS_PROJECT_PATH`
- `CS_PROJ_FILE_NAME`
- `DOTNET_VERSION` - the .NET SDK channel every workflow installs (currently
  `11.0.x`). `setup-dotnet` resolves the channel to the newest release in it, so
  this picks up 11.0 GA automatically without touching the templates.
- `MARKDOWN_GLOBS` - `markdownlint-cli2` target specs. Ordering matters: negations
  only remove files that were already included, so put includes first and the
  `!` exclusions afterwards.

`.github/ci/config/.markdownlint-cli2.jsonc` is the shared markdownlint config.
`workflows apply` copies it into every repo root, so lint rules are centralised
here too:

- `MD013` (line length) off - docfx articles and tables run long.
- `MD041` (first line must be a heading) off - every landing page starts with the
  project logo, then the title.

The root repo runs the same lint over its own prose with
`.github/workflows/check-markdown.yml`. It excludes `projects/**`, because each
submodule lints itself in its own CI.

`.github/ci/config/husky/` holds the `commit-msg` and `pre-commit` hooks copied
into each repo's `.husky/`. The `task-runner.json` stays per-repo because its
globs and docs paths differ.

`.github/ci/config/landing-copy.json` is the shared hero for every project: the
title, the one line tagline, the description and which icon the project uses.
`landing apply` (see below) rewrites both the README and the docs landing page
from it, so a repo and its docs site always say the same thing. The README keeps
its badge shields, the docs page does not. Docfx sites are markdown
(`index.md`); Polyglot Notebook sites are notebooks (`index.ipynb`), and the
script handles both.

`docs/theme/images` holds the canonical icons, all drawn on the same 128px
canvas by `scripts/normalise-icons.py`. Landing copy copies them into each repo
(root icon and `Docs/images/`) so the logo a repo shows is the logo the theme
shows.

Repository secrets used:

- `SONAR_TOKEN`
- `NUGET_API_KEY`

## The tool

```bash
./scripts/ci-sync.sh repos                  # what is managed, and its settings
./scripts/ci-sync.sh vault                  # which secrets the vault holds
./scripts/ci-sync.sh check                  # drift report (non-zero exit on drift)
./scripts/ci-sync.sh verify                 # confirm SonarCloud accepts the vault's token
./scripts/ci-sync.sh rotate SONAR_TOKEN     # prompt, store, push to every repo
./scripts/ci-sync.sh set NUGET_API_KEY <key>
./scripts/ci-sync.sh sync                   # push every vault value to every repo
./scripts/ci-sync.sh settings               # push repo variables from repos.json
./scripts/ci-sync.sh workflows check        # which repos differ from the templates
./scripts/ci-sync.sh workflows apply        # write templates + shared config into each submodule
./scripts/ci-sync.sh workflows apply --commit   # ...and commit/push + stage pointer bumps
./scripts/ci-sync.sh docs check               # docfx theme + metadata drift per docs project
./scripts/ci-sync.sh docs apply               # sync theme and metadata, commit per repo
./scripts/ci-sync.sh landing check            # which READMEs/docs pages drift from the shared copy
./scripts/ci-sync.sh landing apply            # rewrite them, commit per repo, stage pointer bumps
./scripts/ci-sync.sh status                 # last workflow run per repo
```

Options: `--repos=Tuxedo,Cutout` and `--dry-run`.

## Documentation

The canonical docfx theme and docfx metadata live in the root repo:

```text
docs/                                       the profile site, deployed to GitHub Pages
docs/theme/public/main.css, main.js         shared theme, copied into every docs project
.github/ci/config/docfx-global-metadata.json shared docfx globalMetadata
```

`docs apply` copies the theme into `<Docs>/template/public` and merges the shared
metadata into each `<Docs>/docfx.json`, commits and pushes in the submodule, and
stages the pointer bump. Preview first:

```bash
./scripts/docs-preview.sh --serve   # http://localhost:8080
```

## Rotating the Sonar token

1. Generate a new token at <https://sonarcloud.com/account/authorizations>.
2. `./scripts/ci-sync.sh rotate SONAR_TOKEN`
3. `./scripts/ci-sync.sh verify` - prints `{"valid":true}` from SonarCloud
4. `./scripts/ci-sync.sh check`

GitHub never lets you read a stored secret back, so each key has to be seeded
into the vault once; after that every rotation is one command for all repos.

The vault file is never committed; it is a plain `KEY=value` file with mode
`600`. Override the location with `CI_SECRETS_FILE` if you prefer.

## Adding a repo

1. `scripts/add-dotnet-project.nu <name> <description>` (creates the submodule,
   workflows and docs project).
2. Add an entry to `.github/ci/repos.json`.
3. `./scripts/ci-sync.sh settings` and `./scripts/ci-sync.sh workflows apply`.

## Automated sync

`.github/workflows/ci-sync.yml` runs daily and on demand. It checks out the
submodules and reports workflow, docfx theme and landing copy drift as workflow
warnings, so the scheduled job is useful even before `CI_SYNC_TOKEN` exists.
Secrets are only pushed when `CI_SYNC_TOKEN` (a token with *Secrets: Read & Write*
on the target repos) is set on this repo - the job's built-in `GITHUB_TOKEN`
cannot write secrets into sibling repositories.
