# Ben Mazzarol

Hi there! I'm Ben, a software engineer with a passion for building small
libraries and tools that solve problems that I have run into.

I hope you find something useful in my repositories!
Please contact me if you have any questions or feedback.

## Monorepo

This repository acts as a monorepo for all of my projects. Each project is
a git submodule that can be found in the `projects/` directory.

This allows me to manage all of my projects in one place, while still keeping
them separate and independent. It makes updating dependencies and other
chores much easier for me.

It also allows me to enforce a degree of consistency across all of my projects,
such as using the same linters, formatters, and CI/CD pipelines.

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
all live in this repository and are copied out to the projects:

- [Documentation style guide](https://bmazzarol.github.io/bmazzarol/articles/documentation-style-guide.html)
- [The theme](https://bmazzarol.github.io/bmazzarol/articles/theme.html)
- [Shared CI](https://bmazzarol.github.io/bmazzarol/articles/shared-ci.html)
- `./scripts/ci-sync.sh` - writes the shared configuration into every project

Contributing is still expected to be done on a per-project basis, using the
well-known GitHub workflow.
