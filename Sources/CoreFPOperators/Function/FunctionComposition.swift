// SPDX-License-Identifier: Apache-2.0
// MARK: - Function Composition

/// Left-to-right function composition.
///
/// `f >>> g` produces a function that applies `f` first, then passes the result to `g`.
/// This is the forward composition operator, corresponding to Haskell's `>>>` from
/// `Control.Category`.
///
/// **Named equivalent:** ``compose(_:_:)`` from `CoreFP`.
///
/// **Precedence:** `FunctionCompositionForward` (right-associative, highest custom precedence).
///
/// ```swift
/// // Named:
/// let trimAndLower = compose({ $0.trimmingCharacters(in: .whitespaces) }, { $0.lowercased() })
///
/// // Operator:
/// let trimAndLower = { $0.trimmingCharacters(in: .whitespaces) } >>> { $0.lowercased() }
/// trimAndLower("  HELLO  ")   // "hello"
///
/// // Chaining:
/// let pipeline = fetchUser >>> parseUser >>> validateUser
/// ```
///
/// - Note: Also overloaded for optic composition: `Lens >>> Lens`, `Lens >>> Prism`, etc.
///   See `CoreFPOperators/Utilities/OpticsComposition.swift`.
public func >>> <A, B, C>(
    _ f: @escaping @Sendable (A) -> B,
    _ g: @escaping @Sendable (B) -> C
) -> @Sendable (A) -> C {
    { a in g(f(a)) }
}

/// Right-to-left function composition.
///
/// `g <<< f` produces a function that applies `f` first, then passes the result to `g`.
/// This is the backward composition operator, corresponding to Haskell's `.` (dot) and `<<<`.
///
/// **Named equivalent:** ``compose(_:_:)`` from `CoreFP` with arguments flipped.
///
/// **Precedence:** `FunctionCompositionBackwards` (right-associative, one step below `>>>`).
///
/// ```swift
/// // g <<< f == f >>> g
/// let pipeline = validateUser <<< parseUser <<< fetchUser
/// ```
///
/// - Note: Also overloaded for optic composition — see `CoreFPOperators/Utilities/OpticsComposition.swift`.
public func <<< <A, B, C>(
    _ g: @escaping @Sendable (B) -> C,
    _ f: @escaping @Sendable (A) -> B
) -> @Sendable (A) -> C {
    { a in g(f(a)) }
}

// MARK: - Function Application

/// Function application operator — applies `fn` to `value` with low precedence.
///
/// `£` is the Swift equivalent of Haskell's `$`. Its extremely low precedence means
/// all other operators on the right-hand side are evaluated first, eliminating parentheses.
///
/// **Named equivalent:** ``apply(_:_:)-value-fn`` from `CoreFP`.
///
/// **Precedence:** `LowPrecedenceFunctionCallRight` (right-associative, lower than ternary).
///
/// ```swift
/// // Without £ — needs parentheses:
/// let result = f(g(h(x)))
///
/// // With £ — reads left-to-right, no nesting:
/// let result = f £ g £ h £ x
/// ```
public func £ <A, B>(
    _ fn: @escaping @Sendable (A) -> B,
    _ value: A
) -> B {
    fn(value)
}

/// Function application operator (alternative ASCII symbol for `£`).
///
/// `<|` is an ASCII alternative to ``£``. Both have the same type, precedence, and
/// associativity. Use whichever reads more clearly in context.
///
/// **Named equivalent:** ``call(_:_:)`` from `CoreFP`.
///
/// **Precedence:** `LowPrecedenceFunctionCallRight` (right-associative).
///
/// ```swift
/// f <| g <| x    // f(g(x))
/// ```
public func <| <A, B>(
    _ fn: @escaping @Sendable (A) -> B,
    _ value: A
) -> B {
    fn(value)
}

/// Flipped function application — pipes a value into a function.
///
/// `value |> f` applies `f` to `value`. This is the pipeline operator: it reads
/// left-to-right and eliminates the need to wrap intermediate results in variables.
///
/// **Named equivalent:** ``apply(_:_:)-value-fn`` (argument order flipped) from `CoreFP`.
///
/// **Precedence:** `LowPrecedenceFunctionCallLeft` (left-associative, one step above assignment).
///
/// ```swift
/// // Without |>:
/// let result = validate(parse(fetch(userId)))
///
/// // With |> — reads as a pipeline:
/// let result = userId |> fetch |> parse |> validate
/// ```
public func |> <A, B>(
    _ value: A,
    _ fn: @escaping @Sendable (A) -> B
) -> B {
    fn(value)
}
