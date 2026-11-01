---
name: dotnet-build-and-test
description: Build, format, test and benchmark the .NET projects in this monorepo. Use when running tests locally, reading CI test output, writing xUnit v3 tests, using Bunsen Burner AAA/BDD syntax, or running BenchmarkDotNet benchmarks.
---

# Build, test, benchmark

The local SDK here is 10.0.403; CI installs the channel in `DOTNET_VERSION`
(11.0.x). A build that passes locally can still fail in CI, so reproduce CI
failures against the same commands, not against the whole solution.

## The loop

Run from the project root, e.g. `projects/dotnet/Cutout`:

```bash
dotnet tool restore
dotnet csharpier format .                     # CI runs `csharpier check .`
dotnet build --configuration Release          # library, tests, docs, benchmarks
dotnet test                                     # all test projects
dotnet test Cutout.Tests/Cutout.Tests.csproj    # one project
```

Docs are built by an MSBuild target in `Common.Docs.props`, not by a docfx
command you invoke yourself:

```bash
dotnet build Cutout.Docs/Cutout.Docs.csproj    # runs docfx with --warningsAsErrors
```

## What CI actually runs

```bash
dotnet test -- -ignore-exit-code 8 --coverage --coverage-output-format xml \
  --coverage-output coverage.xml --report-xunit-trx \
  --report-xunit-trx-filename test-results.trx --report-xunit --report-xunit-filename report.xml
```

`coverage.xml` and `test-results.trx` are uploaded as artifacts and consumed by
SonarCloud. Test projects target `net10.0` and are marked `SonarQubeExclude`.

## xUnit v3 on Microsoft Testing Platform

- `global.json` sets `"runner": "Microsoft.Testing.Platform"`, so test projects
  are executables (`OutputType=Exe`) rather than VSTest assemblies.
- Tests may return `Task`; there is no void test. `Assert` throws, so a test
  body that does not assert anything trips `S2699`.
- MTP flags come after `--`. Exit code 8 is not a test failure - it is why CI
  passes `-ignore-exit-code 8`.
- Async work should honour the test cancellation token:
  `TestContext.Current.CancellationToken`.
- `Common.Test.props` adds a global `using Xunit;`, so test files do not import it.

Write tests with Bunsen Burner's arrange-act-assert DSL - see
`references/bunsenburner.md`. It disposes everything the arrange and act stages
create, which is the reason the repo uses it.

## Benchmarks

```bash
dotnet run --project Icicle.Benchmarks -c Release
```

`Common.Benchmark.props` gives BenchmarkDotNet plus `DotTraceDiagnoser`, and
benchmarks are excluded from Sonar and coverage. Snapshots land in `artifacts/`.

## Before you finish

- [ ] `dotnet csharpier check .` reports no files needing formatting.
- [ ] `dotnet test` is green, including Verify snapshots.
- [ ] The docs project builds (it runs docfx with `--warningsAsErrors`).
- [ ] Nothing in the change breaks the `netstandard2.0` library projects.
