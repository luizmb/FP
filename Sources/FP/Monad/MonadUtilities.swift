import Foundation

// MARK: - Join (flatten nested monads)

public extension Optional {
    /// Monadic join - flattens nested Optionals
    /// join :: m (m a) -> m a
    static func join<A>(_ nested: A??) -> A? {
        nested.flatMap { $0 }
    }
}

public extension Result {
    /// Monadic join - flattens nested Results
    /// join :: m (m a) -> m a
    static func join<A>(_ nested: Result<Result<A, Failure>, Failure>) -> Result<A, Failure> {
        nested.flatMap { $0 }
    }
}

// MARK: - Void (discard result)

public extension Optional {
    /// Discards the value, keeping only the structure
    /// void :: m a -> m ()
    func void() -> Void? {
        map { _ in () }
    }
}

public extension Result {
    /// Discards the success value, keeping only the structure
    /// void :: m a -> m ()
    func void() -> Result<Void, Failure> {
        map { _ in () }
    }
}

public extension Array {
    /// Discards the values, keeping only the structure
    /// void :: m a -> m ()
    func void() -> [Void] {
        map { _ in () }
    }
}

// MARK: - Guard/Filter

public extension Optional {
    /// Filter with a predicate
    /// guard :: (a -> Bool) -> m a -> m a
    func filter(_ predicate: (Wrapped) -> Bool) -> Self {
        flatMap { value in
            predicate(value) ? .some(value) : .none
        }
    }
}

public extension Array {
    /// Monadic filter (already exists in Swift, but curried version)
    /// filter :: (a -> Bool) -> [a] -> [a]
    static func filterM(_ predicate: @escaping (Element) -> Bool) -> ([Element]) -> [Element] {
        { array in
            array.filter(predicate)
        }
    }
}

// MARK: - Traverse utilities

/// Sequence a list of optionals
/// sequence :: [m a] -> m [a]
public func sequence<A>(_ optionals: [A?]) -> [A]? {
    var result: [A] = []
    for optional in optionals {
        guard let value = optional else { return nil }
        result.append(value)
    }
    return result
}

/// Sequence a list of results
/// sequence :: [m a] -> m [a]
public func sequence<A, E>(_ results: [Result<A, E>]) -> Result<[A], E> {
    var successes: [A] = []
    for result in results {
        switch result {
        case .success(let value):
            successes.append(value)
        case .failure(let error):
            return .failure(error)
        }
    }
    return .success(successes)
}

/// Map and sequence
/// traverse :: (a -> m b) -> [a] -> m [b]
public func traverse<A, B>(_ fn: @escaping (A) -> B?) -> ([A]) -> [B]? {
    { array in
        sequence(array.map(fn))
    }
}

/// Map and sequence for Result
/// traverse :: (a -> m b) -> [a] -> m [b]
public func traverse<A, B, E>(_ fn: @escaping (A) -> Result<B, E>) -> ([A]) -> Result<[B], E> {
    { array in
        sequence(array.map(fn))
    }
}
