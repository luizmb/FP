---
name: fp-library-contributor
description: Conventions and workflows for changing the FP Swift library itself (this repository, github.com/luizmb/FP), not for using it. Covers the named-function plus operator two-layer split, flipped operator pairs, the Sendable contract, the mandatory split between named-function tests and operator tests, law tests, adding functor / applicative / monad support to a library type, and adding a monad transformer stack through Scripts/GenerateTransformers.swift. Use it whenever you're editing files under Sources/CoreFP, Sources/CoreFPOperators, Sources/DataStructure or Sources/DataStructureOperators, adding a type, an operator overload or a transformer stack (ReaderTX, XTValidation, …), touching the generator or its output, or writing tests in CoreFPTests / CoreFPOperatorsTests / DataStructureTests / DataStructureOperatorsTests.
---

# Contributing to FP

This repo's `CLAUDE.md` and `CONTRIBUTING.md` are the authority; this skill is the working summary plus two step-by-step workflows. If they ever disagree, they win, and this skill should be fixed.

## The rules that every change follows

**Two layers.** Every operation exists as a named function in a core module (`CoreFP`, `DataStructure`) and as an operator in its companion module (`CoreFPOperators`, `DataStructureOperators`). The operator body calls the named function and nothing else. The named function is the semantic layer, so it must make sense on its own (good name, doc comment with the Haskell signature, `@Sendable` closures).

**Module placement.** A type that only involves stdlib / Foundation / Combine types (Array, Optional, Result, functions, Publisher, AsyncStream) goes in `CoreFP`; anything involving `Either`, `Validation`, `Reader`, `Writer`, `Stateful`, `Loading`, `NonEmpty`, … goes in `DataStructure`. `CoreFP` never imports `DataStructure`.

**Flipped pairs, same commit.** `<£>` / `<&>`, `£>` / `<£`, `*>` / `<*`, `>>-` / `-<<`, `>=>` / `<=<`, `->>` / `<<-`, `>>>` / `<<<`, `<|` / `|>`. Adding an overload for one means adding the other, and the flipped one delegates to the forward one with the arguments swapped.

**Naming.** Instance `map` / `flatMap`; static curried `fmap` / `bind`; static `pure`, `apply`, `liftA2`, `kleisli` / `kleisliBack`; `seqRight` / `seqLeft` for `*>` / `<*`; `alt` for `<|>`; `combine` for `<>`. Outgoing conversions are `to…()` methods, incoming ones are `init(_:)`. No `T`-suffixed public names.

**Sendable first.** Algebraic types get `extension X: Sendable where …`. Stored closures and closure parameters are `@Sendable`. `apply` takes the inner function as `@Sendable` (`Either<L, @Sendable (A) -> B>`). Helpers that capture a generic value offer a non-Sendable version and a `<A: Sendable>` overload returning `@Sendable`. `inout` can't be captured in a `@Sendable` closure, so a `Stateful` combinator runs its sub-computations before the `@Sendable` body, left to right. Key paths are lifted with `get(_:)` / prefix `^`, never passed bare.

**Lawful or absent.** No HKT in Swift, so no `Functor` / `Monad` protocols: each type gets concrete members. Only add the surface that satisfies the laws (that's why `Validation` stacks have no monad). Don't propose abstractions that need HKT (Free, Coyoneda, generic Traversable, …).

**Tests, twice.** `CoreFPTests` / `DataStructureTests` test the named functions and must not contain a single custom operator symbol. `CoreFPOperatorsTests` / `DataStructureOperatorsTests` must use the operator symbols and check they agree with the named functions. Both sets are required for every operation; one without the other is a bug. Swift Testing (`@Suite`, `@Test`, `#expect`), and don't name a test after a global FP function (`mconcat`, `sconcat`, …) or Swift resolves the call to the test method.

**Style.** Pure functions (inject dates, randomness and other ambient state as parameters), `Result<Success, SpecificFailure>` over `throws`, no force unwraps and no crash functions outside `fail`. New public API gets a DocC comment.

## Pick the workflow

- Adding or completing functor / applicative / monad support (or `Semigroup`, `Alternative`, comonad) for a type in the library: read `references/new-type.md`.
- Adding a transformer stack (`OuterTInner`), changing what a stack exposes, or touching `Scripts/GenerateTransformers.swift`: read `references/transformer-stack.md`. Never hand-edit anything under `Sources/*/Transformer/Generated/`; the generator wipes those directories on every run.

## Before you say it's done

```bash
swift build 2>&1 | xcsift
swift test 2>&1 | xcsift
mint run swiftformat --lint .
mint run swiftlint lint --strict
mint run periphery scan
```

(`xcsift` is a local convenience; CI runs the bare commands.) Update `CHANGELOG.md` under Unreleased, and the DocC article that covers the area (`OperatorVocabulary`, `MonadTransformers`, the type's own article) when the public surface changes.

## Precedence groups

The operator precedence groups live in `Sources/CoreFPOperators/Utilities/PrecedenceGroups.swift`. Swift only orders two groups when one is reachable from the other through declared `higherThan` / `lowerThan` relations, and from a client module several families are unordered today (for instance `>>-` / `<&>` with `<£>` / `<*>`, and `|>` with almost everything), so mixing them needs parentheses. If you touch the groups, check the result from a separate module that imports `FP`, not only from inside `CoreFPOperators`.
