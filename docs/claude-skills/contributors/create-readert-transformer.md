# Create Monad Transformer

Help implement a monad transformer stack — either a `ReaderT` (Reader as outer monad) or a flat transformer where another type (Optional, Array, Either, Publisher, AsyncStream) is the outer monad.

## Skill Prompt

You are helping a developer create a monad transformer following FP library conventions.

### Transformer Flavours

**ReaderT (Reader as outer monad)**:
- **Haskell**: `ReaderT r m a = r -> m a`
- **Swift**: `Reader<Env, M<A>>` where `M` is the inner monad
- Location: `Sources/Reader/` (implementation), `Sources/ReaderOperators/` (operators)

**Flat transformer (non-Reader outer)**:
- The outer monad wraps the inner: `Outer<Inner<A>>`
- Examples already in the library: `[A?]` (ArrayTOptional), `[Result<A,E>]` (ArrayTResult),
  `AnyPublisher<A?,E>` (PublisherTOptional), `AsyncStream<Either<L,A>>` (AsyncSequenceTEither)
- Location: `Sources/FP/` or `Sources/Either/` (implementation), `Sources/Operators/` or
  `Sources/EitherOperators/` (operators)
- Use free functions (not extension methods) when the outer type's generic parameters
  can't be constrained directly in an extension (e.g., `EitherT*` stacks)

### What is a monad transformer?

### Instructions:

1. **Understand the inner monad**: What effects does it provide? (State, IO, Validation, etc.)
2. **Implement Functor**: `mapT` to transform values inside `Reader<Env, M<A>>`
3. **Implement Applicative**: `liftA2ReaderX` for combining effects
4. **Implement Monad**: `flatMapT` for monadic composition
5. **Create Operators**: Operators that work with the transformer
6. **Add Tests**: Verify transformer laws and compositions

### Pattern to Follow:

Create three files in appropriate modules:

#### 1. Functor Implementation (in ReaderXFP module)

```swift
import FP
import Reader

public extension Reader {
    /// Functor map for ReaderT + CustomMonad
    /// Maps over values inside Reader<Env, M<A>>
    func mapT<A, B>(_ fn: @escaping (A) -> B) -> Reader<Environment, M<B>>
    where Output == M<A> {
        mapReader { monadicValue in
            monadicValue.fmap(fn)  // Use inner monad's fmap
        }
    }

    static func fmap<A, B>(
        _ fn: @escaping (A) -> B
    ) -> (Reader<Environment, M<A>>) -> Reader<Environment, M<B>>
    where Output == M<A> {
        { $0.mapT(fn) }
    }
}
```

#### 2. Applicative Implementation (in ReaderXFP module)

```swift
/// liftA2 for ReaderT + CustomMonad
public func liftA2ReaderCustomMonad<Env, A, B, C>(
    _ fn: @escaping (A, B) -> C
) -> (Reader<Env, M<A>>, Reader<Env, M<B>>) -> Reader<Env, M<C>> {
    { readerA, readerB in
        Reader { env in
            let ma = readerA(env)
            let mb = readerB(env)
            // Use inner monad's liftA2
            return liftA2CustomMonad(fn)(ma, mb)
        }
    }
}

/// Apply for ReaderT + CustomMonad
public func applyReaderCustomMonad<Env, A, B>(
    _ readerF: Reader<Env, M<(A) -> B>>,
    _ readerA: Reader<Env, M<A>>
) -> Reader<Env, M<B>> {
    Reader { env in
        let mf = readerF(env)
        let ma = readerA(env)
        // Use inner monad's apply
        return applyCustomMonad(mf, ma)
    }
}
```

#### 3. Monad Implementation (in ReaderXFP module)

```swift
public extension Reader {
    /// Monadic flatMap for ReaderT + CustomMonad
    /// (>>=) :: Reader e (m a) -> (a -> Reader e (m b)) -> Reader e (m b)
    func flatMapT<A, B>(_ fn: @escaping (A) -> Reader<Environment, M<B>>) -> Reader<Environment, M<B>>
    where Output == M<A> {
        Reader<Environment, M<B>> { env in
            self.runReader(env).flatMap { a in
                fn(a).runReader(env)
            }
        }
    }
}

/// Bind for ReaderT + CustomMonad
public func bindReaderCustomMonad<Env, A, B>(
    _ reader: Reader<Env, M<A>>,
    _ fn: @escaping (A) -> Reader<Env, M<B>>
) -> Reader<Env, M<B>> {
    reader.flatMapT(fn)
}

/// Kleisli composition for ReaderT + CustomMonad
public func kleisliReaderCustomMonad<Env, A, B, C>(
    _ f: @escaping (A) -> Reader<Env, M<B>>,
    _ g: @escaping (B) -> Reader<Env, M<C>>
) -> (A) -> Reader<Env, M<C>> {
    { a in
        f(a).flatMapT(g)
    }
}
```

#### 4. Operators (in ReaderXOperators module)

