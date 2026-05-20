// swiftlint:disable file_length
import Foundation

/// A phantom type namespace for free functions with a single type parameter.
///
/// `Of<T>` is an uninhabited enum used purely as a namespace. It has static methods that
/// mirror the top-level free functions but are scoped to a specific type `T`, enabling
/// point-free use without type inference ambiguities.
///
/// ```swift
/// [1, 2, nil, 3].compactMap(Of<Int>.id)   // disambiguates id for Int
/// ```
public enum Of<T>: Sendable {}

/// A phantom type namespace for free functions with two type parameters.
///
/// Like ``Of``, but with two type parameters `T` and `U`. Methods return functions of type
/// `(T) -> U`.
public enum Of2<T, U>: Sendable {}

/// A phantom type namespace for free functions with three type parameters.
///
/// Like ``Of``, but with three type parameters `T`, `U`, and `V`. Methods return functions
/// of type `(T, U) -> V`.
public enum Of3<T, U, V>: Sendable {}

/// Converts a `Never` value into any type — the type-theoretic absurdity function.
///
/// Because `Never` is uninhabited, this function can never actually be called at runtime.
/// It is used to eliminate impossible cases in exhaustive pattern matching or generic code
/// where a `Never`-typed value proves an unreachable branch.
///
/// ```swift
/// func handle<A>(_ result: Result<A, Never>) -> A {
///     switch result {
///     case .success(let value): return value
///     case .failure(let e): return absurd(e)  // provably unreachable
///     }
/// }
/// ```
public func absurd<T>(_: Never) -> T { }
public extension Of {
    static func absurd(_: Never) -> T { }
}

// Removed due to crashing compiler bug in Swift 6.2
// public func ignore<each T>(_: repeat each T) { }
// Temporary workaround is to offer n-ary overloads of `ignore` up to 3 parameters, which should cover most
// use cases. For 4 or more arguments, the last overload uses 4 fixed parameters plus a variadic tail.

/// Calls with no arguments and returns Void. Useful as a no-op placeholder.
public func ignore() {}

/// Discards a single argument and returns Void.
///
/// Replaces `{ _ in }` wherever a function is expected that runs a side-effect and ignores its input.
///
/// ```swift
/// tasks.forEach(ignore)   // run side effects, discard results
/// [1, 2, 3].map(ignore)   // [(), (), ()]
/// ```
public func ignore<T>(_: T) {}

/// Discards two arguments and returns Void.
public func ignore<T, U>(_: T, _: U) {}

/// Discards three arguments and returns Void.
public func ignore<T, U, V>(_: T, _: U, _: V) {}

/// Discards four or more arguments and returns Void.
/// Uses 4 fixed type parameters plus a variadic parameter pack for the tail.
public func ignore<T, U, V, W, each X>(_: T, _: U, _: V, _: W, _: repeat each X) {}

public extension Of {
    static func ignore() -> (T) -> Void { { _ in } }
}

public extension Of2 {
    static func ignore() -> (T, U) -> Void { { _, _ in } }
}

public extension Of3 {
    static func ignore() -> (T, U, V) -> Void { { _, _, _ in } }
}

// Removed due to crashing compiler bug in Swift 6.2
// public func const<each Ignore, Return>(
//     _ returnValue: Return
// ) -> (repeat each Ignore) -> Return {
//     { (_: repeat each Ignore) in returnValue }
// }
// Temporary workaround is to offer n-ary overloads of `const` up to 3 parameters, which should cover most
// use cases. For 4 or more ignored arguments, the last overload uses 4 fixed parameters plus a variadic
// tail. Each arity also has a @Sendable variant — the compiler prefers it in @Sendable-requiring positions
// when `Return` is `Sendable`.

/// Returns a function that ignores all its arguments and always returns `returnValue`.
///
/// Useful for passing a constant value to places that expect a closure:
/// ```swift
/// myIntArray.filter(const(shouldKeepIntegers))
/// results.map(const(.success(())))
/// ```
///
/// Sibling to `ignore`, which discards the input without returning a value.
/// This 0-argument overload returns a `() -> Return` thunk.
public func const<Return>(_ returnValue: Return) -> () -> Return {
    { returnValue }
}

