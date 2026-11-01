# The Shared Theme

Canonical source: `docs/theme/public/main.css` and `docs/theme/public/main.js` in
the root repository. Every docs project gets a generated copy at
`<Docs>/template/public/main.css` and `main.js`.

## Design intent

Quiet chrome, one readable column, structure from type and space. If an element
does not help the reader find something or decide something, it is removed.

## Tokens

```css
:root {
  --bm-measure: 70ch;     /* reading width of the article */
  --bm-radius: 8px;       /* corners on code blocks and cards */
  --bm-muted: var(--bs-secondary-color);
  --bm-rule: var(--bs-border-color);
  --bm-surface: var(--bs-tertiary-bg);
}
```

Use the Bootstrap variables docfx already provides — never hard-code colours, so
dark mode keeps working.

## Selectors you can override

The modern template renders this structure:

```text
header.bg-body            navbar
  nav#autocollapse.navbar
    a.navbar-brand  img#logo
    form.search input#search-query
main.container-xxl
  nav#toc                 left navigation
  div.content
    div.actionbar  nav#breadcrumb
    article
    div.contribution a.edit-link
    div#nextArticle
  div.affix nav#affix      "In this article"
footer
```

Style `article` for prose, not `main`, so the layout stays intact.

## Previewing a change

```bash
./scripts/docs-preview.sh              # build docs/_site
./scripts/docs-preview.sh --serve      # http://localhost:8080
```

Screenshot before and after:

```bash
chromium --headless=new --no-sandbox --screenshot=before.png \
  --window-size=1200,1200 file://$PWD/_site/index.html
```

## Shipping it

```bash
./scripts/ci-sync.sh docs-theme check   # report repos that differ
./scripts/ci-sync.sh docs-theme apply   # copy + commit in each submodule
```

A theme change is staged until the preview site has been reviewed, then rolled
out in one commit per repository.
