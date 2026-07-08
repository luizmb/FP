# Explain Operator Compositions

Help developers understand complex operator compositions and debug issues with functional code.

## Skill Prompt

You are helping a developer understand and debug functional operator compositions using the FP library.

### Instructions:

1. **Parse the composition**: Break down the operator chain step by step
2. **Explain types**: Show the type at each step of the composition
3. **Identify operators**: Explain what each operator does
4. **Show precedence**: Explain how operators group based on precedence
5. **Suggest fixes**: If there's an error, explain what went wrong and how to fix it
6. **Provide alternatives**: Show equivalent ways to write the same composition

### Operator Reference

The precedence numbers below are the library's real, verified hierarchy (see `Sources/CoreFPOperators/Utilities/PrecedenceGroups.swift`, or `<doc:OperatorVocabulary>` for the full table with Swift stdlib groups interleaved).

#### Functor / Applicative Operators (Precedence 4, left-associative — `FunctorOps`)
- `<£>` - fmap: `(a -> b) -> f a -> f b`
- `£>` - replace right: `f a -> b -> f b`
- `<£` - replace left: `a -> f b -> f a`
- `<*>` - apply: `f (a -> b) -> f a -> f b`
- `*>` - sequence right: `f a -> f b -> f b`
- `<*` - sequence left: `f a -> f b -> f a`

`<&>` (flipped fmap) is **not** in this group — it sits at precedence 1 (`MonadBindLeft`), alongside the monadic bind operators. That's a deliberate asymmetry documented in the library; don't assume `<&>` groups the same way as `<£>`.

#### Monad Operators (Precedence 1)
- `>>-` - bind (`MonadBindLeft`, left-associative): `m a -> (a -> m b) -> m b`
- `<&>` - flipped fmap (`MonadBindLeft`, left-associative): `f a -> (a -> b) -> f b` — **not** flipped Kleisli, just flipped `<£>`
- `-<<` - flipped bind (`KleisliCompositionRight`, right-associative): `(a -> m b) -> m a -> m b`
- `>=>` - Kleisli composition (`KleisliCompositionRight`, right-associative): `(a -> m b) -> (b -> m c) -> (a -> m c)`
- `<=<` - flipped Kleisli composition (`KleisliCompositionRight`, right-associative): `(b -> m c) -> (a -> m b) -> (a -> m c)`

#### Alternative Operator (Precedence 3, left-associative)
- `<|>` - alternative: `f a -> f a -> f a`

#### Function Composition (Precedence 9, right-associative)
- `>>>` - forward composition: `(a -> b) -> (b -> c) -> (a -> c)`
- `<<<` - backward composition: `(b -> c) -> (a -> b) -> (a -> c)`

There is no `•` operator in this library — some older notes mention it, but it was never actually implemented. Use `>>>`/`<<<`.

#### Function Application (Precedence 0)
- `|>` - forward pipe (`LowPrecedenceFunctionCallLeft`, left-associative): `a -> (a -> b) -> b`
- `<|` / `£` - backward application (`LowPrecedenceFunctionCallRight`, right-associative): `(a -> b) -> a -> b` — `£` and `<|` are two spellings of the same operator

#### Semigroup (Precedence 6 / 5)
- `<>` - append/concat (`ConcatPrecedence`, precedence 6, right-associative)
- `++` - list concatenation (`AppendToList`, precedence 5, right-associative)

### Example Analysis Process:

#### Example 1: Simple Functor Chain

```swift
let result = someOptional <£> { $0 * 2 } <£> { $0 + 1 }
```

**Error**: This won't compile!

**Analysis**:
1. Type of `someOptional`: `Optional<Int>`
2. `<£>` is left-associative with precedence 4, and its **first** argument must be the transforming function, not the container
3. `someOptional <£> { $0 * 2 }` already puts the container on the left — that's backwards for `<£>`

**Fix**:
```swift
let result = { $0 + 1 } <£> ({ $0 * 2 } <£> someOptional)
// Or, reading left to right with the flipped operator instead:
let result2 = someOptional <&> { $0 * 2 } <&> { $0 + 1 }
```

Or use the named method:
```swift
let result3 = someOptional.map { $0 * 2 }.map { $0 + 1 }
```

#### Example 2: Monad Bind vs Kleisli

```swift
// Bind (left-associative)
let result1 = someOptional >>- f >>- g
// Groups as: (someOptional >>- f) >>- g
// Type flow: Optional<A> -> Optional<B> -> Optional<C>

// Kleisli (right-associative)
let composed = f >=> g
// Groups as: f >=> g (no need for parens)
// Type: (A) -> Optional<C>
// Then apply: composed(value)
```

**When to use which**:
- Use `>>-` when you have a value and want to chain operations
- Use `>=>` when you want to compose functions for later use

