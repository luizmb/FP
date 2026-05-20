import CoreFP
import Foundation

// StatefulT + Optional — free functions for Stateful<S, A?>

/// apply for Stateful<S, Optional>
public func applyStatefulOptional<S, A, B>(
    _ sf: Stateful<S, (@Sendable (A) -> B)?>,
    _ sa: Stateful<S, A?>
) -> Stateful<S, B?> {
    Stateful<S, B?> { s in
        guard let fn = sf.run(&s), let a = sa.run(&s) else { return nil }
        return fn(a)
    }
}

/// liftA2 for Stateful<S, Optional>
public func liftA2StatefulOptional<S, A, B, C>(
    _ fn: @escaping @Sendable (A, B) -> C
) -> (Stateful<S, A?>, Stateful<S, B?>) -> Stateful<S, C?> {
    { sa, sb in
        Stateful<S, C?> { s in
            guard let a = sa.run(&s), let b = sb.run(&s) else { return nil }
            return fn(a, b)
        }
    }
}

/// seqRight for Stateful<S, Optional>
public func seqRightStatefulOptional<S, A, B>(
    _ lhs: Stateful<S, A?>,
    _ rhs: Stateful<S, B?>
) -> Stateful<S, B?> {
    Stateful<S, B?> { s in lhs.run(&s).seqRight(rhs.run(&s)) }
}

/// seqLeft for Stateful<S, Optional>
public func seqLeftStatefulOptional<S, A, B>(
    _ lhs: Stateful<S, A?>,
    _ rhs: Stateful<S, B?>
) -> Stateful<S, A?> {
    Stateful<S, A?> { s in lhs.run(&s).seqLeft(rhs.run(&s)) }
}
