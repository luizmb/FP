// SPDX-License-Identifier: Apache-2.0
/// Given an input, applies it into multiple functions that takes that same input type
/// Examples:
/// - If you want the lowest and greatest elements of a `[Int]`:
/// ```swift
/// let fn: @Sendable ([Int]) -> (Int?, Int?) = fanout({ $0.min() }, { $0.max() })
/// let (min, max) = fn([9, 3, 5, 1, 16, 2])
/// ```
/// - If you want a tuple with only the name and age of a Person:
/// ```swift
/// let fn = fanout(^\Person.name, ^\Person.age)
/// fn(.fixture())
/// ```
/// - Because a key path literal converts to a `@Sendable` function, you can fan out key paths directly:
/// ```swift
/// let fn = fanout(\Person.name, \Person.age)   // @Sendable (Person) -> (String, Int)
/// ```
/// - Parameter functions: one or many functions that transform the same type of input
/// - Returns: a unified function that applies all given functions and returns a tuple
///            with all the results
public func fanout<Input, each Output>(
    _ functions: repeat (@escaping @Sendable (Input) -> each Output)
) -> @Sendable (Input) -> (repeat each Output) {
    { input in
        (repeat (each functions)(input))
    }
}

/// Fans a root out over several **key paths** and feeds the results straight into a multi-argument
/// initializer (or any multi-argument function) — the symbol-free counterpart of `fanout(…) >>> make`.
///
/// Where ``fanout(_:)-tuple`` produces the intermediate tuple, this variant closes the loop: give it the
/// key paths to read and the function that consumes those reads positionally, and it returns the composed
/// `Root -> Output` in one step. It's the point-free way to narrow a large value (a `World`, a parent
/// environment) down to a smaller one whose initializer takes the pieces as separate arguments.
///
/// ```swift
/// struct Env: Sendable { init(badge: Int, save: @Sendable () -> Void) { … } }
///
/// // Instead of `fanout(\.badge, \.save) >>> Env.init`:
/// let narrow: @Sendable (World) -> Env = fanout(keypaths: \.badge, \.save, into: Env.init)
/// ```
///
/// - Parameters:
///   - keypaths: the key paths from `Root` to each argument of `make`, in order. Each is constrained to
///     `Sendable` so the resulting closure stays `Sendable`.
///   - make: a function taking the read values positionally — typically a memberwise `init`.
/// - Returns: a `Sendable` function that reads every key path from a `Root` and applies `make` to them.
public func fanout<Root, each T, Output>(
    keypaths: repeat KeyPath<Root, each T> & Sendable,
    into make: @escaping @Sendable (repeat each T) -> Output
) -> @Sendable (Root) -> Output {
    { root in make(repeat root[keyPath: each keypaths]) }
}
