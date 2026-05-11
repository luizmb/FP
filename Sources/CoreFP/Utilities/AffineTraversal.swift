/// An optic that focuses on zero or one value inside `S`. It is the result of composing a
/// `Lens` with a `Prism` (in either order), and combines the "always-present whole" guarantee
/// of a lens with the "maybe-present focus" of a prism.
public struct AffineTraversal<S, A>: @unchecked Sendable {
    public let preview: (S) -> A?
    public let set: (S, A) -> S
    public let tryModifyMut: (inout S, (inout A) -> Void) -> Void

    public init(preview: @escaping (S) -> A?, set: @escaping (S, A) -> S) {
        self.preview = preview
        self.set = set
        self.tryModifyMut = { s, f in
            guard var part = preview(s) else { return }
            f(&part)
            s = set(s, part)
        }
    }

    public init(preview: @escaping (S) -> A?, set: @escaping (S, A) -> S,
                tryModifyMut: @escaping (inout S, (inout A) -> Void) -> Void) {
        self.preview = preview
        self.set = set
        self.tryModifyMut = tryModifyMut
    }

    public func callAsFunction(_ whole: S) -> A? { preview(whole) }

    public func over(_ transform: @escaping (A) -> A) -> (S) -> S {
        { s in preview(s).map { set(s, transform($0)) } ?? s }
    }

    public func lift(_ f: EndoMut<A>) -> EndoMut<S> {
        EndoMut { s in tryModifyMut(&s) { a in f(&a) } }
    }
}

extension AffineTraversal where S == A {
    public static var id: AffineTraversal<S, S> {
        AffineTraversal(preview: { .some($0) }, set: { _, a in a }, tryModifyMut: { s, f in f(&s) })
    }
}

/// Lifts a `WritableKeyPath` to an optional property into an `AffineTraversal`.
/// Preview reads the optional; set writes the non-nil focus back as `.some`.
///
/// This is the bridge between optional writable subscripts and optics:
/// ```swift
/// affineTraversal(\[Int][safe: 2])  // AffineTraversal<[Int], Int> — same as ix(2)
/// ```
public func affineTraversal<S, A>(_ keyPath: WritableKeyPath<S, A?>) -> AffineTraversal<S, A> {
    AffineTraversal(
        preview: { $0[keyPath: keyPath] },
        set: { s, a in var c = s; c[keyPath: keyPath] = a; return c },
        tryModifyMut: { s, f in
            guard var value = s[keyPath: keyPath] else { return }
            f(&value)
            s[keyPath: keyPath] = value
        }
    )
}
