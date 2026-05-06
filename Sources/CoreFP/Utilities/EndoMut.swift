// MARK: - EndoMut<A>

// EndoMut wraps an in-place endomorphism — `(inout A) -> Void`.
//
// It is the cost-free companion to `Endo<A>` for Swift value types with
// Copy-on-Write (CoW) internals (Array, Dictionary, Set, String). When
// `Endo<A>` receives a value, the caller still holds a strong reference to
// every CoW buffer for the duration of the call, raising the reference count
// to at least 2. Any mutation inside the function therefore triggers an O(n)
// heap copy of the entire buffer — even if only one element changes.
//
// `EndoMut` passes the value by exclusive reference instead. Swift's Law of
// Exclusivity (SE-0176) statically guarantees that no other code holds an
// alias to the value during the call, so CoW sees a reference count of 1 and
// mutates the buffer in place — zero copying regardless of the buffer's size.
//
// The algebra is identical to `Endo<A>`: both form a `Monoid` under sequential
// application with the do-nothing closure as the identity element. `EndoMut`
// and `Endo` are isomorphic as monoids; use the `.toEndo()` / `.toEndoMut()`
// bridges to convert between them.
//
// ```swift
// var items = Array(0..<10_000)
//
// let clamp = EndoMut<[Int]> { xs in for i in xs.indices { xs[i] = min(xs[i], 100) } }
// let sort  = EndoMut<[Int]> { $0.sort() }
//
// let normalise: EndoMut<[Int]> = mconcat([clamp, sort])
// normalise.runEndoMut(&items)   // clamps first, then sorts — no copies
// normalise(&items)              // callAsFunction also works
// ```

public struct EndoMut<A> {
    public let runEndoMut: (inout A) -> Void

    public init(_ fn: @escaping (inout A) -> Void) {
        runEndoMut = fn
    }

    public func callAsFunction(_ value: inout A) {
        runEndoMut(&value)
    }
}

/// Free-function constructor — mirrors `endo { … }` style.
public func endoMut<A>(_ fn: @escaping (inout A) -> Void) -> EndoMut<A> {
    EndoMut(fn)
}
