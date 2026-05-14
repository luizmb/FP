import CoreFP

// ZIOKleisli<Input, Env, Success, Failure>
// = (Input) -> ZIO<Env, Success, Failure>
// — a first-class Kleisli arrow in the ZIO monad.
//
// Two composition levels exist in this library:
//   (>=>)  on plain functions   : (X -> ZIO) >=> (A -> ZIO) = X -> ZIO       [ZIO+MonadOperators]
//   (>=>)  on ZIOKleisli values : ZIOKleisli<X,_,A,_> >=> ZIOKleisli<A,_,B,_> = ZIOKleisli<X,_,B,_>
//
// The ZIOKleisli level is "one up": the result is a named, first-class type
// that carries its own FAM instances and can be stored, inspected, and further composed.

/// A first-class Kleisli arrow in the ``ZIO`` monad.
///
/// `ZIOKleisli<Input, Env, Success, Failure>` is a named wrapper around the function type
/// `(Input) -> ZIO<Env, Success, Failure>`. It is the "one up" level of composition:
/// while `>=>` on plain functions produces another plain function, composing `ZIOKleisli`
/// values produces another `ZIOKleisli` — a named, first-class type that can be stored,
/// inspected, and further composed.
///
/// ## When to use ZIOKleisli vs plain functions with `>=>`
///
/// | Approach | Result type | Use when |
/// |----------|-------------|----------|
/// | `f >=> g` (plain functions) | `@Sendable (X) -> ZIO<Env, B, E>` | Inline composition |
/// | `ZIOKleisli.compose` | `ZIOKleisli<X, Env, B, E>` | Storing, naming, or further composing |
///
/// ## Creating a ZIOKleisli
///
/// ```swift
/// let getUser: ZIOKleisli<UserID, AppEnv, User, DBError> = ZIOKleisli { id in
///     ZIO { env in DeferredTask { await env.db.getUser(id: id) } }
/// }
///
/// // Lift a ZIO that ignores its input:
/// let getConfig: ZIOKleisli<Void, AppEnv, Config, DBError> = .lift(loadConfig)
/// ```
///
/// ## Composing ZIOKleisli
///
/// ```swift
/// // Operator form (requires DataStructureOperators):
/// let getPipeline: ZIOKleisli<UserID, AppEnv, Profile, DBError> =
///     getUser >=> enrichProfile
/// ```
///
/// - SeeAlso: ``ZIO``, ``DeferredTask``
public struct ZIOKleisli<Input: Sendable, Env: Sendable, Success: Sendable, Failure: Error & Sendable>: Sendable {
    public let run: @Sendable (Input) -> ZIO<Env, Success, Failure>

    public init(_ run: @escaping @Sendable (Input) -> ZIO<Env, Success, Failure>) {
        self.run = run
    }

    public func callAsFunction(_ input: Input) -> ZIO<Env, Success, Failure> {
        run(input)
    }

    /// Lift a ZIO into a ZIOKleisli that ignores its input.
    public static func lift(_ zio: ZIO<Env, Success, Failure>) -> ZIOKleisli {
        ZIOKleisli { _ in zio }
    }
}
