// SPDX-License-Identifier: Apache-2.0
/// Opt-in protocol that provides a fluent `mutate` method for value types.
///
/// Conforming types gain a `mutate` method that makes it easy to create modified
/// copies of value types inline, without needing temporary `var` bindings.
///
/// ## Usage
///
/// ```swift
/// struct Config: Mutable {
///     var timeout: TimeInterval = 30
///     var retries: Int = 3
/// }
///
/// let tweaked = Config().mutate { $0.timeout = 60 }
/// // tweaked.timeout == 60, tweaked.retries == 3
///
/// // Or using the pure-function overload:
/// let doubled = config.mutate { cfg in Config(timeout: cfg.timeout * 2, retries: cfg.retries) }
/// ```
///
/// - SeeAlso: ``EndoMut`` for a composable, named mutation container.
public protocol Mutable {}

public extension Mutable where Self: Any {
    /// Returns a mutated copy of `self` by applying the `inout` transform.
    ///
    /// ```swift
    /// let frame = CGRect().mutate {
    ///     $0.origin.x = 10
    ///     $0.size.width = 100
    /// }
    /// ```
    @discardableResult func mutate(_ transform: (inout Self) -> Void) -> Self {
        var copy = self
        transform(&copy)
        return copy
    }

    /// Returns a transformed copy of `self` by applying the pure function.
    @discardableResult func mutate(_ transform: (Self) -> Self) -> Self {
        transform(self)
    }
}
