---
name: docfx-docs
description: Write, review and ship docfx documentation for the bmazzarol monorepo. Use when creating or improving docs sites, articles, TOCs, README copy, docfx themes, or GitHub Pages documentation for a .NET project.
---

# Docfx documentation

You are writing documentation for a family of small .NET libraries. Every docs
site in this monorepo is docfx 2.78.4, published to GitHub Pages at
`https://bmazzarol.github.io/<repo>`, and shares one theme.

Read `references/style-guide.md` before writing copy. Read
`references/docfx-cheatsheet.md` before changing `docfx.json`, `toc.yml` or the
template. Read `references/theme.md` before touching CSS or JS.

## The rule

Documentation is a route to a result. A page must answer, in order:

1. What is this, and why does it exist?
2. How do I use it in thirty seconds?
3. What are the edges — limits, failure modes, alternatives?

If a page answers only (2), it is a code snippet with a heading. If it answers
only (1), it is a manifesto.

## Working on a docs site

A docs project lives at `projects/dotnet/<repo>/<Name>.Docs/` and is built by
`Common.Docs.props` during `dotnet build`:

```text
docfx.json                 build config, template list, global metadata
toc.yml                    the reader's path through the site
index.md                   the landing page
articles/                  one article per concept
images/                    icons and diagrams
template/public/main.css   the shared theme (generated, do not hand edit)
template/public/main.js    shared nav icon links (generated)
```

Build and inspect locally:

```bash
cd projects/dotnet/<repo>/<Name>.Docs
dotnet tool restore
dotnet docfx build docfx.json --warningsAsErrors
```

The output is in `_site/`. To look at it with a real browser:

```bash
python3 -m http.server 8080 --directory _site
```

## Editing copy

- Second person, present tense, active voice.
- Short sentences. One idea per paragraph.
- Name things after what they do, not after what the type is called.
- Never use "powerful", "seamless", "robust", "easy" — show instead.
- Every code example compiles, runs, and shows its output.
- Put the shortest working example before any explanation of internals.
- A "what this does not do" section is required for anything with limits.

## Changing the theme

Never edit a project's `template/public/main.css` directly. The theme is
generated from the root repository:

```bash
./scripts/ci-sync.sh docs check      # which repos differ from the canonical theme/metadata
./scripts/ci-sync.sh docs apply      # copy theme and merge metadata, commit per repo
```

Preview first:

```bash
./scripts/docs-preview.sh --serve        # http://localhost:8080
```

Take a screenshot of the staging site before and after a change, and compare
them. A theme change ships only after the staging site has been reviewed.

## Before you finish

- [ ] First paragraph explains the library without reading code.
- [ ] First code block runs standalone and shows output.
- [ ] Every article appears in `toc.yml`, ordered by learning sequence.
- [ ] `docfx build --warningsAsErrors` is clean.
- [ ] `markdownlint-cli2` reports no errors.
- [ ] Page is legible in dark mode.
- [ ] No badge, banner or decoration that does not help the reader.
