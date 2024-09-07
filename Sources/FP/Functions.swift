import Foundation

public enum Of<T> {}
public enum Of2<T, U> {}
public enum Of3<T, U, V> {}

public func absurd<T>(_ never: Never) -> T { }
public extension Of {
    static func absurd(_ never: Never) -> T { }
}

public func ignore() { }
public func ignore<T>(_ t: T) { }

public extension Of {
    static func ignore() -> (T) -> Void { FP.ignore }
}

/// Ignores the data provided and returns a constant value.
/// Useful for passing a constant values to places that expect closures that provide
/// some data so you can compute a return value, but you don't need that input data.
///
/// For example:
/// `myIntArray.filter` will give you `Int` so you can return `Bool`
/// But if you have another variable in your scope that determines the `Bool`,
/// without having to evaluate the `Int`, you would usually do something like:
/// ```
/// myIntArray.filter { _ in shouldKeepIntegers }
/// ```
/// The problem with this approach is that you are capturing context in your closure,
/// which is usually not a problem for non-escaping functions or value types, but
/// you can still avoid the closure completely with function composition:
/// ```
/// myIntArray.filter(const(shouldKeepIntegers))
/// ```
///
/// Sibling to the function `func ignore<Ignore>(_ ignoredValue: Ignore) -> Void { }`
/// that would ignore the input but doesn't return any value back to the closure.
public func const<each Ignore, Return>(
    _ returnValue: Return
) -> (repeat each Ignore) -> Return {
    { (_: repeat each Ignore) in returnValue }
}

public extension Of {
    static func const<Return>(_ returnValue: Return) -> (T) -> Return {
        FP.const(returnValue)
    }
}

public extension Of2 {
    static func const(_ returnValue: U) -> (T) -> U {
        FP.const(returnValue)
    }
}

/// Identify function of a value, returning the unmodified value
/// Useful in function composition and represents the arrow pointing to itself category.
public func identity<T>(_ value: T) -> T {
    value
}

public extension Of {
    static func identity(_ value: T) -> T {
        FP.identity(value)
    }
}

/// Curries a given function that accepts two parameters
/// into one that accepts the two parameters subsequently.
/// Useful to break down a function that might be used later
/// that we don't have all parameters at the time of calling.
/// (partial application)
public func curry<A, B, C>(
    _ function: @escaping (A, B) -> C
) -> (A) -> (B) -> C {
    { (a: A) -> (B) -> C in
        { (b: B) -> C in
            function(a, b)
        }
    }
}

public func curryT<A, B, C>(
    _ function: @escaping ((A, B)) -> C
) -> (A) -> (B) -> C {
    { (a: A) -> (B) -> C in
        { (b: B) -> C in
            function((a, b))
        }
    }
}

public func partialApply<A, B, C>(
    _ function: @escaping (A, B) -> C,
    _ value: A
) -> (B) -> C {
    curry(function)(value)
}

/// Opposite of curry, takes a function that returns another function
/// and compresses into a single function that take both arguments at
/// once.
public func uncurry<A, B, C>(
    _ function: @escaping (A) -> (B) -> C
) -> (A, B) -> C {
    { (a: A, b: B) -> C in
        function(a)(b)
    }
}

/// Zero arguments curry, adds lazy evaluation to a value or operation
public func lazy<A, B>(_ function: @escaping (A) -> B)
-> () -> (A) -> B {
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

/// Opposite of lazy/zurry, removes the layer of Void application
/// Applies the argument Void of the curried function
public func unlazy<A, B>(
    _ function: @escaping (A) -> () -> B
) -> (A) -> B {
    { (a: A) -> B in
        function(a)()
    }
}

/// Opposite of lazy/zurry, removes the layer of Void application
/// Applies the argument Void of the curried function
public func unlazy<A, B>(
    _ function: @escaping () -> (A) -> B
) -> (A) -> B {
    { (a: A) -> B in
        function()(a)
    }
}

/// Opposite of lazy/zurry, removes the layer of Void application
/// Applies the argument Void of the curried function
public func unlazy<A>(
    _ function: @escaping () -> (A)
) -> A {
    function()
}

public func flip<A, B, C>(
    _ function: @escaping (A, B) -> C
) -> (B) -> (A) -> C {
    { (b: B) -> (A) -> C in
        { (a: A) -> C in
            function(a, b)
        }
    }
}

public func partialApplyFlip<A, B, C>(
    _ function: @escaping (A, B) -> C,
    _ value: B
) -> (A) -> C {
    flip(function)(value)
}

public func flipU<A, B, C>(
    _ function: @escaping (A, B) -> C
) -> (B, A) -> C {
    { (b: B, a: A) -> C in
        function(a, b)
    }
}

public func flip<A, B, C>(
    _ function: @escaping (A) -> (B) -> C
) -> (B) -> (A) -> C {
    { (b: B) -> (A) -> C in
        { (a: A) -> C in
            function(a)(b)
        }
    }
}

public func tuple<A, B>(_ a: A, _ b: B) -> (A, B) {
    (a, b)
}

public func tuple<A, B, C>(_ fn: @escaping (A, B) -> C) -> ((A, B)) -> C {
    { tuple in fn(tuple.0, tuple.1) }
}

public func untuple<A, B, C>(_ fn: @escaping ((A, B)) -> C) -> (A, B) -> C {
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
    _ pickArgument: @escaping ((Arg1, Arg2)) -> Picked
) -> (@escaping (Picked) -> Return) -> (Arg1, Arg2) -> Return {
    curryT(compose(compose, untuple))(pickArgument)
}

/// It returns a function that calls `fatalError`, regardless of the parameters provided.
/// All the input parameters will be ignored.
///
/// Example:
/// ```
/// init(
///     fn: @escaping (String, Int) -> AnyPublisher<String, Never> = fail("Mock not implemented")
/// ) -> Mock
/// ```
///
/// **Be careful with this function in a production code, it will crash the app if not overriden.**
public func fail<T, each U>(
    _ message: String,
    file: StaticString = #file,
    line: UInt = #line
) -> (repeat each U) -> T {
    { (_: repeat each U) -> T in
        fatalError(message, file: file, line: line)
    }
}

public func compose<A, B, C>(_ ab: @escaping (A) -> B, _ bc: @escaping (B) -> C) -> (A) -> C {
    { a in 
        bc(ab(a))
    }
}

public extension Of3 {
    static func compose(_ fn1: @escaping (T) -> U, _ fn2: @escaping (U) -> V) -> (T) -> V {
        FP.compose(fn1, fn2)
    }
}

public func compose3<A, B, C, D>(
    _ ab: @escaping (A) -> B, 
    _ bc: @escaping (B) -> C,
    _ cd: @escaping (C) -> D
) -> (A) -> D {
    { a in 
        cd(bc(ab(a)))
    }
}

public func compose4<A, B, C, D, E>(
    _ ab: @escaping (A) -> B, 
    _ bc: @escaping (B) -> C,
    _ cd: @escaping (C) -> D,
    _ de: @escaping (D) -> E
) -> (A) -> E {
    { a in 
        de(cd(bc(ab(a))))
    }
}

public func apply<A, B>(
    _ value: A,
    _ fn: (A) -> B
) -> B {
    fn(value)
}

public func call<A, B>(
    _ fn: (A) -> B,
    _ value: A
) -> B {
    fn(value)
}

public func call<A, B>() -> ((A) -> B, A) -> B {
    call
}

public func call<A, B, C>(then transform: @escaping (B) -> C) -> (@escaping (A) -> B, A) -> C {
    uncurry(partialApplyFlip(compose, transform))
}