#### Example 3: Mixed Operators

```swift
let result = { $0 * 2 } <£> array >>- { [$0, $0 + 1] }
```

**Analysis**:
1. `<£>` has precedence 4 (left-assoc)
2. `>>-` has precedence 1 (left-assoc)
3. Higher precedence binds tighter, so this groups as: `({ $0 * 2 } <£> array) >>- { [$0, $0 + 1] }`
4. Step 1: `{ $0 * 2 } <£> array` → `[Int]` (doubled)
5. Step 2: `[Int] >>- { [$0, $0 + 1] }` → `[Int]` (expanded)

**Type flow**:
```
[Int]                                    // [1, 2, 3]
  <£> { $0 * 2 }     → [Int]             // [2, 4, 6]
  >>- { [$0, $0+1] } → [Int]             // [2, 3, 4, 5, 6, 7]
```

#### Example 4: Function Composition

```swift
let double = curry(*)(2)
let increment = curry(+)(1)
let transform = increment >>> double >>> { String($0) }
```

**Analysis**:
1. `>>>` is right-associative with precedence 9
2. Groups as: `increment >>> (double >>> { String($0) })`
3. Type flow:
   - `increment`: `(Int) -> Int`
   - `double`: `(Int) -> Int`
   - `{ String($0) }`: `(Int) -> String`
   - Result: `(Int) -> String`

Swift has no operator-section syntax — `(*2)`/`(+1)` are not valid Swift expressions. Use `curry(_:)` (partial-applied via `|>` or direct call) for the arithmetic pieces.

**Usage**:
```swift
let result = 5 |> transform  // "12"
// Or: transform(5)
```

#### Example 5: Reader + Optional (a transformer stack)

```swift
let computation = fetchUser(id) >>- { user in
    user.profile
} <£> { profile in
    profile.name
}
```

**Error**: Type mismatch!

**Analysis**:
1. `fetchUser(id)` returns `Reader<Config, User?>` — this is the `ReaderTOptional` combo (Reader wrapping an Optional)
2. `>>- { user in user.profile }` treats it like a plain `Reader<Config, User>`, but the value inside is actually `User?`
3. Should use `mapT` — the transformer-specific operation that reaches *through* the inner `Optional` — instead of the base `<£>`/`>>-`

**Fix** (assuming `User.profile: Profile` and `Profile.name: String`, both non-optional — `mapT` only wraps in `Optional` once, at the outermost level):
```swift
let computation: Reader<Config, String?> = fetchUser(id)
    .mapT { user in user.profile }    // Reader<Config, Profile?>
    .mapT { profile in profile.name } // Reader<Config, String?>
```

### Debugging Checklist:

When you encounter an error in operator composition:

1. **Check precedence**: Are operators grouping as expected?
   - Use parentheses to force grouping
   - Check the precedence table above, or `<doc:OperatorVocabulary>`

2. **Trace types**: What's the type at each step?
   - Add type annotations to intermediate steps
   - Use `let intermediate: Type = ...` to verify

3. **Check associativity**: Left vs right makes a difference!
   - `a >>- b >>- c` = `(a >>- b) >>- c` (left)
   - `f >=> g >=> h` = `f >=> (g >=> h)` (right)

4. **Verify monad type**: Are you mixing plain and transformer monads?
   - `Optional<A>` vs `Reader<Env, Optional<A>>`
   - Use `mapT`, `flatMapT` for the transformer combo, not the base `<£>`/`>>-`

5. **Check operator direction**: `<£>` wants the function on the left; `<&>` wants the container on the left

### Common Mistakes:

❌ **Mistake 1**: Wrong operator direction
```swift
optional <£> { $0 * 2 }  // ❌ <£> wants the function on the left
```
✅ **Fix**:
```swift
{ $0 * 2 } <£> optional  // ✅ Function on left
// Or use the flipped version:
optional <&> { $0 * 2 }  // ✅ Flipped fmap — container on the left
```

❌ **Mistake 2**: Mixing monad levels
```swift
let reader: Reader<Env, Int?> = ...
reader >>- { $0 * 2 }  // ❌ >>- expects the value to be a plain Int, not Int?
```
✅ **Fix**:
```swift
reader.mapT { $0 * 2 }  // ✅ Use mapT to reach through the inner Optional
```

❌ **Mistake 3**: Wrong precedence assumption
```swift
optional <|> nil >>- f  // Might not parse as expected
```
✅ **Fix**:
```swift
(optional <|> nil) >>- f  // ✅ Explicit grouping
```

### Ask the developer:
1. What operator composition are they trying to understand or debug?
2. What error message are they seeing (if any)?
3. What did they expect to happen?
4. What types are involved?

Provide detailed step-by-step analysis with type annotations and clear explanations.
