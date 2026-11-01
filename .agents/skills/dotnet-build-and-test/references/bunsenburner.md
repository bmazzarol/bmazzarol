# Bunsen Burner test syntax

```csharp
using static BunsenBurner.ArrangeActAssert;   // or BunsenBurner.GivenWhenThen
```

The chain returns a `Task`, so the test method returns it directly:

```csharp
[Fact(DisplayName = "SerializeAsync works with anonymous objects")]
public Task Example() =>
    Arrange(() => (widget: new { Name = "Widget1", Cost = 12.50 }, ms: new MemoryStream()))
        .Act(async data =>
        {
            await JsonSerializer.SerializeAsync(data.ms, data.widget,
                cancellationToken: TestContext.Current.CancellationToken);
            return Encoding.UTF8.GetString(ms.ToArray());
        })
        .Assert(result => Assert.Equal("{\"Name\":\"Widget1\",\"Cost\":12.5}", result));
```

Rules worth knowing:

- `Arrange` takes a function or a value; `.And` steps transform or assert along
  the way; `Act` produces the result; `Assert` takes the result (or the
  `(data, result)` pair).
- Assertions can be lambdas or expressions: `.Assert((d, r) => r.Length == 2)`
  throws `ExpressionAssertionFailureException` carrying the expression and the
  value, which is why failures read well in the test report.
- Everything arranged and acted on is disposed after the test, in reverse order.
  A disposal you want to verify manually must be done inside the chain:
  `await disposable.Arrange().Act(d => d.IsDisposed).Assert(Assert.False);`
  then assert it is disposed afterwards.
- Given/When/Then is the same machinery with different names; pick one per file
  and put the `using static` in a `#region` so the docs snippet extracts cleanly.

The `Examples/` folders in `BunsenBurner.Tests` are the canonical snippets that
the docfx site embeds; when a docs article shows AAA code, it came from there.
