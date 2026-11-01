# docfx Cheatsheet

Version in use across the monorepo: **docfx 2.78.4** (local tool manifest in
`<Docs>/.config/dotnet-tools.json`).

## docfx.json anatomy

```json
{
  "build": {
    "content": [
      { "files": ["articles/**.md", "articles/**/toc.yml", "toc.yml", "*.md"] }
    ],
    "resource": [{ "files": ["images/**", "examples/**"] }],
    "output": "_site",
    "template": ["default", "modern", "template"],
    "globalMetadata": { ... },
    "markdown": { "properties": {} }
  }
}
```

The docs project itself is a `.csproj` that imports `Common.Docs.props`, which
runs `dotnet tool restore`, `docfx metadata` and `docfx build --warningsAsErrors`
after the C# build.

## Useful global metadata

| Key | Effect |
|---|---|
| `_appName` | text next to the logo in the navbar |
| `_appTitle` | appended to every page title |
| `_appLogoPath` | logo image (relative to the docs folder) |
| `_appLogoUrl` | where the logo links to |
| `_appFaviconPath` | favicon |
| `_appFooter` | footer HTML |
| `_enableSearch` | lunr search (default true when an index is produced) |
| `_disableNavbar` | removes the top navigation |
| `_disableToc` | removes the left navigation |
| `_disableAffix` | removes the "In this article" panel |
| `_disableBreadcrumb` | removes breadcrumbs |
| `_disableNextArticle` | removes the next/previous footer |
| `_disableContribution` | removes "Edit this page" |
| `_noindex` | keep the page out of the search index |
| `_lang` | language for template strings |

For a minimal site, `_disableBreadcrumb` and `_disableAffix` are the two that
change the feel most.

## Table of contents

`toc.yml` is a simple YAML tree. Items can point at a file, an external URL, or a
container:

```yaml
items:
  - name: Getting started
    href: articles/getting-started.md
  - name: Concepts
    items:
      - name: Schedules
        href: articles/schedules.md
  - name: API reference
    href: api/
```

Order the toc by the sequence a person needs to learn, not by file order.

## Cross references

Reference API types with `@` syntax once an xref map is available:

```markdown
See the [@System.Threading.Tasks.Task](xref:System.Threading.Tasks.Task).
```

Microsoft's map can be pulled in with:

```json
"xref": ["https://learn.microsoft.com/en-us/dotnet/api/xrefmap.yml"]
```

## Markdown extras docfx supports

- Admonitions: `:::note` and `:::warning`.
- Code fences with a title: `::: code-lang=csharp title="Example"`.
- Include syntax for reusing a fragment across pages.

## Building

```bash
dotnet docfx metadata docfx.json          # regenerate api/ metadata
dotnet docfx build docfx.json --warningsAsErrors
```

Always use `--warningsAsErrors` locally so warnings become visible before CI
fails on them.

## Known traps

1. **Docfx 2.78.2 breaks with Polyfill** — it fails compiling `netstandard2.0`
   Polyfill content on the current SDK. The monorepo pins 2.78.4.
2. **Relative image paths** must be under a `resource` glob in `docfx.json`,
   otherwise they are not copied to `_site`.
3. **`_site` is generated** and must stay out of git.
4. **Markdown lint and docfx disagree** — `markdownlint-cli2` globs must list
   includes before exclusions, and `LICENSE.md` / `node_modules` are excluded.
5. **Templates merge in order** — later entries in `template` override earlier
   files with the same name. `default`, then `modern`, then the local `template`.
