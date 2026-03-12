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

### Operator Reference:

#### Functor Operators (Precedence 4, left-associative)
- `<£>` - fmap: `(a -> b) -> f a -> f b`
- `£>` - replace right: `f a -> b -> f b`
- `<£` - replace left: `a -> f b -> f a`
- `<&>` - flipped fmap (Precedence 1): `f a -> (a -> b) -> f b`

#### Applicative Operators (Precedence 4, left-associative)
- `<*>` - apply: `f (a -> b) -> f a -> f b`
- `*>` - sequence right: `f a -> f b -> f b`
- `<*` - sequence left: `f a -> f b -> f a`

#### Monad Operators
- `>>-` - bind (Precedence 1, left-associative): `m a -> (a -> m b) -> m b`
- `-<<` - flipped bind (Precedence 1, right-associative): `(a -> m b) -> m a -> m b`
- `>=>` - Kleisli composition (Precedence 1, right-associative): `(a -> m b) -> (b -> m c) -> (a -> m c)`
- `<&>` - flipped Kleisli (Precedence 1, right-associative): `(b -> m c) -> (a -> m b) -> (a -> m c)`

#### Alternative Operator (Precedence 3, left-associative)
- `<|>` - alternative: `f a -> f a -> f a`

#### Function Composition (Precedence 9, right-associative)
- `>>>` - forward composition: `(a -> b) -> (b -> c) -> (a -> c)`
- `<<<` - backward composition: `(b -> c) -> (a -> b) -> (a -> c)`
- `•` - alternative composition symbol

#### Function Application
- `|>` - forward pipe (Precedence 0, left-associative): `a -> (a -> b) -> b`
- `<|` - backward application (Precedence 0, right-associative): `(a -> b) -> a -> b`
- `£` - low-precedence application (Precedence 0)

#### Semigroup (Precedence 6)
- `<>` - append/concat
- `++` - list concatenation (Precedence 5, right-associative)

### Example Analysis Process:

#### Example 1: Simple Functor Chain

```swift
let result = someOptional <£> { $0 * 2 } <£> { $0 + 1 }
```

**Error**: This won't compile!

**Analysis**:
1. Type of `someOptional`: `Optional<Int>`
2. `<£>` is left-associative with precedence 4
3. Groups as: `(someOptional <£> { $0 * 2 }) <£> { $0 + 1 }`
4. Step 1: `someOptional <£> { $0 * 2 }` → `Optional<Int>`
5. Step 2: `Optional<Int> <£> { $0 + 1 }` → **Error!** `<£>` expects function on the left

**Fix**:
```swift
let result = { $0 * 2 } <£> someOptional <£> { $0 + 1 }
// Groups as: ({ $0 * 2 } <£> someOptional) <£> { $0 + 1 }
// Type flow: Optional<Int> -> Optional<Int> -> Optional<Int>
```

Or use method syntax:
```swift
let result = someOptional.fmap { $0 * 2 }.fmap { $0 + 1 }
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
let result = array <£> { $0 * 2 } >>- { [$0, $0 + 1] }
```

**Analysis**:
1. `<£>` has precedence 4 (left-assoc)
2. `>>-` has precedence 1 (left-assoc)
3. Higher precedence binds tighter, so groups as: `(array <£> { $0 * 2 }) >>- { [$0, $0 + 1] }`
4. Step 1: `{ $0 * 2 } <£> array` → `[Int]` (doubled)
5. Step 2: `[Int] >>- { [$0, $0 + 1] }` → `[Int]` (expanded)

**Type flow**:
```
[Int]                                    // [1, 2, 3]
  <£> { $0 * 2 }    → [Int]             // [2, 4, 6]
  >>- { [$0, $0+1] } → [Int]             // [2, 3, 4, 5, 6, 7]
```

#### Example 4: Function Composition

```swift
let transform = (*2) >>> (+1) >>> String.init
```

**Analysis**:
1. `>>>` is right-associative with precedence 9
2. Groups as: `(*2) >>> ((+1) >>> String.init)`
3. Type flow:
   - `(*2)`: `(Int) -> Int`
   - `(+1)`: `(Int) -> Int`
   - `String.init`: `(Int) -> String`
   - Result: `(Int) -> String`

**Usage**:
```swift
let result = 5 |> transform  // "11"
// Or: transform(5)
```

#### Example 5: Reader Composition

```swift
let computation = fetchUser(id) >>- { user in
    user.profile
} <£> { profile in
    profile.name
}
```

**Error**: Type mismatch!

**Analysis**:
1. `fetchUser(id)` returns `Reader<Config, User?>`
2. `>>- { user in user.profile }` expects Reader monad, but we're in ReaderT + Optional
3. Should use `mapT` instead of `<£>` for the second operation

**Fix**:
```swift
// Using ReaderT operations:
let computation: Reader<Config, String?> = fetchUser(id)
    .mapT { user in user.profile }
    .mapT { profile in profile.name }

// Or with ReaderT bind:
let computation = fetchUser(id) >>- { user in
    Reader { _ in user.profile }
} >>- { profile in
    Reader { _ in profile.name }
}
```

### Debugging Checklist:

When you encounter an error in operator composition:

1. **Check precedence**: Are operators grouping as expected?
   - Use parentheses to force grouping
   - Check precedence table

2. **Trace types**: What's the type at each step?
   - Add type annotations to intermediate steps
   - Use `let intermediate: Type = ...` to verify

3. **Check associativity**: Left vs right makes a difference!
   - `a >>- b >>- c` = `(a >>- b) >>- c` (left)
   - `f >=> g >=> h` = `f >=> (g >=> h)` (right)

4. **Verify monad type**: Are you mixing plain and transformer monads?
   - `Optional` vs `Reader<Env, Optional>`
   - Use `mapT`, `flatMapT` for transformers

5. **Check operator signature**: Does it match your types?
   - Functor: operates on values inside
   - Applicative: combines contexts
   - Monad: sequences effects

### Common Mistakes:

❌ **Mistake 1**: Wrong operator direction
```swift
optional <£> { $0 * 2 }  // ❌ Value on left
```
✅ **Fix**:
```swift
{ $0 * 2 } <£> optional  // ✅ Function on left
// Or use flipped version:
optional <&> { $0 * 2 }  // ✅ Flipped fmap
```

❌ **Mistake 2**: Mixing monad levels
```swift
let reader: Reader<Env, Int?> = ...
reader >>- { $0 * 2 }  // ❌ Expects Reader, not Int
```
✅ **Fix**:
```swift
reader.mapT { $0 * 2 }  // ✅ Use mapT for transformers
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
