# The Documentation Theme

All docfx sites in this monorepo share one theme. It is deliberately quiet: the
nav is a thin rule, the article is a single column at a comfortable reading
width, and headings and spacing carry the structure instead of colour.

## Where the theme lives

The canonical copy of the theme is in the root repository:

```text
docs/theme/public/main.css   layout, typography, code, tables
docs/theme/public/main.js    nav icon links (GitHub, home)
```

Each project keeps a local copy under its own docfx template:

```text
<project>.Docs/template/public/main.css
<project>.Docs/template/public/main.js
```

That copy is generated, not hand edited. Changes go in `docs/theme` first, then
get applied to every project with:

```bash
./scripts/ci-sync.sh docs-theme check
./scripts/ci-sync.sh docs-theme apply
```

`apply` commits the change in each submodule with a `docs(theme):` message, so a
theme rollout is one reviewable commit per repository.

## Previewing before it ships

Never push a theme change straight to the project sites. Build the staging site
first and look at it:

```bash
./scripts/docs-preview.sh            # build docs/_site
./scripts/docs-preview.sh --serve    # build and serve on http://localhost:8080
```

The staging site uses the same theme files that will be copied to the projects,
so what you see locally is exactly what will ship.

## What the theme changes

| Area | Behaviour |
| --- | --- |
| Article | single column, capped at 70 characters |
| Navigation | transparent bar, 1.75rem logo, thin bottom rule |
| Headings | size and weight only, no borders or background |
| Code blocks | subtle surface, rounded, monospace at 0.875rem |
| Tables | hairline rules, muted header text |
| Footer | quiet surface band |
| Dark mode | inherits docfx/Bootstrap tokens, no extra work |

Design rule: if an element does not help the reader find something or decide
something, remove it.
