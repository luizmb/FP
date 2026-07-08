# Create Monad Transformer

Help implement a monad transformer stack — either a `ReaderT` (Reader as outer monad) or a flat transformer where another type (Optional, Array, Either, Publisher, AsyncStream) is the outer monad.

## Skill Prompt

You are helping a developer create a monad transformer following FP library conventions.

### Transformer Flavours

**`OuterTInner` naming** — see `<doc:MonadTransformers>` for the full picture. `ReaderTOptional` means `Reader<Env, Optional<A>>`; `ArrayTResult` means `[Result<A, E>]`. The outer type names the module the combo's files live in; the inner type is a suffix on the filenames.

**ReaderT (Reader as outer monad)**:
- **Haskell**: `ReaderT r m a = r -> m a`
- **Swift**: `Reader<Env, M<A>>` where `M` is the inner monad
- Location: `Sources/DataStructure/Reader/` (implementation, e.g. `ReaderTOptional+Functor.swift`), `Sources/DataStructureOperators/Reader/` (operators)
- Module: everything lives inside the `DataStructure`/`DataStructureOperators` modules — there is no separate per-type module

**Flat transformer (non-Reader outer)**:
- The outer monad wraps the inner: `Outer<Inner<A>>`
- Real examples already in the library: `[A?]` (`ArrayTOptional`), `[Result<A,E>]` (`ArrayTResult`),
  `AnyPublisher<A?,E>` (`PublisherTOptional`), `AsyncStream<Either<L,A>>` (`AsyncSequenceTEither`)
- Location: pure-stdlib/CoreFP combos (Array/Optional/Result/Publisher/AsyncSequence-with-each-other) live in `Sources/CoreFP/`/`Sources/CoreFPOperators/`; combos involving a `DataStructure` type (Either/Validation/Reader/Stateful/Writer/NonEmpty) live in `Sources/DataStructure/`/`Sources/DataStructureOperators/`
- Use free functions (not extension methods) when the outer type's generic parameters
  can't be constrained directly in an extension (e.g., some `EitherT*` stacks)

### What is a monad transformer?

A way to combine two monads into one, when you need both effects at once — e.g. "a dependency-injected computation (`Reader`) that might fail (`Optional`)" is `ReaderTOptional`, not two separate types you juggle by hand.

### Instructions:

1. **Understand the inner monad**: What effects does it provide? (State, error handling, accumulation, etc.)
2. **Implement Functor**: `mapT` (instance method) — transforms values *inside* the inner monad, reaching through the outer one
3. **Implement Applicative**: `liftA2T`/an `apply`-shaped free function, if the combo needs one
4. **Implement Monad**: `flatMapT` (instance method) — monadic composition through both layers
5. **Named `kleisliT`**: the `>=>`/`<=<` operators for this combo delegate to a named `kleisliT` function — never inline `{ a in fn1(a).flatMapT(fn2) }` directly in the operator body
6. **Create Operators, both directions**: every operator with a directional sense (`<£^>`/`<&^>` for transformer functor map, `>>-`/`-<<`, `>=>`/`<=<`) needs its flip added in the same change
7. **`Sendable`-first**: every escaping closure is `@Sendable`; the combo's own methods require `Environment`/inner-type-parameters to be `Sendable` where the language demands it
8. **Add Tests in all four targets that apply**: named-function tests in `CoreFPTests`/`DataStructureTests` (no operator symbols), operator tests in `CoreFPOperatorsTests`/`DataStructureOperatorsTests` (must use the operator)

### Pattern to Follow:

#### 1. Functor Implementation (`Sources/DataStructure/Reader/ReaderTCustomMonad+Functor.swift`)

