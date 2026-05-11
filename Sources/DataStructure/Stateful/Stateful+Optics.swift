import CoreFP

// MARK: - Zooming Stateful computations through optics
//
// These extensions let you focus a `Stateful<Part, Result>` down to a
// `Stateful<Whole, Result>` using any optic. The whole state is always passed
// by `inout`, so the outer struct/array is never CoW-copied. Only `Part` is
// extracted and written back via the optic's get/set.
//
// For `AffineTraversal` and `Prism` the result is `Result?` because the focus
// may be absent — if the optic misses, the computation is not run and the
// state is left unchanged.

extension Lens {
    public func zoom<Result>(_ s: Stateful<A, Result>) -> Stateful<S, Result> {
        Stateful<S, Result> { whole in
            var part = get(whole)
            let result = s.run(&part)
            whole = set(whole, part)
            return result
        }
    }
}

extension Prism {
    public func zoom<Result>(_ s: Stateful<A, Result>) -> Stateful<S, Result?> {
        Stateful<S, Result?> { whole in
            guard var part = preview(whole) else { return nil }
            let result = s.run(&part)
            whole = review(part)
            return result
        }
    }
}

extension AffineTraversal {
    public func zoom<Result>(_ s: Stateful<A, Result>) -> Stateful<S, Result?> {
        Stateful<S, Result?> { whole in
            guard var part = preview(whole) else { return nil }
            let result = s.run(&part)
            whole = set(whole, part)
            return result
        }
    }
}
