# Style Guide

## Voice

| Prefer | Avoid |
|---|---|
| "you pass a strategy" | "the user passes a strategy" |
| "the generator emits the code" | "the code is emitted by the generator" |
| "runs every 15 minutes" | "is configured with a cadence of fifteen minutes" |
| "returns null when not found" | "may potentially return a null value in some cases" |
| "no runtime dependency" | "lightweight and dependency-free" |

Words that never earn their place: powerful, robust, seamless, easy, simple
(unless you are comparing to something specifically harder), advanced, best.

## Page shape

```markdown
# Name

One or two sentences: what it is, and the problem it removes.

## Why this exists
The concrete problem, in a sentence or two. Optionally show the bad version of
the code.

## How it works
The smallest working example, then the output it produces.

## What it does not do
Limits, edge cases, and what to reach for instead.

## See also
Links to the API reference and related articles.
```

## Headings

- `H1` page title only.
- `H2` a concept the reader must understand.
- `H3` a detail of that concept.
- Never skip a level. A heading is a promise; the section under it must keep it.

## Code examples

- Must compile. Must run. Must show output.
- Shortest version that proves the point. Drop imports and boilerplate.
- One idea per example.
- Use meaningful variable names; never `foo`, `bar`, `temp`.
- Cite versions when behaviour changed.

## Lists versus prose

Use a list when the reader will scan. Use prose when order matters. A list of
three items where the second depends on the first is prose.

## Common failures

1. **The cliff** — the page explains a concept for three paragraphs and the first
   example is on the next page. Put the example first.
2. **The glossary trap** — using API names as if the reader already knows them.
   Introduce a type the first time it appears.
3. **The missing negative** — no page says what the library does not do.
4. **Badge noise** — shields and status images on the landing page. Move them to
   a compact line or drop them; the README can carry them.
5. **TOC as a file listing** — the toc should read as a learning path.
