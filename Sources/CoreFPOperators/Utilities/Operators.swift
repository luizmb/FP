// SPDX-License-Identifier: Apache-2.0
/// Append / list concatenation. (`++` in Haskell)
///
/// Appends the right-hand sequence to the left-hand sequence.
///
/// **Precedence:** `AppendToList` (right-associative, between `AdditionPrecedence` and `RangeFormationPrecedence`).
///
/// ```swift
/// [1, 2] ++ [3, 4]    // [1, 2, 3, 4]
/// ```
infix operator ++: AppendToList

/// Semigroup concatenation. (`<>` in Haskell)
///
/// Combines two ``Semigroup`` values using ``Semigroup/combine(_:_:)``.
///
/// **Named equivalent:** ``Semigroup/combine(_:_:)``
///
/// **Precedence:** `ConcatPrecedence` (right-associative, between `MultiplicationPrecedence` and `AdditionPrecedence`).
///
/// ```swift
/// [1, 2] <> [3, 4]              // [1, 2, 3, 4]
/// "hello" <> " world"           // "hello world"
/// Endo { $0 + 1 } <> Endo { $0 * 2 }  // +1 then *2
/// ```
infix operator <>: ConcatPrecedence

/// Applicative apply. (`<*>` in Haskell)
///
/// Applies a wrapped function to a wrapped value. The specific behaviour depends on the functor:
/// - `Optional`: both must be non-nil.
/// - `Array`: Cartesian product — every function applied to every value.
/// - `Result`/`Either`: short-circuits on the first error.
/// - ``Validation``: accumulates errors via ``Semigroup``.
///
/// **Named equivalent:** `apply` (varies per type).
///
/// **Precedence:** `FunctorOps` (left-associative, below `NilCoalescingPrecedence`).
///
/// ```swift
/// Optional.some({ $0 + 1 }) <*> Optional.some(5)   // Optional(6)
/// [(+1), (*2)] <*> [10, 20]                         // [11, 21, 20, 40]
/// ```
infix operator <*>: FunctorOps

/// Applicative sequence-right — run both, discard the left result. (`*>` in Haskell)
///
/// Runs both effects; the right-hand value is returned. Errors from the left still propagate.
///
/// **Precedence:** `FunctorOps`.
///
/// ```swift
/// Optional.some(()) *> Optional.some(42)   // Optional(42)
/// Optional.none *> Optional.some(42)       // nil
/// ```
infix operator *>: FunctorOps

/// Applicative sequence-left — run both, discard the right result. (`<*` in Haskell)
///
/// Runs both effects; the left-hand value is returned. Errors from the right still propagate.
///
/// **Precedence:** `FunctorOps`.
///
/// ```swift
/// Optional.some(42) <* Optional.some(())   // Optional(42)
/// Optional.some(42) <* Optional.none       // nil
/// ```
infix operator <*: FunctorOps

/// Alternative / fallback selection. (`<|>` in Haskell)
///
/// Returns the left-hand value if it represents a "success", otherwise falls back to the right.
/// The exact meaning of "success" depends on the type:
/// - `Optional`: returns left if non-nil, otherwise evaluates and returns right.
/// - `Array`: concatenation (both arrays are kept).
/// - `Either`/`Result`: left-biased — returns left `.right` if present.
///
/// **Precedence:** `AlternativePrecedence` (left-associative, below `NilCoalescingPrecedence`).
///
/// ```swift
/// Optional.some(1) <|> Optional.some(2)   // Optional(1)
/// Optional.none <|> Optional.some(2)       // Optional(2)
/// [1, 2] <|> [3, 4]                        // [1, 2, 3, 4]
/// ```
infix operator <|>: AlternativePrecedence

/// Kleisli composition (left-to-right). (`>=>` in Haskell)
///
/// Composes two Kleisli arrows `(A) -> M<B>` and `(B) -> M<C>` into `(A) -> M<C>`.
/// The resulting function applies the first arrow, then feeds its result to the second.
///
/// **Named equivalent:** `kleisli` (varies per type).
///
/// **Precedence:** `KleisliCompositionRight` (right-associative, priority 1).
///
/// ```swift
/// // Optional:
/// let firstNonZeroDigit: (String) -> Int? = Int.init >=> { $0 > 0 ? $0 : nil }
/// ```
infix operator >=>: KleisliCompositionRight

/// Reverse Kleisli composition (right-to-left). (`<=<` in Haskell)
///
/// Like `>=>` but with arguments flipped: `g <=< f == f >=> g`.
///
/// **Precedence:** `KleisliCompositionRight` (right-associative, priority 1).
///
/// ```swift
/// // Optional:
/// let firstNonZeroDigit: (String) -> Int? = { $0 > 0 ? $0 : nil } <=< Int.init
/// ```
infix operator <=<: KleisliCompositionRight

