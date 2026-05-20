import Foundation

/// A computation that reads and modifies a mutable state `S`, producing a value `A`.
///
/// `Stateful<S, A>` is the classic State monad in Swift, with the twist that `S` is
/// passed as `inout` for zero-copy semantics on CoW types. It wraps a function
/// `(inout S) -> A` and provides a monadic API for composing stateful computations.
///
/// ## When to use Stateful
///
/// Use `Stateful` when you want to thread a mutable state through a chain of computations
/// without explicitly passing `inout` at every call site. It is the pure-FP alternative
/// to classes with mutable properties.
///
/// ## Creating Stateful computations
///
/// ```swift
/// // Primitive operations:
/// let getCount: Stateful<Int, Int> = .get          // reads state
/// let increment: Stateful<Int, Void> = .modify { $0 + 1 }
/// let reset: Stateful<Int, Void> = .put(0)
///
/// // Custom:
/// let pop: Stateful<[String], String?> = Stateful { stack in
///     guard !stack.isEmpty else { return nil }
///     return stack.removeLast()
/// }
/// ```
///
/// ## Running a Stateful computation
///
/// ```swift
/// let (value, finalState) = stateful.runStateful(initialState)
/// let value = stateful.eval(initialState)    // result only
/// let state = stateful.exec(initialState)    // final state only
/// ```
///
/// ## Functor / Applicative / Monad
///
/// ```swift
/// let doubled: Stateful<Int, Int> = getCount.map { $0 * 2 }
///
/// let combined: Stateful<[String], (String?, String?)> =
///     pop.flatMap { first in pop.map { second in (first, second) } }
///
/// // Operator forms (requires DataStructureOperators):
/// let mapped = getCount <&> { $0 * 2 }
/// let chained = pop >>- { first in pop.map { second in (first, second) } }
/// ```
///
/// ## Primitive operations
///
/// | Factory | Type | Description |
/// |---------|------|-------------|
/// | `.get` | `Stateful<S, S>` | Return the current state |
/// | `.gets(f)` | `Stateful<S, B>` | Extract a derived value from the state |
/// | `.put(s)` | `Stateful<S, Void>` | Replace the state with a new value |
/// | `.modify(f)` | `Stateful<S, Void>` | Transform the state with a pure function |
/// | `.modifyInPlace(f)` | `Stateful<S, Void>` | Transform the state with an `inout` closure |
/// | `.pure(a)` | `Stateful<S, A>` | Lift a value without touching the state |
///
/// - SeeAlso: ``Reader``, ``Writer``, ``EndoMut``
public struct Stateful<S, A>: Sendable {
    /// The underlying state-transforming function.
    public let run: @Sendable (inout S) -> A

    public init(_ fn: @escaping @Sendable (inout S) -> A) {
        run = fn
    }

    /// Execute the computation, mutating `state` in place and returning the produced value.
    @discardableResult
    public func callAsFunction(_ state: inout S) -> A { run(&state) }

    /// Execute the computation starting from `initial`, returning only the produced value.
    /// The final state is discarded.
    public func eval(_ initial: S) -> A {
        var s = initial
        return run(&s)
    }

    /// Execute the computation starting from `initial`, returning only the final state.
    /// The produced value is discarded.
    public func exec(_ initial: S) -> S {
        var s = initial
        _ = run(&s)
        return s
    }

    /// Execute the computation starting from `initial`, returning `(value, finalState)`.
    public func runStateful(_ initial: S) -> (A, S) {
        var s = initial
        let a = run(&s)
        return (a, s)
    }
}
