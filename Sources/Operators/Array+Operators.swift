import FP

// MARK: - Functor

// (<$>) :: Functor f => (a -> b) -> f a -> f b
public func <£> <A, A1>(_ transform: @escaping (A) -> A1, _ array: [A]) -> [A1] {
    Array.fmap(transform)(array)
}

// ($>) :: Functor f => f a -> b -> f b
public func £> <A, A1>(_ array: [A], _ value: A1) -> [A1] {
    Array<A>.fmap(const(value))(array)
}

// (<$) :: a -> f b -> f a
public func <£ <A, A1>(_ value: A1, _ array: [A]) -> [A1] {
    array £> value
}

// (<&>) :: Functor f => f a -> (a -> b) -> f b
public func <&> <A, A1>(_ array: [A], _ transform: @escaping (A) -> A1) -> [A1] {
    Array.fmap(transform)(array)
}

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

// MARK: - Monad

// (>>-) :: m a -> (a -> m b) -> m b
public func >>- <A, A1>(_ array: [A], _ fn: @escaping (A) -> [A1]) -> [A1] {
    array.flatMap(fn)
}

// (-<<) :: (a -> m b) -> m a -> m b
public func -<< <A, A1>(_ fn: @escaping (A) -> [A1], _ array: [A]) -> [A1] {
    array.flatMap(fn)
}

// (>=>) :: (a -> m b) -> (b -> m c) -> a -> m c
public func >=> <A0, A, A1>(
    _ fn1: @escaping (A0) -> [A],
    _ fn2: @escaping (A) -> [A1]
) -> (A0) -> [A1] {
    Array.kleisli(fn1, fn2)
}

// MARK: - Alternative

// (<|>) :: [a] -> [a] -> [a]
public func <|> <A>(_ lhs: [A], _ rhs: @autoclosure () -> [A]) -> [A] {
    Array.alt(lhs, rhs())
}

// (++) :: [a] -> [a] -> [a]
public func ++ <A>(_ lhs: [A], _ rhs: [A]) -> [A] {
    lhs + rhs
}