```swift
import CoreFP

public extension Reader {
    /// Functor map for ReaderT + CustomMonad — maps over the value inside
    /// `Reader<Environment, CustomMonad<A>>`, reaching through the inner monad.
    func mapT<A, B>(_ fn: @escaping @Sendable (A) -> B) -> Reader<Environment, CustomMonad<B>>
        where Output == CustomMonad<A>
    {
        mapReader { monadicValue in
            monadicValue.map(fn)  // Use the inner monad's own Functor
        }
    }

    static func fmapT<A, B>(
        _ fn: @escaping @Sendable (A) -> B
    ) -> @Sendable (Reader<Environment, CustomMonad<A>>) -> Reader<Environment, CustomMonad<B>>
        where Output == CustomMonad<A>
    {
        { $0.mapT(fn) }
    }
}
```

#### 2. Applicative Implementation

```swift
public extension Reader {
    /// liftA2T for ReaderT + CustomMonad.
    static func liftA2T<Env, A, B, C>(
        _ fn: @escaping @Sendable (A, B) -> C
    ) -> @Sendable (Reader<Env, CustomMonad<A>>, Reader<Env, CustomMonad<B>>) -> Reader<Env, CustomMonad<C>> {
        { readerA, readerB in
            Reader { env in
                let ma = readerA(env)
                let mb = readerB(env)
                return CustomMonad.liftA2(fn)(ma, mb)  // Use the inner monad's own Applicative
            }
        }
    }
}
```

#### 3. Monad Implementation

```swift
public extension Reader {
    /// Monadic flatMapT for ReaderT + CustomMonad.
    /// (>>=) :: Reader e (m a) -> (a -> Reader e (m b)) -> Reader e (m b)
    func flatMapT<A, B>(
        _ fn: @escaping @Sendable (A) -> Reader<Environment, CustomMonad<B>>
    ) -> Reader<Environment, CustomMonad<B>> where Output == CustomMonad<A> {
        Reader<Environment, CustomMonad<B>> { env in
            self(env).flatMap { a in
                fn(a)(env)
            }
        }
    }

    /// Named Kleisli composition — `>=>`/`<=<` delegate to this, never inline the body.
    static func kleisliT<Env, A, B, C>(
        _ f: @escaping @Sendable (A) -> Reader<Env, CustomMonad<B>>,
        _ g: @escaping @Sendable (B) -> Reader<Env, CustomMonad<C>>
    ) -> @Sendable (A) -> Reader<Env, CustomMonad<C>> {
        { a in f(a).flatMapT(g) }
    }
}
```

#### 4. Operators (`Sources/DataStructureOperators/Reader/ReaderTCustomMonad+*Operators.swift`)

```swift
import CoreFP
import CoreFPOperators
import DataStructure

// MARK: - Functor Operators

public func <£^> <A, B, Env>(
    _ transform: @escaping @Sendable (A) -> B,
    _ reader: Reader<Env, CustomMonad<A>>
) -> Reader<Env, CustomMonad<B>> {
    reader.mapT(transform)
}

public func <&^> <A, B, Env>(
    _ reader: Reader<Env, CustomMonad<A>>,
    _ transform: @escaping @Sendable (A) -> B
) -> Reader<Env, CustomMonad<B>> {
    transform <£^> reader
}

// MARK: - Monad Operators

public func >>- <Env, A, B>(
    _ reader: Reader<Env, CustomMonad<A>>,
    _ fn: @escaping @Sendable (A) -> Reader<Env, CustomMonad<B>>
) -> Reader<Env, CustomMonad<B>> {
    reader.flatMapT(fn)
}

public func -<< <Env, A, B>(
    _ fn: @escaping @Sendable (A) -> Reader<Env, CustomMonad<B>>,
    _ reader: Reader<Env, CustomMonad<A>>
) -> Reader<Env, CustomMonad<B>> {
    reader >>- fn
}

public func >=> <Env, A, B, C>(
    _ f: @escaping @Sendable (A) -> Reader<Env, CustomMonad<B>>,
    _ g: @escaping @Sendable (B) -> Reader<Env, CustomMonad<C>>
) -> @Sendable (A) -> Reader<Env, CustomMonad<C>> {
    Reader.kleisliT(f, g)
}

public func <=< <Env, A, B, C>(
    _ g: @escaping @Sendable (B) -> Reader<Env, CustomMonad<C>>,
    _ f: @escaping @Sendable (A) -> Reader<Env, CustomMonad<B>>
) -> @Sendable (A) -> Reader<Env, CustomMonad<C>> {
    f >=> g
}
```

