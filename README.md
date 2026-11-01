# Ben Mazzarol

I build small .NET libraries and tools that solve problems I ran into. Each one
is its own repository, documented with docfx and published to GitHub Pages.

## Monorepo

Every project is a git submodule under `projects/`. The repositories stay
independent, but this one holds the CI templates, docfx theme, git hooks and
documentation conventions they share, so a change to a lint rule, a workflow or
the theme reaches every project in one commit.

Contributing is still per project, using the usual GitHub workflow.

## Projects

| Project | What it is | Documentation |
| --- | --- | --- |
| [Bunsen Burner](https://github.com/bmazzarol/Bunsen-Burner) | arrange/act/assert testing in plain C# | [docs](https://bmazzarol.github.io/Bunsen-Burner/) |
| [Cutout](https://github.com/bmazzarol/Cutout) | source generated templating | [docs](https://bmazzarol.github.io/Cutout/) |
| [Eon](https://github.com/bmazzarol/Eon) | schedules as data | [docs](https://bmazzarol.github.io/Eon/) |
| [Http BuildR](https://github.com/bmazzarol/Http-BuildR) | request and response builders | [docs](https://bmazzarol.github.io/Http-BuildR/) |
| [Icicle](https://github.com/bmazzarol/Icicle) | structured concurrency | [docs](https://bmazzarol.github.io/Icicle/) |
| [Pasted](https://github.com/bmazzarol/Pasted) | text files baked into the binary | [docs](https://bmazzarol.github.io/Pasted/) |
| [Polyglot Notebook docfx Plugin](https://github.com/bmazzarol/Polyglot.Notebook.Docfx.Plugin) | notebooks that become documentation | [docs](https://bmazzarol.github.io/Polyglot.Notebook.Docfx.Plugin/) |
| [Tuxedo](https://github.com/bmazzarol/Tuxedo) | refined types from predicates | [docs](https://bmazzarol.github.io/Tuxedo/) |
| [docfx result snippets](https://github.com/bmazzarol/docfx.result-snippets) | executed output in a docfx page | [docs](https://bmazzarol.github.io/docfx.result-snippets/) |
| [Quacker](https://github.com/bmazzarol/Quacker) | compile time duck typing | - |

## Tooling

The CI templates, the docfx theme, the hooks and the documentation style guide
live in this repository and are copied out to the projects:

- [Documentation style guide](https://bmazzarol.github.io/bmazzarol/articles/documentation-style-guide.html)
- [The theme](https://bmazzarol.github.io/bmazzarol/articles/theme.html)
- [Shared CI](https://bmazzarol.github.io/bmazzarol/articles/shared-ci.html)
- `./scripts/ci-sync.sh` - writes the shared configuration into every project
