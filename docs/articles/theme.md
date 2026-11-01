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
./scripts/ci-sync.sh docs check
./scripts/ci-sync.sh docs apply
```

`apply` copies the theme and merges the shared docfx metadata into each project's
`docfx.json`, then commits in each submodule with a `docs(theme):` message, so a
theme rollout is one reviewable commit per repository.

## Chrome decisions

Shared docfx behaviour lives in `.github/ci/config/docfx-global-metadata.json`
and is merged into each project's `globalMetadata`.

| Element | Decision | Reason |
| --- | --- | --- |
| Breadcrumbs | off | these sites are five to ten pages deep with a linear toc, the trail adds nothing |
| toc filter box | off | filtering a five-item sidebar is pointless, search already exists |
| "In this article" | on, restyled | concept articles are long, a heading list is real help |
| Next/previous article | on | the toc is a learning path, people read it end to end |
| Site search | on | valuable once the API reference is generated |
| "Edit this page" | on | one quiet link, useful for contributions |
| Badge shields | removed from doc landing pages | status belongs in the README, not in the article |

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
| Typography | Inter for prose, JetBrains Mono for code, both self-hosted (~67 KB total) |
| Article | single column, capped at 70 characters |
| Navigation | transparent bar, 1.75rem logo, thin bottom rule |
| Headings | size and weight only, no borders or background |
| Code blocks | subtle surface, rounded, monospace at 0.875rem |
| Tables | hairline rules, muted header text |
| Footer | quiet surface band, links back to the profile site |
| Dark mode | inherits docfx/Bootstrap tokens, no extra work |

## Icons

Project icons are normalised so every logo sits in the same box: transparent
padding is trimmed, the artwork is scaled so its longest side fills a 128x128
canvas, and it is centred with 6px of breathing room. Without this, the glue
stick renders half the size of the notebook and the navbar looks uneven.

Canonical icons live in `docs/theme/images` and are copied into each project's
`<Docs>/images` by `docs apply`:

```bash
./scripts/normalise-icons.py <png...> -o docs/theme/images
```

Design rule: if an element does not help the reader find something or decide
something, remove it.
