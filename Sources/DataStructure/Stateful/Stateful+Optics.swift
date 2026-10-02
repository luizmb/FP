// SPDX-License-Identifier: Apache-2.0
import CoreFP

// MARK: - Zooming Stateful computations through optics

//
// `zoom` lifts a `Stateful<Part, Result>` to a `Stateful<Whole, Result>` by
// routing the optic's focus through the stateful computation.
//
// ## Copy cost
//
// The outer `Whole` is always passed by `inout`, and the computation runs against
// the focus through the optic's own `modifyMut` / `tryModifyMut`. For key-path
// optics that is a true in-place mutation: zooming into `\.items` and appending
// doesn't copy `items` or `Whole`.
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

public extension Lens {
    /// Lifts a `Stateful<A, Result>` to `Stateful<S, Result>` through this lens.
    ///
    /// Runs through the lens's `modifyMut`, so a key-path lens mutates the focus in place.
    func zoom<Result>(_ s: Stateful<A, Result>) -> Stateful<S, Result> {
        Stateful<S, Result> { whole in
            var result: Result?
            modifyMut(&whole) { part in result = s.run(&part) }
            // A lawful lens's modifyMut calls its body exactly once. Fall back to get/set for
            // a hand-built one that doesn't, rather than trapping.
            guard let result else {
                var part = get(whole)
                let fallback = s.run(&part)
                whole = set(whole, part)
                return fallback
            }
            return result
        }
    }
}

public extension Prism {
    /// Lifts a `Stateful<A, Result>` to `Stateful<S, Result?>` through this prism.
    ///
    /// Returns `nil` and leaves `S` unchanged when the focus is absent.
    /// Runs through the prism's `tryModifyMut`.
    func zoom<Result>(_ s: Stateful<A, Result>) -> Stateful<S, Result?> {
        Stateful<S, Result?> { whole in
            var result: Result?
            tryModifyMut(&whole) { part in result = s.run(&part) }
            return result
        }
    }
}

public extension AffineTraversal {
    /// Lifts a `Stateful<A, Result>` to `Stateful<S, Result?>` through this traversal.
    ///
    /// Returns `nil` and leaves `S` unchanged when the focus is absent.
    /// Runs through the traversal's `tryModifyMut`, so a key-path traversal mutates in place.
    func zoom<Result>(_ s: Stateful<A, Result>) -> Stateful<S, Result?> {
        Stateful<S, Result?> { whole in
            var result: Result?
            tryModifyMut(&whole) { part in result = s.run(&part) }
            return result
        }
    }
}
