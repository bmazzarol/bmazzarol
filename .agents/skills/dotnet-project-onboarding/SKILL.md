---
name: dotnet-project-onboarding
description: Add or restructure a .NET library project under projects/dotnet so it matches the monorepo conventions. Use when creating a project, wiring up its Tests/Docs/Benchmarks projects, solution file, package props, icons, hooks or CI settings.
---

# .NET project onboarding

Every project is a git submodule of this repo, and every one is built by the
same four shared props files. The naming is load-bearing: `Common.Test.props`
and `Common.Benchmark.props` derive the library name from the assembly name with
`$(AssemblyName.Replace('.Tests',''))`, so a project named anything else has no
project reference and silently tests nothing.

Run the audit first, then fix what it reports:

```bash
./.agents/skills/dotnet-project-onboarding/scripts/audit-project.sh Cutout --slnx
```

## The shape of a project

| Piece | Rule |
| --- | --- |
| `Name/Name.csproj` | `netstandard2.0`, imports `Common.Release.props` |
| `Name.Tests/` | imports `Common.Test.props`, `TreatWarningsAsErrors=false` |
| `Name.Docs/` | imports `Common.Docs.props`, holds `docfx.json`, `toc.yml`, `template/public` |
| `Name.Benchmarks/` | imports `Common.Benchmark.props`, optional |
| `Name.Sample/` or `Name.Examples/` | net8+ consumer that proves the API works |
| `Name.slnx` | one `<Folder Name="/Name/">` entry per project |

All shared props are found with
`$([MSBuild]::GetPathOfFileAbove('Common.X.props', '$(MSBuildThisFileDirectory)'))`,
so a project that does not import them is not "different", it is unmanaged.
`projects/dotnet/Internal/` is not a submodule - shared code (e.g.
`SourceGeneratorUtilities`) lives in this repo and is referenced by the projects
that need it.

## Dependencies

`Directory.Packages.props` centrally pins versions. A dependency on another
project in this monorepo is written twice, gated by `BuiltInMonoRepo`:

```xml
<PackageReference Include="Pasted" Condition="$(BuiltInMonoRepo) != 'true'" />
<ProjectReference Include="..\..\Pasted\Pasted\Pasted.csproj"
                  OutputItemType="Analyzer" ReferenceOutputAssembly="false"
                  Condition="$(BuiltInMonoRepo) == 'true'" />
```

Inside the monorepo it is a project reference; in a standalone repo it is a NuGet
package from `Parent.Directory.Packages.props`. Getting this wrong produces a
package that builds here and fails for everyone else.

New package versions go in `Directory.Packages.props` (and
`Parent.Directory.Packages.props`) - never in a `csproj`, because
`ManagePackageVersionsCentrally` is on.

## Adding a project

```bash
./scripts/add-dotnet-project.nu Name           # git submodule add
./scripts/ci-sync.sh workflows apply           # workflows, .husky hooks, markdownlint config
./scripts/ci-sync.sh settings                  # push per-repo variables
./scripts/normalise-icons.py name-icon.png -o docs/theme/images
```

Then register it in `.github/ci/repos.json` (`sonarProjectKey`,
`docsProjectPath`, `csProjFileName`, `markdownGlobs`, `dotnetVersion`) and in
`.github/ci/config/landing-copy.json` (title, tagline, description, package,
icon, `packageReadmes` paths). Without those two entries the project has no CI
identity: workflows skip, docs are not deployed, landing copy is not written.

`global.json` in the project root must contain
`{"test": {"runner": "Microsoft.Testing.Platform"}}` - xUnit v3 here runs on MTP.

Commit messages use scopes `core`, `docs` or `deps` (enforced by commitlint, both
locally through husky and in CI).