/// Sendable 0-argument overload.
public func const<Return: Sendable>(_ returnValue: Return) -> @Sendable () -> Return {
    { returnValue }
}

/// Returns a function that ignores one argument and always returns `returnValue`.
public func const<Ignore, Return>(_ returnValue: Return) -> (Ignore) -> Return {
    { _ in returnValue }
}

/// Sendable 1-argument overload.
/// Preferred by the compiler in `@Sendable`-requiring positions (e.g. `AsyncSequence.map`).
public func const<Ignore, Return: Sendable>(_ returnValue: Return) -> @Sendable (Ignore) -> Return {
    { _ in returnValue }
}

/// Returns a function that ignores two arguments and always returns `returnValue`.
public func const<I1, I2, Return>(_ returnValue: Return) -> (I1, I2) -> Return {
    { _, _ in returnValue }
}

/// Sendable 2-argument overload.
public func const<I1, I2, Return: Sendable>(_ returnValue: Return) -> @Sendable (I1, I2) -> Return {
    { _, _ in returnValue }
}

/// Returns a function that ignores three arguments and always returns `returnValue`.
public func const<I1, I2, I3, Return>(_ returnValue: Return) -> (I1, I2, I3) -> Return {
    { _, _, _ in returnValue }
}

/// Sendable 3-argument overload.
public func const<I1, I2, I3, Return: Sendable>(_ returnValue: Return) -> @Sendable (I1, I2, I3) -> Return {
    { _, _, _ in returnValue }
}

/// Returns a function that ignores four or more arguments and always returns `returnValue`.
/// Uses 4 fixed type parameters plus a variadic parameter pack for the tail.
public func const<I1, I2, I3, I4, each I, Return>(
    _ returnValue: Return
) -> (I1, I2, I3, I4, repeat each I) -> Return {
    { (_: I1, _: I2, _: I3, _: I4, _: repeat each I) in returnValue }
}

/// Sendable 4+-argument overload.
public func const<I1, I2, I3, I4, each I, Return: Sendable>(
    _ returnValue: Return
) -> @Sendable (I1, I2, I3, I4, repeat each I) -> Return {
    { (_: I1, _: I2, _: I3, _: I4, _: repeat each I) in returnValue }
}

public extension Of {
    static func const<Return>(_ returnValue: Return) -> (T) -> Return {
        { _ in returnValue }
    }
}

public extension Of2 {
    static func const(_ returnValue: U) -> (T) -> U {
        { _ in returnValue }
    }
}

public extension Of3 {
    static func const(_ returnValue: V) -> (T, U) -> V {
        { _, _ in returnValue }
    }
}

/// Identify function of a value, returning the unmodified value
/// Useful in function composition and represents the arrow pointing to itself category.
public func id<T>(_ value: T) -> T {
    value
}

public extension Of {
    static func id(_ value: T) -> T {
        CoreFP.id(value)
    }
}

/// Curries a given function that accepts two parameters
/// into one that accepts the two parameters subsequently.
/// Useful to break down a function that might be used later
/// that we don't have all parameters at the time of calling.
/// (partial application)
public func curry<A, B, C>(
    _ function: @escaping @Sendable (A, B) -> C
) -> (A) -> (B) -> C {
    { (a: A) -> (B) -> C in
        { (b: B) -> C in
            function(a, b)
        }
    }
}

/// Sendable overload — picked by the compiler in `@Sendable`-requiring positions.
/// Requires `A: Sendable` because the partially-applied `a` is captured in the inner closure.
public func curry<A: Sendable, B, C>(
    _ function: @escaping @Sendable (A, B) -> C
) -> @Sendable (A) -> @Sendable (B) -> C {
    { (a: A) -> @Sendable (B) -> C in
        { (b: B) -> C in
            function(a, b)
        }
    }
}

public func curryT<A, B, C>(
    _ function: @escaping @Sendable ((A, B)) -> C
) -> (A) -> (B) -> C {
    { (a: A) -> (B) -> C in
        { (b: B) -> C in
            function((a, b))
        }
    }
}

