# Create Monad Transformer

Help add a monad transformer stack (a `ReaderT` like `ReaderTValidation`, or any other `OuterTInner` such as `ArrayTValidation`) to the library. Stacks are generated, so the work is mostly picking the right line in the generator's table, making sure the nested-type functions it delegates to exist, and writing tests.

## Skill Prompt

You are helping a developer add a monad transformer stack following FP library conventions.

### The model

Every stack is its own concrete struct named `OuterTInner` (see `<doc:MonadTransformers>` for the coverage matrix). `ReaderTOptional<Env, A>` wraps `Reader<Env, A?>`, `ArrayTResult<E, A>` wraps `[Result<A, E>]`, `PublisherTOptional<Failure, A>` wraps `AnyPublisher<A?, Failure>`, `AsyncStreamTEither<L, A>` wraps `AsyncStream<Either<L, A>>`. Each struct has:

- `rawValue` (the whole nested value), `init(rawValue:)`, `init(_:)`, typealiases `O` (nested value) and `I` (inner layer), a conditional `Sendable`.
- Functor: `map`, static `fmap`; operators `<£>`, `<&>`, `£>`, `<£`.
- Applicative (unless functor-only): static `pure`, static `apply`, static `liftA2`, `seqRight`, `seqLeft`; operators `<*>`, `*>`, `<*`.
- Monad (lawful monads only, conforming to `MonadT`): `flatMap`, static `bind`, static `kleisli` / `kleisliBack`; operators `>>-`, `-<<`, `>=>`, `<=<`. Applicative-only stacks conform to `TransformerStack`.
- A Haskell-named escape hatch `(O) -> O2`: by the outer layer for Reader / Stateful / streams (`mapReaderT`, `mapStateT`, `mapPublisherT`, `mapAsyncStreamT`), else by the inner layer for Optional / Either / Result / Writer (`mapMaybeT`, `mapExceptT`, `mapWriterT`), else (Compose-like stacks) by the outer layer (`mapArrayT`, `mapOptionalT`, `mapEitherT`, `mapResultT`, `mapNonEmptyT`, `mapValidationT`).
- A lifting property on the outer type, named after it (`reader.readerT`, `array.arrayT`, `publisher.publisherT`, …), constrained by the inner-shape protocol (`extension Reader where Output: ValidationLike`).

Module placement: the struct goes in `CoreFP` when both layers are CoreFP / stdlib types (Array, Optional, Result, Publisher, AsyncStream), otherwise in `DataStructure`; its operators go in the matching operator module. Output lands in `Sources/<Module>/Transformer/Generated/<Stack>.swift` and `Sources/<OperatorModule>/Transformer/Generated/<Stack>+Operators.swift`.

**Never hand-edit anything under `Sources/*/Transformer/Generated/`.** The generator wipes and rewrites those directories on every run.

### What is a monad transformer?

A way to combine two monads into one, when you need both effects at once, e.g. "a dependency-injected computation (`Reader`) that might fail (`Optional`)" is `ReaderTOptional`, not two separate types you juggle by hand.

### Instructions

1. **Check it doesn't exist**: look at `<doc:MonadTransformers>`'s matrix and the `inventory` array in `Scripts/GenerateTransformers.swift`.
2. **Decide the kind**: `.monad` only when the stack has a lawful monad (check the "Why some combos lack a Monad" section: anything with `Validation`, a list inside a non-commutative outer layer, `Writer` outside another monad, a monad outside `Stateful`, or `Stateful` outside Reader / Publisher / AsyncStream is not a monad). Otherwise `.applicative`, or `.functor` when there's no lawful applicative either.
3. **Make sure the nested-type functions exist** (they are the implementation the struct delegates to, and they are `internal`, never public API): the `mapT` method on the outer type, the free `apply<Outer><Inner>`, `liftA2<Outer><Inner>`, `seqRight<Outer><Inner>`, `seqLeft<Outer><Inner>` functions, and for monads the `flatMapT` method. They live next to the outer type (e.g. `Sources/DataStructure/Reader/ReaderTValidation+Functor.swift`). Implement them with the inner type's own `map` / `liftA2` / `flatMap`. If the stack's functions don't follow those names, use an `Override` instead (next step).
4. **Add the table line**: one `Stack(.outer, .inner, kind)` line in `inventory`, in the section for its module/outer type, e.g. `Stack(.reader, .validation, .applicative)`. Add `Override`s only when needed:
   - `.applyViaLiftA2` when there is no `apply<Outer><Inner>` free function (derives `apply` from `liftA2`);
   - `.freeFlatMap` when the bind is a free `flatMapT<Outer><Inner>(_:_:)` instead of a method;
   - `.map(body)`, `.liftA2(body)`, `.flatMap(body)`, `.pure(body)` for a custom member body (e.g. a stream stack whose nested `mapT` returns `AsyncMapSequence`, or a `pure` that must build a fresh stream per run).
