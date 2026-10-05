// SPDX-License-Identifier: Apache-2.0
import CoreFP

// Inner-shape protocols for the DataStructure types; see `ArrayLike` in CoreFP for the rationale.
// Each protocol has exactly one conformer and every requirement is the identity on it (O(1), no copies).

/// The shape of `Either<Left, Right>`, used to lift `F<Either<L, A>>` into an `FTEither` stack.
public protocol EitherLike<Left, Right>: SendableMetatype {
    /// The left (error) value.
    associatedtype Left
    /// The right (success) value.
    associatedtype Right

    /// Views a value as `Either<Left, Right>`; the identity for `Either`.
    static func asEither(_ value: Self) -> Either<Left, Right>

    /// Views an array of values as `[Either<Left, Right>]`; the identity for `Either`.
    static func coerceArray(_ values: [Self]) -> [Either<Left, Right>]

    /// Views a stream of values as a stream of `Either<Left, Right>`; the identity for `Either`.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    static func coerceAsyncStream(_ values: AsyncStream<Self>) -> AsyncStream<Either<Left, Right>>
}

extension Either: EitherLike {
    /// Identity: an either already is `Either<A, B>`.
    public static func asEither(_ value: Either<A, B>) -> Either<A, B> {
        value
    }

    /// Identity: an array of eithers already is `[Either<A, B>]`.
    public static func coerceArray(_ values: [Either<A, B>]) -> [Either<A, B>] {
        values
    }

    /// Identity: a stream of eithers already is `AsyncStream<Either<A, B>>`.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public static func coerceAsyncStream(_ values: AsyncStream<Either<A, B>>) -> AsyncStream<Either<A, B>> {
        values
    }
}

/// The shape of `NonEmpty<Element>`, used to lift `F<NonEmpty<A>>` into an `FTNonEmpty` stack.
public protocol NonEmptyLike<Element>: SendableMetatype {
    /// The element.
    associatedtype Element: Sendable

    /// Views a value as `NonEmpty<Element>`; the identity for `NonEmpty`.
    static func asNonEmpty(_ value: Self) -> NonEmpty<Element>
}

extension NonEmpty: NonEmptyLike {
    /// Identity: a non-empty collection already is `NonEmpty<A>`.
    public static func asNonEmpty(_ value: NonEmpty<A>) -> NonEmpty<A> {
        value
    }
}

/// The shape of `Writer<Log, Value>`, used to lift `F<Writer<W, A>>` into an `FTWriter` stack.
public protocol WriterLike<Log, Value>: SendableMetatype {
    /// The accumulated log.
    associatedtype Log: Monoid
    /// The computed value.
    associatedtype Value

    /// Views a value as `Writer<Log, Value>`; the identity for `Writer`.
    static func asWriter(_ value: Self) -> Writer<Log, Value>

    /// Views an array of values as `[Writer<Log, Value>]`; the identity for `Writer`.
    static func coerceArray(_ values: [Self]) -> [Writer<Log, Value>]

    /// Views a stream of values as a stream of `Writer<Log, Value>`; the identity for `Writer`.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    static func coerceAsyncStream(_ values: AsyncStream<Self>) -> AsyncStream<Writer<Log, Value>>
}

extension Writer: WriterLike {
    /// Identity: a writer already is `Writer<W, A>`.
    public static func asWriter(_ value: Writer<W, A>) -> Writer<W, A> {
        value
    }

    /// Identity: an array of writers already is `[Writer<W, A>]`.
    public static func coerceArray(_ values: [Writer<W, A>]) -> [Writer<W, A>] {
        values
    }

    /// Identity: a stream of writers already is `AsyncStream<Writer<W, A>>`.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public static func coerceAsyncStream(_ values: AsyncStream<Writer<W, A>>) -> AsyncStream<Writer<W, A>> {
        values
    }
}

/// The shape of `Validation<Errors, Value>`, used to lift `F<Validation<E, A>>` into an `FTValidation` stack.
public protocol ValidationLike<Errors, Value>: SendableMetatype {
    /// The accumulated errors.
    associatedtype Errors: Semigroup
    /// The valid value.
    associatedtype Value

    /// Views a value as `Validation<Errors, Value>`; the identity for `Validation`.
    static func asValidation(_ value: Self) -> Validation<Errors, Value>
}

extension Validation: ValidationLike {
    /// Identity: a validation already is `Validation<E, A>`.
    public static func asValidation(_ value: Validation<E, A>) -> Validation<E, A> {
        value
    }
}

/// The shape of `Reader<Environment, Output>`, used to lift `F<Reader<R, A>>` into an `FTReader` stack.
public protocol ReaderLike<Environment, Output>: SendableMetatype {
    /// The environment read.
    associatedtype Environment
    /// The output produced.
    associatedtype Output

    /// Views a value as `Reader<Environment, Output>`; the identity for `Reader`.
    static func asReader(_ value: Self) -> Reader<Environment, Output>
}

extension Reader: ReaderLike {
    /// Identity: a reader already is `Reader<Environment, Output>`.
    public static func asReader(_ value: Reader<Environment, Output>) -> Reader<Environment, Output> {
        value
    }
}

/// The shape of `Stateful<State, Value>`, used to lift `F<Stateful<S, A>>` into an `FTStateful` stack.
public protocol StatefulLike<State, Value>: SendableMetatype {
    /// The threaded state.
    associatedtype State
    /// The produced value.
    associatedtype Value

    /// Views a value as `Stateful<State, Value>`; the identity for `Stateful`.
    static func asStateful(_ value: Self) -> Stateful<State, Value>

    /// Views an array of values as `[Stateful<State, Value>]`; the identity for `Stateful`.
    static func coerceArray(_ values: [Self]) -> [Stateful<State, Value>]

    /// Views a stream of values as a stream of `Stateful<State, Value>`; the identity for `Stateful`.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    static func coerceAsyncStream(_ values: AsyncStream<Self>) -> AsyncStream<Stateful<State, Value>>
}

extension Stateful: StatefulLike {
    /// Identity: a stateful computation already is `Stateful<S, A>`.
    public static func asStateful(_ value: Stateful<S, A>) -> Stateful<S, A> {
        value
    }

    /// Identity: an array of stateful computations already is `[Stateful<S, A>]`.
    public static func coerceArray(_ values: [Stateful<S, A>]) -> [Stateful<S, A>] {
        values
    }

    /// Identity: a stream of stateful computations already is `AsyncStream<Stateful<S, A>>`.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public static func coerceAsyncStream(_ values: AsyncStream<Stateful<S, A>>) -> AsyncStream<Stateful<S, A>> {
        values
    }
}
