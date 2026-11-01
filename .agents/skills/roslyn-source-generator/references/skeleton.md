# Generator skeleton

The shape every generator in this monorepo follows (`Cutout/TemplateSourceGenerator.cs`
is the full version).

```csharp
namespace MyProject;

#pragma warning disable RS1038
[Generator]
#pragma warning restore RS1038
public sealed class MyGenerator : IIncrementalGenerator
{
    public void Initialize(IncrementalGeneratorInitializationContext context)
    {
        // 1. Boilerplate that every generated file needs: attributes, helpers.
        context.RegisterPostInitializationOutput(ctx =>
            ctx.AddSource("MyAttribute.g", EmbeddedFiles.MyAttribute_Source));

        // 2. A provider that narrows syntax cheaply, then builds a model.
        //    The first lambda must be cheap - it runs on every node.
        var models = context.SyntaxProvider
            .ForAttributeWithMetadataName("MyProject.MyAttribute",
                (node, _) => node is MethodDeclarationSyntax,
                (ctx, _) => BuildModel(ctx.Target, ctx.Attributes))
            .Collect();

        // 3. Emit one source file per model.
        context.RegisterSourceOutput(models, (sp, model) =>
            sp.EmitSource($"{model.TypeName}.g", Render(model)));
    }
}
```

Three details that decide whether the generator is incremental:

- **Cheap filter, expensive transform.** `ForAttributeWithMetadataName`'s filter
  runs on every syntax node; put the real work in the transform.
- **Cacheable values only.** The transform must return immutable, comparable
  data. Returning a `SyntaxNode` or a mutable object defeats caching and the
  generator re-runs on unrelated edits.
- **Read inputs through providers.** `context.AdditionalTextsProvider` and
  `context.AnalyzerConfigOptionsProvider` are the only tracked ways to get
  files and `.editorconfig` values. `File.ReadAllText` in a generator is the
  RS1035 warning, and it makes the generator non-incremental.

Emitting code that references a type the compilation does not yet have is a
compile error in the consumer, not in the generator. That is why the shared
support types (`TemplateAttribute`, `RenderUtilities`) are emitted in
`RegisterPostInitializationOutput` before any consumer code is generated.
