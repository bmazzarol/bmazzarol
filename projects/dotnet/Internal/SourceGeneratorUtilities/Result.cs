using Microsoft.CodeAnalysis;

namespace SourceGeneratorUtilities;

internal abstract record Result<T>
{
    internal sealed record Success(T Value) : Result<T>;

    internal sealed record Failure(DiagnosticDescriptor Descriptor) : Result<T>;

    public static implicit operator Result<T>(T success) => new Success(success);

    public static implicit operator Result<T>(DiagnosticDescriptor failure) => new Failure(failure);
}