/// Monadic bind (left-to-right). (`>>=` in Haskell, renamed to avoid conflict with Swift's `>>=` bitwise operator)
///
/// Sequences a monadic value with a function that returns another monadic value.
///
/// **Named equivalent:** `flatMap` (varies per type).
///
/// **Precedence:** `MonadBindLeft` (left-associative, priority 1).
///
/// ```swift
/// Optional.some(5) >>- { $0 > 0 ? .some($0 * 2) : .none }   // Optional(10)
/// [1, 2, 3] >>- { [$0, -$0] }                                // [1, -1, 2, -2, 3, -3]
/// ```
infix operator >>-: MonadBindLeft

/// Flipped monadic bind (right-to-left). (`=<<` in Haskell)
///
/// Like `>>-` but with arguments flipped: `f -<< m == m >>- f`.
///
/// **Precedence:** `KleisliCompositionRight` (right-associative, priority 1).
///
/// ```swift
/// { $0 > 0 ? .some($0 * 2) : .none } -<< Optional.some(5)   // Optional(10)
/// ```
infix operator -<<: KleisliCompositionRight

/// Comonad extend / coflatMap (left-to-right). (dual of `>>=`)
///
/// `w ->> f` is equivalent to `w.extend(f)`. The function receives the whole comonadic
/// context `W<A>` and produces a `B`; the result is `W<B>`.
///
/// **Named equivalent:** `extend` / `coflatMap` (varies per type).
///
/// **Precedence:** `MonadBindLeft` (left-associative, priority 1).
///
/// ```swift
/// writer ->> { w in w.value + w.log.count }
/// ```
infix operator ->>: MonadBindLeft

/// Flipped comonad extend (right-to-left). (dual of `-<<`)
///
/// `f <<- w` is equivalent to `w.extend(f)`. Like `(->>)` but with arguments flipped.
///
/// **Precedence:** `KleisliCompositionRight` (right-associative, priority 1).
///
/// ```swift
/// { w in w.value + w.log.count } <<- writer
/// ```
infix operator <<-: KleisliCompositionRight

/// Flipped pattern-matching / range membership. (symbolic)
///
/// `value ≅ range` checks whether `value` is contained in `range`.
/// This is the flipped version of the `~=` pattern-matching operator.
///
/// **Precedence:** `ComparisonPrecedence`.
///
/// ```swift
/// statusCode ≅ 200...299        // true if in range
/// temperature ≅ 20.0...25.0    // true if in range
/// ```
infix operator ≅: ComparisonPrecedence

/// Symmetric range operator — `center ± delta` produces a `ClosedRange`.
///
/// **Precedence:** `RangeFormationPrecedence`.
///
/// ```swift
/// 5.0 ± 0.5    // 4.5...5.5
/// 20 ± 3       // 17...23
/// ```
infix operator ±: RangeFormationPrecedence

/// ASCII alias for `±`. (`center +/- delta` → `ClosedRange`)
///
/// **Precedence:** `RangeFormationPrecedence`.
infix operator +/-: RangeFormationPrecedence

/// Left-to-right function and optic composition.
///
/// `f >>> g` applies `f` first, then `g`. Also overloaded for optic composition
/// (``Lens``, ``Prism``, ``AffineTraversal``, ``Iso``) in `CoreFPOperators/Utilities/`.
///
/// **Named equivalent (functions):** ``compose(_:_:)``
///
/// **Precedence:** `FunctionCompositionForward` (right-associative, highest custom precedence).
///
/// ```swift
/// let pipeline: (String) -> Bool = { $0.trimmingCharacters(in: .whitespaces) } >>> { !$0.isEmpty }
///
/// // Optic composition:
/// let streetLens = ^\AppState.address >>> ^\Address.street   // Lens<AppState, String>
/// ```
infix operator >>>: FunctionCompositionForward

/// Right-to-left function and optic composition.
///
/// `g <<< f` is equivalent to `f >>> g`. Also overloaded for optic composition.
///
/// **Precedence:** `FunctionCompositionBackwards` (right-associative).
///
/// ```swift
/// let pipeline = validate <<< parse <<< fetch  // reads right-to-left
/// ```
infix operator <<<: FunctionCompositionBackwards

/// Function application with lowest right-associative precedence. (`$` in Haskell)
///
/// `f £ x` applies `f` to `x`. Its extremely low precedence means all other operators
/// on the right-hand side are evaluated first, eliminating deep parentheses nesting.
///
/// **Named equivalent:** ``apply(_:_:)``
///
/// **Precedence:** `LowPrecedenceFunctionCallRight` (right-associative, lower than ternary).
///
/// ```swift
/// f £ g £ x           // f(g(x))
/// not £ isValid £ input  // not(isValid(input))
/// ```
infix operator £: LowPrecedenceFunctionCallRight

/// ASCII alternative to `£` — function application with lowest right-associative precedence.
///
/// `f <| x` is identical to `f £ x`. Use whichever is more readable in context.
///
/// **Named equivalent:** ``call(_:_:)``
///
/// **Precedence:** `LowPrecedenceFunctionCallRight` (right-associative).
infix operator <|: LowPrecedenceFunctionCallRight