/// Sendable overload — requires `A: Sendable` for the inner closure capture.
public func curryT<A: Sendable, B, C>(
    _ function: @escaping @Sendable ((A, B)) -> C
) -> @Sendable (A) -> @Sendable (B) -> C {
    { (a: A) -> @Sendable (B) -> C in
        { (b: B) -> C in
            function((a, b))
        }
    }
}

public func partialApply<A, B, C>(
    _ function: @escaping @Sendable (A, B) -> C,
    _ value: A
) -> (B) -> C {
    curry(function)(value)
}

/// Sendable overload — requires `A: Sendable` because `value` is captured.
public func partialApply<A: Sendable, B, C>(
    _ function: @escaping @Sendable (A, B) -> C,
    _ value: A
) -> @Sendable (B) -> C {
    curry(function)(value)
}

/// Opposite of curry, takes a function that returns another function
/// and compresses into a single function that take both arguments at
/// once.
public func uncurry<A, B, C>(
    _ function: @escaping @Sendable (A) -> @Sendable (B) -> C
) -> @Sendable (A, B) -> C {
    { (a: A, b: B) -> C in
        function(a)(b)
    }
}

/// Zero arguments curry, adds lazy evaluation to a value or operation
public func lazy<A, B>(_ function: @escaping @Sendable (A) -> B)
-> @Sendable () -> @Sendable (A) -> B {
    {
        function
    }
}

/// Zero arguments curry, adds lazy evaluation to a value or operation
public func lazy<A>(_ value: A)
-> () -> (A) {
    {
        value
    }
}

/// Sendable overload — requires `A: Sendable` because `value` is captured in a `@Sendable` thunk.
public func lazy<A: Sendable>(_ value: A)
-> @Sendable () -> A {
    {
        value
    }
}

/// Opposite of lazy/zurry, removes the layer of Void application
/// Applies the argument Void of the curried function
public func unlazy<A, B>(
    _ function: @escaping @Sendable (A) -> @Sendable () -> B
) -> @Sendable (A) -> B {
    { (a: A) -> B in
        function(a)()
    }
}

/// Opposite of lazy/zurry, removes the layer of Void application
/// Applies the argument Void of the curried function
public func unlazy<A, B>(
    _ function: @escaping @Sendable () -> @Sendable (A) -> B
) -> @Sendable (A) -> B {
    { (a: A) -> B in
        function()(a)
    }
}

/// Opposite of lazy/zurry, removes the layer of Void application
/// Applies the argument Void of the curried function
public func unlazy<A>(
    _ function: @escaping @Sendable () -> (A)
) -> A {
    function()
}

public func flip<A, B, C>(
    _ function: @escaping @Sendable (A, B) -> C
) -> (B) -> (A) -> C {
    { (b: B) -> (A) -> C in
        { (a: A) -> C in
            function(a, b)
        }
    }
}

/// Sendable overload — requires `B: Sendable` because the inner closure captures `b`.
public func flip<A, B: Sendable, C>(
    _ function: @escaping @Sendable (A, B) -> C
) -> @Sendable (B) -> @Sendable (A) -> C {
    { (b: B) -> @Sendable (A) -> C in
        { (a: A) -> C in
            function(a, b)
        }
    }
}

public func partialApplyFlip<A, B, C>(
    _ function: @escaping @Sendable (A, B) -> C,
    _ value: B
) -> (A) -> C {
    flip(function)(value)
}

/// Sendable overload — requires `B: Sendable` because `value` is captured.
public func partialApplyFlip<A, B: Sendable, C>(
    _ function: @escaping @Sendable (A, B) -> C,
    _ value: B
) -> @Sendable (A) -> C {
    flip(function)(value)
}

public func flipU<A, B, C>(
    _ function: @escaping @Sendable (A, B) -> C
) -> @Sendable (B, A) -> C {
    { (b: B, a: A) -> C in
        function(a, b)
    }
}

