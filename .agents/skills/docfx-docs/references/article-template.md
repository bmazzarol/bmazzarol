# Article Templates

## Landing page (`index.md`)

````markdown
# <Library name>

![<Library name>](images/<icon>.png)

**<Playful tagline, six words or fewer.>**

<What it is, one sentence. The problem it removes, one sentence.>

```shell
dotnet add package <package>
```

## Get started

<install line>

<the shortest program that does the thing>

<the output it produces>

## Why this exists

<the bad version of the code, then the good version>

## What it does not do

<limits, and what to use instead>

## Articles

- [Concept A](articles/concept-a.md)
- [Concept B](articles/concept-b.md)
````

The concept and getting started templates nest fine because they contain no code
fences of their own; the landing page opens with four backticks so the install
block can sit inside it.
sit inside it.

## Concept article (`articles/<concept>.md`)

```markdown
# <Concept>

<Definition in one or two sentences, in plain language.>

## Example

<code, then output>

## Options

<table or list of choices and what each costs>

## When not to use it

<the honest negative>
```

## Getting started (`articles/getting-started.md`)

````markdown
# Getting started

## Install

```bash
dotnet add package <name>
```

## First program

<complete, runnable, with output>

## Next

<two or three links, in the order a reader will need them>
````

Every template keeps the same order: what, then how, then the edges.