/// Pipeline / flipped function application. (`&` in Swift stdlib, `|>` in F# / Elixir)
///
/// `x |> f` applies `f` to `x`. Reads left-to-right as a pipeline.
///
/// **Named equivalent:** ``apply(_:_:)``
///
/// **Precedence:** `LowPrecedenceFunctionCallLeft` (left-associative, one step above assignment).
///
/// ```swift
/// userId |> fetchUser |> parseUser |> validateUser
/// ```
infix operator |>: LowPrecedenceFunctionCallLeft

/// Functor map — applies a function inside a functor. (`<$>` in Haskell)
///
/// `f <£> fa` is `fmap(f, fa)`. The `£` (pound) character is used instead of `$`
/// to avoid conflict with Swift's string interpolation syntax.
///
/// **Named equivalent:** `fmap` / `map` (varies per type).
///
/// **Precedence:** `FunctorOps` (left-associative, below `NilCoalescingPrecedence`).
///
/// ```swift
/// { $0 + 1 } <£> Optional.some(5)    // Optional(6)
/// { $0 * 2 } <£> [1, 2, 3]          // [2, 4, 6]
/// String.init <£> Either<Error, Int>.right(42)  // Either.right("42")
/// ```
infix operator <£>: FunctorOps

/// Flipped functor replace — `fa £> b` replaces every element of `fa` with `b`. (`$>` in Haskell)
///
/// Equivalent to `fa.map(const(b))`.
///
/// **Precedence:** `FunctorOps`.
///
/// ```swift
/// Optional.some(42) £> "replaced"    // Optional("replaced")
/// [1, 2, 3] £> "x"                   // ["x", "x", "x"]
/// ```
infix operator £>: FunctorOps

/// Functor replace-by — `b <£ fa` replaces every element of `fa` with `b`. (`<$` in Haskell)
///
/// Equivalent to `fa.map(const(b))` with arguments flipped.
///
/// **Precedence:** `FunctorOps`.
///
/// ```swift
/// "replaced" <£ Optional.some(42)    // Optional("replaced")
/// "x" <£ [1, 2, 3]                   // ["x", "x", "x"]
/// ```
infix operator <£: FunctorOps

/// Flipped functor map — value on the left, function on the right. (`<&>` in Haskell)
///
/// `fa <&> f` is `fmap(f, fa)` with arguments flipped. More readable in pipeline chains.
///
/// **Named equivalent:** `map` / `fmap` (varies per type).
///
/// **Precedence:** `MonadBindLeft` (left-associative, priority 1 — same as `>>-`).
///
/// ```swift
/// Optional.some(5) <&> { $0 + 1 }   // Optional(6)
/// [1, 2, 3] <&> { $0 * 2 }          // [2, 4, 6]
/// // In a pipeline:
/// userId |> fetchUser <&> \.name
/// ```
infix operator <&>: MonadBindLeft

/// Transformer-specific fmap: `(<£^>) :: (a -> b) -> f (g a) -> f (g b)`
///
/// This operator is exclusively for transformer (nested) fmap (`mapT`).
/// Unlike `<£>`, it has NO base overload — only transformer-specific overloads —
/// so Swift can always resolve the correct overload with zero ambiguity.
infix operator <£^>: FunctorOps

/// Flipped transformer-specific fmap: `(<&^>) :: f (g a) -> (a -> b) -> f (g b)`
///
/// Flipped version of `<£^>`. The outer type is the first argument,
/// so Swift resolves the overload from the container type directly.
infix operator <&^>: MonadBindLeft

// `^` is already declared by the Swift standard library as `infix operator ^: BitwiseXorPrecedence`.
// Re-declaring it with a different precedence group would cause an "ambiguous operator declarations"
// error, so we intentionally omit the declaration here and provide only the function overloads
// in NumericOperators.swift. For BinaryFloatingPoint types (where XOR doesn't exist) the power
// semantics are unambiguous.

/// Lift prefix operator — promotes a `WritableKeyPath` or `KeyPath` into a ``Lens``.
///
/// Applied as a prefix to a key path, `^` returns a ``Lens`` focused on that property.
///
/// - For `WritableKeyPath`: produces a ``Lens`` with zero-copy `modifyMut`.
/// - For `KeyPath` (read-only): produces a partial builder — call the result with a setter
///   closure to complete the lens.
///
/// **Named equivalent:** ``lens(_:)-swift.func``
///
/// ```swift
/// let ageLens: Lens<Person, Int> = ^\Person.age         // WritableKeyPath
/// let nameLens = (^\Person.name) { Person(name: $1, age: $0.age) }  // KeyPath + setter
/// ```
///
/// - Note: Defined in `CoreFPOperators/Utilities/KeyPath.swift`.
prefix operator ^