Note `<&^>` — not `<&>` — is the flipped transformer-functor operator. `<&>`/`<£^>` and `<&^>` live in a deliberately different precedence group from the base `<£>`/`<&>`; see `<doc:OperatorVocabulary>`. There is no separate "flipped Kleisli via `<&>`" — the flipped Kleisli operator is always `<=<`.

#### 5. Tests — both the named-function and operator targets

`DataStructureTests` (named functions, no operator symbols):
```swift
import Testing

@Suite("ReaderTCustomMonad — Functor/Monad (named functions)")
struct ReaderTCustomMonadTests {
    struct Environment: Sendable { let config: Int }

    @Test func mapTTransformsInnerValue() {
        let reader = Reader<Environment, CustomMonad<Int>> { env in .pure(env.config) }
        let mapped = reader.mapT { $0 * 2 }
        // #expect(...) against CustomMonad's own equality/introspection
    }

    @Test func flatMapTChains() {
        let reader = Reader<Environment, CustomMonad<Int>> { env in .pure(env.config) }
        let bound = reader.flatMapT { value in
            Reader<Environment, CustomMonad<Int>> { env in .pure(value + env.config) }
        }
        // #expect(...)
    }
}
```

`DataStructureOperatorsTests` (must use the operator symbol):
```swift
import CoreFPOperators
import DataStructureOperators
import Testing

@Suite("ReaderTCustomMonad — operator delegation")
struct ReaderTCustomMonadOperatorsTests {
    struct Environment: Sendable { let config: Int }

    @Test func fmapOperatorMatchesMapT() {
        let reader = Reader<Environment, CustomMonad<Int>> { env in .pure(env.config) }
        let env = Environment(config: 5)
        #expect(({ $0 * 3 } <£^> reader)(env) == reader.mapT { $0 * 3 }(env))
    }

    @Test func kleisliOperatorComposes() {
        let f: @Sendable (Int) -> Reader<Environment, CustomMonad<Int>> = { x in
            Reader { env in .pure(x + env.config) }
        }
        let g: @Sendable (Int) -> Reader<Environment, CustomMonad<Int>> = { x in
            Reader { env in .pure(x * env.config) }
        }
        let composed = f >=> g
        let env = Environment(config: 5)
        #expect(composed(10)(env) == Reader.kleisliT(f, g)(10)(env))
    }
}
```

### Special Considerations:

**For async monads (AsyncSequence, Publisher)**:
- Add `@Sendable` constraints throughout
- Add platform availability annotations: `@available(macOS 10.15, iOS 13.0, ...)`
- `Environment` must be `Sendable`

**For platform-specific monads (Combine/Publisher)**:
- Wrap with `#if canImport(Combine)`
- Add higher platform requirements for parameterized existentials

**For error-handling monads (Result, Either)**:
- Preserve error types through transformations
- Consider error short-circuiting behavior

**For `Stateful` as the inner or outer type**: `inout` state cannot be captured in a `@Sendable` closure — when a combinator needs to run multiple sub-`Stateful`s, evaluate them *before* entering the `@Sendable` closure body, in left-to-right applicative order.

### Ask the developer:
1. What is the inner monad type?
2. Does it already have Functor/Applicative/Monad support?
3. Is it async or concurrent (needs `Sendable`, availability annotations)?
4. Is it platform-specific (Combine)?
5. Does this exact `OuterTInner` combo already exist? Check `<doc:MonadTransformers>`'s coverage matrix first.

Generate complete, working transformer code following FP library patterns — named function + operator (both directions) + all four test targets that apply + `Sendable`-first, every time.
