// SPDX-License-Identifier: Apache-2.0

// Inner-shape protocols.
//
// Swift has no parameterized extensions (`extension<A> Reader where Output == [A]`), so the lifting
// properties of the transformer stacks (`reader.readerT`, `publisher.publisherT`, `array.arrayT`, …)
// constrain the inner layer through these protocols instead. Each protocol has exactly one conformer,
// the real type, and every requirement is the identity on it: no copies, O(1).
//
// `coerceArray` / `coerceAsyncStream` exist because mapping an identity over an `Array` or an
// `AsyncStream` would cost O(n) or a new stream; as requirements they are a free type-equality cast.

/// The shape of `[Element]`, used to lift `F<[A]>` into an `FTArray` stack.
public protocol ArrayLike<Element>: SendableMetatype {
    /// The array element.
    associatedtype Element

    /// Views a value as `[Element]`; the identity for `Array`.
    static func asArray(_ value: Self) -> [Element]

    /// Views a stream of values as a stream of `[Element]`; the identity for `Array`.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    static func coerceAsyncStream(_ values: AsyncStream<Self>) -> AsyncStream<[Element]>
}

extension Array: ArrayLike {
    /// Identity: an array already is `[Element]`.
    public static func asArray(_ value: [Element]) -> [Element] {
        value
    }

    /// Identity: a stream of arrays already is `AsyncStream<[Element]>`.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public static func coerceAsyncStream(_ values: AsyncStream<[Element]>) -> AsyncStream<[Element]> {
        values
    }
}

/// The shape of `Wrapped?`, used to lift `F<A?>` into an `FTOptional` stack.
public protocol OptionalLike<Wrapped>: SendableMetatype {
    /// The wrapped value.
    associatedtype Wrapped

    /// Views a value as `Wrapped?`; the identity for `Optional`.
    static func asOptional(_ value: Self) -> Wrapped?

    /// Views an array of values as `[Wrapped?]`; the identity for `Optional`.
    static func coerceArray(_ values: [Self]) -> [Wrapped?]

    /// Views a stream of values as a stream of `Wrapped?`; the identity for `Optional`.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    static func coerceAsyncStream(_ values: AsyncStream<Self>) -> AsyncStream<Wrapped?>
}

extension Optional: OptionalLike {
    /// Identity: an optional already is `Wrapped?`.
    public static func asOptional(_ value: Wrapped?) -> Wrapped? {
        value
    }

    /// Identity: an array of optionals already is `[Wrapped?]`.
    public static func coerceArray(_ values: [Wrapped?]) -> [Wrapped?] {
        values
    }

    /// Identity: a stream of optionals already is `AsyncStream<Wrapped?>`.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public static func coerceAsyncStream(_ values: AsyncStream<Wrapped?>) -> AsyncStream<Wrapped?> {
        values
    }
}

/// The shape of `Result<Success, Failure>`, used to lift `F<Result<A, E>>` into an `FTResult` stack.
public protocol ResultLike<Success, Failure>: SendableMetatype {
    /// The success value.
    associatedtype Success
    /// The failure value.
    associatedtype Failure: Error

    /// Views a value as `Result<Success, Failure>`; the identity for `Result`.
    static func asResult(_ value: Self) -> Result<Success, Failure>

    /// Views an array of values as `[Result<Success, Failure>]`; the identity for `Result`.
    static func coerceArray(_ values: [Self]) -> [Result<Success, Failure>]

    /// Views a stream of values as a stream of `Result<Success, Failure>`; the identity for `Result`.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    static func coerceAsyncStream(_ values: AsyncStream<Self>) -> AsyncStream<Result<Success, Failure>>
}

extension Result: ResultLike {
    /// Identity: a result already is `Result<Success, Failure>`.
    public static func asResult(_ value: Result<Success, Failure>) -> Result<Success, Failure> {
        value
    }

    /// Identity: an array of results already is `[Result<Success, Failure>]`.
    public static func coerceArray(_ values: [Result<Success, Failure>]) -> [Result<Success, Failure>] {
        values
    }

    /// Identity: a stream of results already is `AsyncStream<Result<Success, Failure>>`.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public static func coerceAsyncStream(
        _ values: AsyncStream<Result<Success, Failure>>
    ) -> AsyncStream<Result<Success, Failure>> {
        values
    }
}

/// The shape of `AsyncStream<Element>`, used to lift `F<AsyncStream<A>>` into an `FTAsyncStream` stack.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public protocol AsyncStreamLike<Element>: SendableMetatype {
    /// The stream element.
    associatedtype Element

    /// Views a value as `AsyncStream<Element>`; the identity for `AsyncStream`.
    static func asAsyncStream(_ value: Self) -> AsyncStream<Element>
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension AsyncStream: AsyncStreamLike {
    /// Identity: a stream already is `AsyncStream<Element>`.
    public static func asAsyncStream(_ value: AsyncStream<Element>) -> AsyncStream<Element> {
        value
    }
}
