/// Semigroup: a type with an associative binary operation.
/// combine :: a -> a -> a
public protocol Semigroup {
    static func combine(_ lhs: Self, _ rhs: Self) -> Self
}