5. **A brand-new layer type** (one not in `enum Layer`) needs a `Layer` case: its type spelling, outer/inner context parameters, `outerPure`, module (`isCore`), the lifting extension (`lift`) and, if it can be an inner layer, an inner-shape protocol (`XLike` in `Sources/*/Transformer/InnerShape.swift`: one conformer, identity requirements only, so lifting never copies) plus its `shape` entry.
6. **Run the generator** from the package root, then lint:
   ```bash
   swift Scripts/GenerateTransformers.swift
   mint run swiftformat --lint .
   swift build 2>&1 | xcsift
   ```
   Commit the script change and the regenerated sources together.
7. **`Sendable`-first**: the generated members already require `Sendable` context parameters and `@Sendable` closures. Your nested functions must do the same. `inout` state can't be captured in a `@Sendable` closure: when a `Stateful` combinator runs several sub-`Stateful`s, evaluate them before the `@Sendable` body, in left-to-right applicative order.
8. **Tests in both targets** (`DataStructureTests` + `DataStructureOperatorsTests`, or `CoreFPTests` + `CoreFPOperatorsTests`), written against the struct API only (never the internal nested functions):
   - named tests use `map` / `apply` / `liftA2` / `flatMap` / `kleisli` / the escape hatch / the lifting property, no operator symbols; verify functor / applicative / monad laws by comparing `rawValue`s (run them for function-like layers);
   - operator tests use the symbols (`<£>`, `<*>`, `*>`, `>>-`, `>=>`, …) and check they agree with the named members.

### Test sketch

`DataStructureTests` (named, no operator symbols):
```swift
import CoreFP
import DataStructure
import Testing

@Suite("ReaderTValidation")
struct ReaderTValidationTests {
    struct Env: Sendable { let limit: Int }

    @Test func mapReachesTheInnerValue() {
        let stack = Reader<Env, Validation<[String], Int>> { .success($0.limit) }.readerT
        let mapped = stack.map { $0 * 2 }.rawValue
        #expect(mapped(Env(limit: 5)) == .success(10))
    }

    @Test func applyAccumulatesErrors() {
        let ff = ReaderTValidation<Env, [String], @Sendable (Int) -> Int>(Reader { _ in .failure(["f"]) })
        let fa = ReaderTValidation<Env, [String], Int>(Reader { _ in .failure(["a"]) })
        #expect(ReaderTValidation.apply(ff, fa).rawValue(Env(limit: 0)) == .failure(["f", "a"]))
    }
}
```

`DataStructureOperatorsTests` (must use the operator symbol):
```swift
import CoreFPOperators
import DataStructure
import DataStructureOperators
import Testing

@Suite("ReaderTValidation operators")
struct ReaderTValidationOperatorsTests {
    struct Env: Sendable { let limit: Int }

    @Test func fmapOperatorDelegatesToMap() {
        let stack = Reader<Env, Validation<[String], Int>> { .success($0.limit) }.readerT
        let env = Env(limit: 3)
        #expect(({ $0 + 1 } <£> stack).rawValue(env) == stack.map { $0 + 1 }.rawValue(env))
    }
}
```

(Adapt equality to the types involved; `Validation` and `Either` are `Equatable` when their parameters are.)

### Special considerations

- **Streams (Publisher, AsyncStream)**: applicatives are `ap` derived from the ordered-concat bind (each left element over the whole right stream), never zip. The right stream is single-pass and gets buffered with `AsyncStream.replayable(_:)`. A `pure` inside a function-like outer layer (`Reader`, `Stateful`) must build a fresh stream per run. Availability annotations and `#if canImport(Combine)` are emitted by the generator from the `Layer`.
- **Error-handling inner layers (Result, Either)**: preserve error types and short-circuit on the first failure; `Validation` accumulates instead and never gets a monad.
- **No new operators**: stacks reuse the base vocabulary, and there are no operator overloads on nested shapes (`Reader<E, Validation<…>>`); the struct is the only public surface.

### Ask the developer

1. What are the outer and inner types, and does this `OuterTInner` already exist?
2. Is the result a lawful monad, or applicative / functor only?
3. Does the inner type already have Functor / Applicative / Monad support?
4. Is it a stream or platform-specific (Combine) layer?
5. Is a new `Layer` case (and inner-shape protocol) needed?

Deliver: the nested-type functions (internal), one `inventory` line (plus overrides if needed), the regenerated sources, and tests in both the named and operator targets.
