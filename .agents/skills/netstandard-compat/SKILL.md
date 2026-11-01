---
name: netstandard-compat
description: Write library code that compiles under the monorepo's netstandard2.0 floor and warnings-as-errors analyzer settings. Use when editing Cutout, Pasted, Icicle, Eon, Tuxedo, Quacker, Bunsen Burner or Http-BuildR source, or when a build fails with CA, MA or S diagnostics.
---

# netstandard2.0 compatibility

Every library here targets `netstandard2.0` so it works everywhere; the tests,
docs and benchmarks target `net10.0`. That gap is where builds break: code that
compiles in the test project does not compile in the library.

## What is available

| Modern API | Status on netstandard2.0 | What the repo does |
| --- | --- | --- |
| `ValueTask` | absent | `Microsoft.Bcl.AsyncInterfaces` + `ValueTaskSupplement` (Icicle) |
| `Span` / `ReadOnlySpan` | absent | avoid, or use Polyfill extensions |
| records | need a shim | `IsExternalInit` in each project's `Compiler.cs` |
| extension methods on missing types | absent | `Polyfill` (Bunsen Burner, Icicle) |
| `dynamic` | needs the runtime | `Microsoft.CSharp` |

Do not remove `Compiler.cs` from a project because "the shim is built into
modern .NET" - it is guarded by `#if NETSTANDARD2_0 || ...` and is required for
records here.

## Warnings are errors

Library projects set `TreatWarningsAsErrors=true` with `AnalysisMode=Recommended`,
so any CA/MA/S diagnostic stops the build. Test, docs and benchmark projects set
`TreatWarningsAsErrors=false`.

The severities that have been deliberately relaxed live in `.globalconfig` in
each repo, copied from `projects/dotnet/.globalconfig.shared`:

```ini
dotnet_diagnostic.MA0004.severity = none   # ConfigureAwait(false)
dotnet_diagnostic.MA0048.severity = none   # file name must match type
dotnet_diagnostic.CA1848.severity = none   # logging performance
dotnet_diagnostic.S2699.severity = suggestion  # tests without assertions
dotnet_diagnostic.S1135.severity = suggestion  # TODO tags
```

When a diagnostic is wrong for this codebase, change the severity in
`.globalconfig.shared` and copy it to each repo's `.globalconfig` (ci-sync does
not sync this file yet). Suppress with `NoWarn` only when the rule is genuinely
unfixable - `RS1035;MA0037` in the generator projects is the accepted pattern.

## Async style

`Icicle` and `Bunsen Burner` return `Task`/`ValueTask` from netstandard2.0 code.
Do not add `ConfigureAwait(false)`; the rule is silenced deliberately because
these are libraries, not applications.
