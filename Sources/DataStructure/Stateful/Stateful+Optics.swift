// SPDX-License-Identifier: Apache-2.0
import CoreFP

// MARK: - Zooming Stateful computations through optics
//
// `zoom` lifts a `Stateful<Part, Result>` to a `Stateful<Whole, Result>` by
// routing the optic's focus through the stateful computation.
//
// ## Copy cost
//
// The outer `Whole` is always passed by `inout`, so no CoW copy occurs on
// `Whole` itself. `Part` is extracted via the optic's `get` (one copy), the
// computation runs against `inout Part`, then `Part` is written back via `set`.
// This is equivalent to using the synthesised `modifyMut` path.
//
// For the Void-result case this is identical to `lift` — prefer `lift` when
// the computation does not need to return a value:
//
//     lens.lift(myEndoMut)           // EndoMut<Whole> — zero alloc
//     lens.zoom(myEndoMut.toStateful()) // same cost, different return type
//
// ## Optional results (Prism and AffineTraversal)
//
// `Prism.zoom` and `AffineTraversal.zoom` return `Stateful<Whole, Result?>`.
// When the optic's focus is absent the computation is not run, `Whole` is left
// unchanged, and the result is `nil`.

// ## zoom vs lift
//
// | Method | Returns | Use when |
// |--------|---------|----------|
// | `lens.lift(endoMut)` | `EndoMut<Whole>` | No return value needed, maximum efficiency |
// | `lens.zoom(stateful)` | `Stateful<Whole, Result>` | The stateful computation returns a value |

extension Lens {
    /// Lifts a `Stateful<A, Result>` to `Stateful<S, Result>` through this lens.
    ///
    /// `S` is `inout` throughout; `A` is copied once via `get`+`set`.
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
    /// Lifts a `Stateful<A, Result>` to `Stateful<S, Result?>` through this prism.
    ///
    /// Returns `nil` and leaves `S` unchanged when the focus is absent.
    /// When present, copies the enum case value once; `S` is `inout` throughout.
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
    /// Lifts a `Stateful<A, Result>` to `Stateful<S, Result?>` through this traversal.
    ///
    /// Returns `nil` and leaves `S` unchanged when the focus is absent.
    /// When present, copies `A` once via `preview`+`set`; `S` is `inout` throughout.
    public func zoom<Result>(_ s: Stateful<A, Result>) -> Stateful<S, Result?> {
        Stateful<S, Result?> { whole in
            guard var part = preview(whole) else { return nil }
            let result = s.run(&part)
            whole = set(whole, part)
            return result
        }
    }
}
