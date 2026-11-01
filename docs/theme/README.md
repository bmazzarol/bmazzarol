# Docfx theme

This is the canonical theme for every docfx site in the monorepo. Projects do
not edit their own copy; `ci-sync.sh docs apply` copies these files into
`<Docs>/template/public`.

```text
public/main.css    layout, typography, code, tables
public/main.js     nav icon links
public/fonts/      self-hosted web fonts
```

## Fonts

| Font | Weights | File | Size |
| --- | --- | --- | --- |
| Inter | 400-700 (variable) | `public/fonts/inter-latin.var.woff2` | 37 KB |
| JetBrains Mono | 400-600 (variable) | `public/fonts/jetbrains-mono-latin.var.woff2` | 30 KB |

Both are SIL Open Font License 1.1, © the respective authors:

- Inter - © Orling (Figma Inc.)
- JetBrains Mono - © JetBrains

Only the Latin subset is shipped; it covers everything the documentation needs.
To refresh a font, download the variable woff2 from Google Fonts and replace the
file in place, keeping the same name.
