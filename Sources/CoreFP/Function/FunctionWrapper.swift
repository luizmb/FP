/// A protocol for types that wrap a single function `(Input) -> Output`.
///
/// `FunctionWrapper` provides a uniform interface for newtype wrappers around functions.
/// Types conforming to this protocol can be initialised from a closure and called directly
/// via `callAsFunction`. This enables:
///
/// - **Nominal typing**: wrapping the same function type `(A) -> B` in distinct named types
///   (e.g. ``Endo``, ``Reader``) to clarify intent and prevent mix-ups.
/// - **Protocol conformances**: attaching `Functor`, `Monad`, etc. to a specific wrapper
///   rather than the raw function type.
/// - **Sendable / `@Sendable` enforcement**: each wrapper can specify its own sendability.
///
/// ## Conforming types
///
/// | Type | Input | Output | Purpose |
/// |------|-------|--------|---------|
/// | ``Endo``<A> | `A` | `A` | Pure endomorphism |
/// | ``Reader``<Env, A> | `Env` | `A` | Environment-dependent computation |
///
/// ## Requirements
///
/// - `init(_ fn:)`: initialise from a closure.
/// - `callAsFunction(_ input:)`: invoke the wrapped function directly.
///
/// ## Example
///
/// ```swift
/// struct MyWrapper<A, B>: FunctionWrapper {
///     typealias Input = A
///     typealias Output = B
///     let fn: (A) -> B
///     init(_ fn: @escaping @Sendable (A) -> B) { self.fn = fn }
///     func callAsFunction(_ input: A) -> B { fn(input) }
/// }
/// ```
public protocol FunctionWrapper<Input, Output>: Sendable {
    associatedtype Input
    associatedtype Output

    /// Initialise the wrapper from a closure.
    init(_ fn: @escaping @Sendable (Input) -> Output)
    /// Invoke the wrapped function.
    func callAsFunction(_ input: Input) -> Output
}
