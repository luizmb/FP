// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// StatefulT + NonEmpty — free functions for Stateful<S, NonEmpty<A>>

/// apply for Stateful<S, NonEmpty>
public func applyStatefulNonEmpty<S, A, B>(
    _ sf: Stateful<S, NonEmpty<@Sendable (A) -> B>>,
    _ sa: Stateful<S, NonEmpty<A>>
) -> Stateful<S, NonEmpty<B>> {
    Stateful<S, NonEmpty<B>> { s in
        NonEmpty.apply(sf.run(&s), sa.run(&s))
    }
}

/// liftA2 for Stateful<S, NonEmpty>
public func liftA2StatefulNonEmpty<S, A, B, C>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (Stateful<S, NonEmpty<A>>, Stateful<S, NonEmpty<B>>) -> Stateful<S, NonEmpty<C>> where A: Sendable {
    { sa, sb in
        Stateful<S, NonEmpty<C>> { s in
            NonEmpty.liftA2(fn)(sa.run(&s), sb.run(&s))
        }
    }
}

/// seqRight for Stateful<S, NonEmpty>
public func seqRightStatefulNonEmpty<S, A, B>(
    _ lhs: Stateful<S, NonEmpty<A>>,
    _ rhs: Stateful<S, NonEmpty<B>>
) -> Stateful<S, NonEmpty<B>> {
    Stateful<S, NonEmpty<B>> { s in lhs.run(&s).seqRight(rhs.run(&s)) }
}

/// seqLeft for Stateful<S, NonEmpty>
public func seqLeftStatefulNonEmpty<S, A, B>(
    _ lhs: Stateful<S, NonEmpty<A>>,
    _ rhs: Stateful<S, NonEmpty<B>>
) -> Stateful<S, NonEmpty<A>> {
    Stateful<S, NonEmpty<A>> { s in lhs.run(&s).seqLeft(rhs.run(&s)) }
}
