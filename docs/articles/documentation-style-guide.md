# Documentation Style Guide

Documentation is not a description of the code. It is a route to a result. Every
page should move the reader from "I have this problem" to "I have solved it, and
I understand why it works".

## The three questions

Before a page is finished, it should answer, in this order:

1. **What is this, and why does it exist?** One or two sentences, before any code.
2. **How do I use it in thirty seconds?** The shortest complete working example.
3. **What are the edges?** Options, limits, failure modes, and what to do when it
   does not behave as expected.

A page that answers only the second question is a code snippet with a heading. A
page that answers only the first is a manifesto.

## Structure of a project site

Every docfx site in this monorepo has the same skeleton:

```text
index.md            what the library is, in plain language
articles/
  getting-started.md  install, first example, expected output
  <concept>.md       one article per idea the reader must hold in their head
toc.yml             the reader's path through those articles
api/                generated reference, not written by hand
```

The table of contents is a learning path, not a file listing. Order it by the
order a person needs to learn things, not by the order the source files appear.

## Voice

- Write in the second person: "you pass a strategy", not "the user passes a
  strategy".
- Prefer short sentences. If a sentence needs a comma to be understood, split it.
- Name things after what they do. `TryThenCatch` is clearer than
  `StrategyHandler`.
- Present tense, active voice: "the generator emits the code", not "the code is
  emitted by the generator".
- Never use a word that exists only because the API has it. If a type is called
  `IResult`, explain what it means before using it.
- No marketing. "Powerful", "seamless" and "robust" tell the reader nothing.

## Code examples

An example is a claim that the code works. Treat it as a test.

- Every example compiles and runs. Where possible, the executed result is shown
  in the page using the result-snippets plugin.
- Show the output. A reader who cannot see what the code produces has to run it
  to learn anything.
- Keep the example to the shortest thing that still proves the point. Cut imports,
  boilerplate and unrelated setup.
- Use `csharp` fences, and name variables the way you would want them named in
  a real program.
- One idea per example. If an example demonstrates two things, split it.

## Headings and prose

- A heading is a promise. The section under it must deliver exactly that promise.
- `H1` is the page title, `H2` is a concept, `H3` is a detail of that concept. Do
  not skip levels.
- One paragraph per idea. A paragraph that ends with "however" probably contains
  two ideas.
- Lists are for things the reader will scan. Prose is for things the reader needs
  to follow in sequence.

## Before you publish

- [ ] The first paragraph says what the library is without reading the code.
- [ ] The first code block runs on its own.
- [ ] The example shows its output.
- [ ] There is a "what this does not do" section for anything with limits.
- [ ] `dotnet docfx build docfx.json --warningsAsErrors` is clean.
- [ ] `markdownlint-cli2` reports no errors.
- [ ] Every link in the toc resolves, and every article is in the toc.
- [ ] The page reads well in dark mode as well as light mode.
