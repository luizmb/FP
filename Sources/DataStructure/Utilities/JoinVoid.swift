import CoreFP

// MARK: - join / void free functions for DataStructure types
//
// These free functions mirror the join/void free functions in CoreFP/Utilities/JoinVoid.swift
// but target the DataStructure monad types: Either, Reader, Stateful, Writer.
//
// join :: Monad m => m (m a) -> m a     (flattens one layer of nesting)
// void :: Functor f => f a -> f ()      (discards values, keeps structure)
//
// Available overloads:
//   join(Either<L, Either<L, A>>)           -> Either<L, A>
//   join(Reader<Env, Reader<Env, A>>)       -> Reader<Env, A>
//   join(Stateful<S, Stateful<S, A>>)       -> Stateful<S, A>
//   join(Writer<W, Writer<W, A>>)           -> Writer<W, A>
//
//   void(Either<L, A>)                      -> Either<L, Void>
//   void(Reader<Env, A>)                    -> Reader<Env, Void>
//   void(Stateful<S, A>)                    -> Stateful<S, Void>
//   void(Writer<W, A>)                      -> Writer<W, Void>
//   void(Validation<E, A>)                  -> Validation<E, Void>  (Functor only — no Monad)

// MARK: - Either

public func join<L, A>(_ nested: Either<L, Either<L, A>>) -> Either<L, A> {
    Either.join(nested)
}

public func void<L, A>(_ fa: Either<L, A>) -> Either<L, Void> {
    fa.void()
}

// MARK: - Reader

public func join<Env, A>(_ nested: Reader<Env, Reader<Env, A>>) -> Reader<Env, A> {
    Reader.join(nested)
}

public func void<Env, A>(_ fa: Reader<Env, A>) -> Reader<Env, Void> {
    fa.void()
}

// MARK: - Stateful

public func join<S, A>(_ nested: Stateful<S, Stateful<S, A>>) -> Stateful<S, A> {
    Stateful.join(nested)
}

public func void<S, A>(_ fa: Stateful<S, A>) -> Stateful<S, Void> {
    fa.void()
}

// MARK: - Writer

public func join<W: Monoid, A>(_ nested: Writer<W, Writer<W, A>>) -> Writer<W, A> {
    Writer.join(nested)
}

public func void<W: Monoid, A>(_ fa: Writer<W, A>) -> Writer<W, Void> {
    fa.void()
}

// MARK: - Validation (Functor only — no Monad join)

public func void<E: Semigroup, A>(_ fa: Validation<E, A>) -> Validation<E, Void> {
    fa.void()
}
