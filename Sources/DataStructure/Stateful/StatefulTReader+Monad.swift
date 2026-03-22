import Foundation
import CoreFP

// StatefulT + Reader — Stateful<S, Reader<Env, A>>
//
// flatMapT is not implementable for this transformer stack: Reader's init
// takes an @escaping closure, which cannot capture an `inout` parameter.
// The state `S` in `(inout S) -> A` cannot be shared with the Reader's
// deferred environment-application closure.
//
// Use Stateful<S, Either<L, A>> or Stateful<S, A?> for monad sequencing.
