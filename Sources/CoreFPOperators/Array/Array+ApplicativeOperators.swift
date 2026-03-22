import CoreFP

// MARK: - Applicative

// (<*>) :: [a -> b] -> [a] -> [b]
public func <*> <A, A1>(_ functions: [(A) -> A1], _ values: [A]) -> [A1] {
    Array.apply(functions, values)
}

// (*>) :: [a] -> [b] -> [b]
public func *> <A, A1>(_ lhs: [A], _ rhs: [A1]) -> [A1] {
    lhs.seqRight(rhs)
}

// (<*) :: [a] -> [b] -> [a]
public func <* <A, A1>(_ lhs: [A], _ rhs: [A1]) -> [A] {
    lhs.seqLeft(rhs)
}
