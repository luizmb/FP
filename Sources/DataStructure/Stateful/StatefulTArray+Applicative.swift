// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Foundation

// StatefulT + Array — free functions for Stateful<S, [A]>

/// apply for Stateful<S, Array>
public func applyStatefulArray<S, A, B>(
    _ sf: Stateful<S, [@Sendable (A) -> B]>,
    _ sa: Stateful<S, [A]>
) -> Stateful<S, [B]> {
    Stateful<S, [B]> { s in
        let fns = sf.run(&s)
        let values = sa.run(&s)
        return fns.flatMap(values.map)
    }
}

/// liftA2 for Stateful<S, Array>
public func liftA2StatefulArray<S, A, B, C>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (Stateful<S, [A]>, Stateful<S, [B]>) -> Stateful<S, [C]> {
    { sa, sb in
        Stateful<S, [C]> { s in
            Array.liftA2(fn)(sa.run(&s), sb.run(&s))
        }
    }
}

/// seqRight for Stateful<S, Array>
public func seqRightStatefulArray<S, A, B>(
    _ lhs: Stateful<S, [A]>,
    _ rhs: Stateful<S, [B]>
) -> Stateful<S, [B]> {
    Stateful<S, [B]> { s in lhs.run(&s).seqRight(rhs.run(&s)) }
}

/// seqLeft for Stateful<S, Array>
public func seqLeftStatefulArray<S, A, B>(
    _ lhs: Stateful<S, [A]>,
    _ rhs: Stateful<S, [B]>
) -> Stateful<S, [A]> {
    Stateful<S, [A]> { s in lhs.run(&s).seqLeft(rhs.run(&s)) }
}
