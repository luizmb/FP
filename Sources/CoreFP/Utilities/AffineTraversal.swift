/// An optic that focuses on zero or one value inside `S`. It is the result of composing a
/// `Lens` with a `Prism` (in either order), and combines the "always-present whole" guarantee
/// of a lens with the "maybe-present focus" of a prism.
public struct AffineTraversal<S, A>: @unchecked Sendable {
    public let preview: (S) -> A?
    public let set: (S, A) -> S

    public init(preview: @escaping (S) -> A?, set: @escaping (S, A) -> S) {
        self.preview = preview
        self.set = set
    }

    public func over(_ transform: @escaping (A) -> A) -> (S) -> S {
        { s in preview(s).map { set(s, transform($0)) } ?? s }
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
        set: { s, a in
            var copy = s
            copy[keyPath: keyPath] = a
            return copy
        }
    )
}

extension AffineTraversal where S == A {
    /// The identity `AffineTraversal`: preview always succeeds and set replaces the whole.
    /// Equivalent to composing `Lens.id` with `Prism.id`.
    public static var id: AffineTraversal<S, S> {
        AffineTraversal(preview: { .some($0) }, set: { _, a in a })
    }
}
