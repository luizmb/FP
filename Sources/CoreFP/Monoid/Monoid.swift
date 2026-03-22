/// Monoid: a Semigroup with an identity element.
/// identity :: a
public protocol Monoid: Semigroup {
    static var identity: Self { get }
}