public func flip<A, B, C>(
    _ function: @escaping @Sendable (A) -> (B) -> C
) -> (B) -> (A) -> C {
    { (b: B) -> (A) -> C in
        { (a: A) -> C in
            function(a)(b)
        }
    }
}

/// Sendable overload — requires `B: Sendable` for the inner closure capture.
public func flip<A, B: Sendable, C>(
    _ function: @escaping @Sendable (A) -> @Sendable (B) -> C
) -> @Sendable (B) -> @Sendable (A) -> C {
    { (b: B) -> @Sendable (A) -> C in
        { (a: A) -> C in
            function(a)(b)
        }
    }
}

public func tuple<A, B>(_ a: A, _ b: B) -> (A, B) {
    (a, b)
}

public func tuple<A, B, C>(_ fn: @escaping @Sendable (A, B) -> C) -> @Sendable ((A, B)) -> C {
    { tuple in fn(tuple.0, tuple.1) }
}

public func untuple<A, B, C>(_ fn: @escaping @Sendable ((A, B)) -> C) -> @Sendable (A, B) -> C {
    { a, b in fn((a, b)) }
}

/// Allows for transforming a function to a similar function but with more arguments by specyfing
/// which one has to be used. The other arguments will be ignored.
///
/// Example:
/// ```
/// let f: (String) -> Character? = \.first
/// let f: (String, Int) -> Character? = \.first |> withArg(\.0)
/// ```
/// When `f` function changes its type and introduces another argument, the key path cannot be used anymore as
/// it uses only a single argument. However, it still can be changed to use `usingArg` function and `|>` operator:
public func withArg<Arg1, Arg2, Picked, Return>(
    _ pickArgument: @escaping @Sendable ((Arg1, Arg2)) -> Picked
) -> @Sendable (@escaping @Sendable (Picked) -> Return) -> @Sendable (Arg1, Arg2) -> Return {
    curryT(compose(compose, untuple))(pickArgument)
}

// Removed due to crashing compiler bug in Swift 6.2
// public func fail<T, each U>(
//     _ message: String,
//     file: StaticString = #file,
//     line: UInt = #line
// ) -> (repeat each U) -> T {
//     { (_: repeat each U) -> T in
//         fatalError(message, file: file, line: line)
//     }
// }
// Temporary workaround is to offer n-ary overloads of `fail` up to 3 parameters, which should cover most
// use cases. For 4 or more arguments, the last overload uses 4 fixed parameters plus a variadic tail.

/// Returns a function that calls `fatalError` with no arguments.
///
/// Intended for mock/stub implementations that must never be called in production:
/// ```swift
/// init(fn: @escaping @Sendable () -> AnyPublisher<String, Never> = fail("Mock not implemented")) -> Mock
/// ```
///
/// **Be careful with this function in production code — it will crash the app if not overridden.**
public func fail<T>(_ message: String, file: StaticString = #file, line: UInt = #line) -> () -> T {
    { fatalError(message, file: file, line: line) }
}

/// Returns a function that ignores one argument and calls `fatalError`.
public func fail<T, U>(_ message: String, file: StaticString = #file, line: UInt = #line) -> (U) -> T {
    { _ in fatalError(message, file: file, line: line) }
}

/// Returns a function that ignores two arguments and calls `fatalError`.
public func fail<T, U, V>(_ message: String, file: StaticString = #file, line: UInt = #line) -> (U, V) -> T {
    { _, _ in fatalError(message, file: file, line: line) }
}

/// Returns a function that ignores three arguments and calls `fatalError`.
public func fail<T, U, V, W>(_ message: String, file: StaticString = #file, line: UInt = #line) -> (U, V, W) -> T {
    { _, _, _ in fatalError(message, file: file, line: line) }
}

/// Returns a function that ignores four or more arguments and calls `fatalError`.
/// Uses 4 fixed type parameters plus a variadic parameter pack for the tail.
public func fail<T, U, V, W, X, each Y>(
    _ message: String,
    file: StaticString = #file,
    line: UInt = #line
) -> (U, V, W, X, repeat each Y) -> T {
    { (_: U, _: V, _: W, _: X, _: repeat each Y) in fatalError(message, file: file, line: line) }
}
