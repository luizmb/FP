public protocol Mutable {}

public extension Mutable where Self: Any {
    /// Makes it available to set properties with closures just after initializing and copying the value types.
    ///
    ///     let frame = CGRect().with {
    ///       $0.origin.x = 10
    ///       $0.size.width = 100
    ///     }
    @discardableResult func mutate(_ transform: (inout Self) -> Void) -> Self {
        var copy = self
        transform(&copy)
        return copy
    }

    @discardableResult func mutate(_ transform: (Self) -> Self) -> Self {
        transform(self)
    }
}
