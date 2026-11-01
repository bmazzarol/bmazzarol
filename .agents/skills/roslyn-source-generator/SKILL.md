---
name: roslyn-source-generator
description: Write, test and package Roslyn source generators for Cutout, Pasted, Tuxedo and Quacker. Use when adding a generator, changing generated output, debugging generated code, or fixing Verify generator snapshots.
---

# Source generators

Five projects here are generators: `Cutout`, `Pasted`, `Tuxedo.SourceGenerator`,
`Quacker`, and the shared `Internal/SourceGeneratorUtilities`. They are the
hardest part of the monorepo because a generator's failure is usually invisible
until a consumer compiles.

## Non-negotiable settings

```xml
<TargetFramework>netstandard2.0</TargetFramework>   <!-- generators run in the compiler, which is netstandard -->
<IsRoslynComponent>true</IsRoslynComponent>
<EnforceExtendedAnalyzerRules>true</EnforceExtendedAnalyzerRules>
<NoWarn>RS1035;MA0037</NoWarn>                      <!-- RS1035: generator may not use System.IO; MA0037 is noise here -->
<EmitCompilerGeneratedFiles>true</EmitCompilerGeneratedFiles>
```

Implement `IIncrementalGenerator`, never the deprecated `ISourceGenerator`.

Templates are inputs, not source: they are `AdditionalFiles`
(`*.Source.cs`, `*.liquid`) and must be read through the provider, never with
`File.ReadAllText`, which breaks incremental caching and is what RS1035 is
warning about.

## Packaging

A generator is only useful if it lands in the analyzer folder:

```xml
<None Include="$(OutputPath)\$(AssemblyName).dll" Pack="true" PackagePath="analyzers/dotnet/cs" Visible="false" />
```

Missing that line produces a package that installs, resolves, and does nothing -
the most expensive bug in this repo, because it only shows up in a consumer
build.

Consumers wire it up with:

```xml
<ProjectReference Include="..\Cutout\Cutout.csproj"
                  OutputItemType="Analyzer" ReferenceOutputAssembly="false" />
```

Test projects keep `ReferenceOutputAssembly="true"` so they can inspect the
generator's types.

## Testing

Snapshot the generated code with `Verify.SourceGenerators`; a `ModuleInit` with
`[ModuleInitializer] public static void Init() => VerifySourceGenerators.Initialize();`
is required in every test project that uses it. Snapshots are named
`<TestClass>.<Case>#<TypeName>.g.verified.cs`, and there are as many as there
are generated types - one per type. When a generator change is intended, run the
test, read the `.failed` file, and accept it by renaming. Never hand edit a
`.verified.cs`.

See `references/skeleton.md` for the generator shape used across these projects.

## Debugging

Build with `EmitCompilerGeneratedFiles` and read `obj/generated/`. If generated
code does not appear at all, the generator is not registered (wrong reference
type), not running (no matching syntax), or silently throwing - a generator
exception aborts the compilation with no message.

## Before you finish

- [ ] The dll is packed into `analyzers/dotnet/cs`.
- [ ] Every generated type has a Verify snapshot, and the snapshots are clean.
- [ ] A consumer project (`*.Sample` or `*.Examples`) compiles against the new output.
- [ ] `dotnet build` of the library is warning free - `TreatWarningsAsErrors` is on.
