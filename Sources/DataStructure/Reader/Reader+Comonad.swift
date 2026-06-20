// SPDX-License-Identifier: Apache-2.0
import CoreFP

public extension Reader where Environment: Monoid & Sendable {
    /// extract :: Reader Env A -> A
    /// Run the reader with the Monoid identity (empty environment).
    var extract: Output { runReader(Environment.identity) }

    /// extend :: (Reader Env A -> B) -> Reader Env A -> Reader Env B
    /// extend f r = Reader { e -> f (Reader { e' -> r.run(e <> e') }) }
    /// For each outer env e, build a "shifted" reader and apply f.
    func extend<B>(_ f: @escaping @Sendable (Reader<Environment, Output>) -> B) -> Reader<Environment, B> {
        Reader<Environment, B> { e in
            f(Reader { e2 in self.runReader(Environment.combine(e, e2)) })
        }
    }

    /// coflatMap is extend with arguments in the more familiar (value-first) order.
    func coflatMap<B>(_ f: @escaping @Sendable (Reader<Environment, Output>) -> B) -> Reader<Environment, B> {
        extend(f)
    }

    /// duplicate :: Reader Env A -> Reader Env (Reader Env A)
    /// duplicate r = Reader { e -> Reader { e' -> r.run(e <> e') } }
    var duplicate: Reader<Environment, Reader<Environment, Output>> {
        extend(id)
    }

    /// Curried static form for point-free use.
    static func extend<B>(
        _ f: @escaping @Sendable (Reader<Environment, Output>) -> B
    ) -> (Reader<Environment, Output>) -> Reader<Environment, B> {
        { $0.extend(f) }
    }
}

/// extract :: Reader Env A -> A  (requires Env: Monoid)
public func extract<Env: Monoid & Sendable, A>(_ reader: Reader<Env, A>) -> A {
    reader.extract
}

/// extend :: (Reader Env A -> B) -> Reader Env A -> Reader Env B  (requires Env: Monoid)
public func extend<Env: Monoid & Sendable, A, B>(
    _ f: @escaping @Sendable (Reader<Env, A>) -> B
) -> (Reader<Env, A>) -> Reader<Env, B> {
    { $0.extend(f) }
}

/// duplicate :: Reader Env A -> Reader Env (Reader Env A)  (requires Env: Monoid)
public func duplicate<Env: Monoid & Sendable, A>(_ reader: Reader<Env, A>) -> Reader<Env, Reader<Env, A>> {
    reader.duplicate
}