```swift
import Reader
import ReaderXFP
import Operators

// MARK: - Functor Operators

public func <£> <A, B, Env>(
    _ transform: @escaping (A) -> B,
    _ reader: Reader<Env, M<A>>
) -> Reader<Env, M<B>> {
    reader.mapT(transform)
}

public func £> <A, B, Env>(
    _ reader: Reader<Env, M<A>>,
    _ value: B
) -> Reader<Env, M<B>> {
    reader.mapT { _ in value }
}

public func <£ <A, B, Env>(
    _ value: A,
    _ reader: Reader<Env, M<B>>
) -> Reader<Env, M<A>> {
    reader £> value
}

// MARK: - Applicative Operators

public func <*> <Env, A, B>(
    _ readerF: Reader<Env, M<(A) -> B>>,
    _ readerA: Reader<Env, M<A>>
) -> Reader<Env, M<B>> {
    applyReaderCustomMonad(readerF, readerA)
}

public func *> <Env, A, B>(
    _ lhs: Reader<Env, M<A>>,
    _ rhs: Reader<Env, M<B>>
) -> Reader<Env, M<B>> {
    liftA2ReaderCustomMonad { (_: A, b: B) in b }(lhs, rhs)
}

public func <* <Env, A, B>(
    _ lhs: Reader<Env, M<A>>,
    _ rhs: Reader<Env, M<B>>
) -> Reader<Env, M<A>> {
    liftA2ReaderCustomMonad { (a: A, _: B) in a }(lhs, rhs)
}

// MARK: - Monad Operators

public func >>- <Env, A, B>(
    _ reader: Reader<Env, M<A>>,
    _ fn: @escaping (A) -> Reader<Env, M<B>>
) -> Reader<Env, M<B>> {
    reader.flatMapT(fn)
}

public func -<< <Env, A, B>(
    _ fn: @escaping (A) -> Reader<Env, M<B>>,
    _ reader: Reader<Env, M<A>>
) -> Reader<Env, M<B>> {
    reader >>- fn
}

public func >=> <Env, A, B, C>(
    _ f: @escaping (A) -> Reader<Env, M<B>>,
    _ g: @escaping (B) -> Reader<Env, M<C>>
) -> (A) -> Reader<Env, M<C>> {
    kleisliReaderCustomMonad(f, g)
}

public func <&> <Env, A, B, C>(
    _ g: @escaping (B) -> Reader<Env, M<C>>,
    _ f: @escaping (A) -> Reader<Env, M<B>>
) -> (A) -> Reader<Env, M<C>> {
    f >=> g
}
```

#### 5. Tests (in ReaderXOperatorsTests)

```swift
import XCTest
@testable import Reader
@testable import ReaderXFP
@testable import ReaderXOperators
import FP

final class ReaderCustomMonadTests: XCTestCase {
    struct Environment {
        let config: Int
    }

    // MARK: - Functor Tests

    func testFunctorOperatorFmap() {
        let reader = Reader<Environment, M<Int>> { env in
            pure(env.config * 2)
        }

        let mapped = { $0 * 3 } <£> reader

        let env = Environment(config: 5)
        let result = mapped(env)

        // Verify result based on M's structure
        // XCTAssertEqual(...)
    }

    // MARK: - Applicative Tests

    func testApplicativeOperator() {
        let readerA = Reader<Environment, M<Int>> { env in
            pure(env.config)
        }

        let readerB = Reader<Environment, M<Int>> { env in
            pure(env.config * 2)
        }

        let combined = liftA2ReaderCustomMonad(+)(readerA, readerB)

        let env = Environment(config: 5)
        let result = combined(env)

        // Verify result
        // XCTAssertEqual(...)
    }

    // MARK: - Monad Tests

    func testMonadOperatorBind() {
        let reader = Reader<Environment, M<Int>> { env in
            pure(env.config)
        }

        let bound = reader >>- { value in
            Reader<Environment, M<Int>> { env in
                pure(value + env.config)
            }
        }

        let env = Environment(config: 5)
        let result = bound(env)

        // Verify result
        // XCTAssertEqual(...)
    }

    func testKleisliComposition() {
        let f: (Int) -> Reader<Environment, M<Int>> = { x in
            Reader { env in pure(x + env.config) }
        }

        let g: (Int) -> Reader<Environment, M<Int>> = { x in
            Reader { env in pure(x * env.config) }
        }

        let composed = f >=> g

        let env = Environment(config: 5)
        let result = composed(10)(env)

        // Verify result
        // XCTAssertEqual(...)
    }
}
```

### Special Considerations:

**For async monads (AsyncSequence, Publisher)**:
- Add `@Sendable` constraints
- Add platform availability annotations: `@available(macOS 10.15, iOS 13.0, ...)`
- Environment must be `Sendable`

**For platform-specific monads (Combine)**:
- Wrap with `#if canImport(Combine)`
- Add higher platform requirements for parameterized existentials

**For error-handling monads (Result, Either)**:
- Preserve error types through transformations
- Consider error short-circuiting behavior

### Ask the developer:
1. What is the inner monad type (M)?
2. Does it already have Functor/Applicative/Monad support?
3. Is it async or concurrent (needs Sendable)?
4. Is it platform-specific?
5. What module names should be used?

Generate complete, working ReaderT transformer code following FP library patterns.
