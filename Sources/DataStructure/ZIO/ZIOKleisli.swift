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
