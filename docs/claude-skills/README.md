# Claude AI Skills for FP Library

AI-powered development assistance for using and extending the FP (Functional Programming) library.

## Philosophy: Operators + Tacit Programming

This library encourages:
1. **Operators over methods at call sites**: prefer `<£>` over `.map()`, `>>-` over `.flatMap()` — though `.map`/`.flatMap` are the real instance methods the operators delegate to
2. **Tacit (point-free) style**: prefer `2 |> curry(*)` over `{ $0 * 2 }` for simple arithmetic
3. **Composition**: Build complex functions from simple pieces

Example:
```swift
// ❌ Avoid: Explicit lambdas with methods
array.map { $0 * 2 }.flatMap { [$0, $0 + 1] }

// ✅ Better: Operators with lambdas
{ $0 * 2 } <£> array >>- { [$0, $0 + 1] }

// ✅✅ Best: Tacit style with operators (use |> curry)
let double = 2 |> curry(*)
let expand: (Int) -> [Int] = { [$0, $0 + 1] }  // Some cases still need lambdas
double <£> array >>- expand
```

Swift has no operator-section syntax — `(+1)`/`(*2)` are not valid Swift. Always use `curry(_:)`.

## Two Audiences

### 👤 Library Users (`users/`)

**Use the library** in your Swift projects with operators and tacit style.

**Core principle**: Import the modules you need (`FP` for everything, or `CoreFP`/`CoreFPOperators`/`DataStructure`/`DataStructureOperators` individually), use operators, prefer point-free style when readable.

### 🔧 Library Contributors (`contributors/`)

**Extend the library** with new types, transformers, following library conventions.

**Core principle**: Implement named functions first (instance `.map`/`.flatMap` + static curried `fmap`/`bind`), then wrap with operators that delegate to them, ensure type class laws, cover all four applicable test targets.

## Skills for Users

### ⭐ 1. getting-started.md (START HERE)
Learn FP library operators and tacit programming style, plus Prism/PrismKeyPath composition for enum case access.

```
Use the getting-started skill to learn how to use operators and
point-free style with the FP library.
```

### 2. convert-to-functional.md
Refactor imperative code to functional style — operators, `Reader`, `Validation`, `Loading` + `loadedOrPrevious` for UI state, and `const`/`ignore`/`fail`/`withArg` for point-free test fixtures.

```
Use the convert-to-functional skill to refactor this code using
FP operators and tacit style: [paste code]
```

### 3. explain-operators.md
Understand operator compositions and precedence — including the real, verified precedence table (not folklore).

```
Use the explain-operators skill to explain how this composes:
curry(*)(2) <£> array >>- expand
```

### 4. reader-monad-guide.md
Use Reader monad for dependency injection — **and know when not to**: `Reader` is for environment/dependency context that crosses the app's own boundary, not a wrapper for ordinary function parameters.

```
Use the reader-monad-guide skill to refactor my service layer
to use Reader with operators.
```

### 5. make-type-composable.md
Make custom types work with library operators.

```
Use the make-type-composable skill to help my AsyncResult<T, E>
work with <£> and >>- operators.
```

## Skills for Contributors

### 1. add-monad-support.md
Implement type classes for new library types, following the library's actual internal conventions (static-method-on-type `pure`/`apply`/`liftA2`/`kleisli`, not free functions; both flipped-operator directions; all four test targets).

```
Use the add-monad-support skill to add Functor/Applicative/Monad
to the new Validation type I'm adding to the library.
```

### 2. create-readert-transformer.md
Create monad transformer stacks (`ReaderT` or a flat `OuterTInner`) following library patterns — real module locations, `mapT`/`flatMapT`/`kleisliT` naming, `<£^>`/`<&^>` for the transformer functor map.

```
Use the create-readert-transformer skill to implement ReaderT + Validation
transformer with all operators.
```

```
Use the create-readert-transformer skill to implement ArrayTValidation
([Validation<E,A>]) transformer with all operators.
```

## Tacit Programming Utilities

The library provides utilities for point-free style (in `CoreFP`):

```swift
curry        // (A, B) -> C becomes (A) -> (B) -> C
flip         // Reverse parameter order
withArg      // Adapt a single-argument function to a multi-argument call site
compose      // Function composition (also >>> and <<<)
const        // Ignores its arguments, always returns a fixed value — overloads for 0-4+ args
ignore       // Accepts any arguments, returns Void — for no-op stubs
fail         // Returns a function that traps with a message if ever actually called
|>           // Pipe operator — apply a value to a function
```

### Tacit Examples

**Multiplication**:
```swift
// Explicit lambda
{ $0 * 2 }

// ✅ Tacit (preferred with |>)
2 |> curry(*)
```

**Composition**:
```swift
// Explicit
{ transform2(transform1($0)) }

// Tacit
transform1 >>> transform2
```

**Default/ignored closures in fixtures** (see `convert-to-functional.md` Pattern 9 for the full treatment):
```swift
// ❌ { _, _ in someValue } just to satisfy a default parameter
var fetchUser: (String, Int) -> User = { _, _ in .guest }

// ✅ const names the intent: ignore the args, always return this
var fetchUser: (String, Int) -> User = const(.guest)
```

## Key Differences: Users vs Contributors

| Aspect | Users | Contributors |
|--------|-------|--------------|
| **Goal** | Use library | Extend library |
| **Style** | Operators + tacit | Named functions + operators |
| **Import** | `FP` or the specific module(s) needed | Add to the appropriate core/`*Operators` module |
| **Methods** | Call operators at use sites | Implement `.map`/`.flatMap` + static `fmap`/`bind`/`pure`/`apply`/`liftA2`/`kleisli` |
| **Tests** | App logic | Type class laws, in all four applicable test targets |

## Quick Start

**User journey**:
1. `getting-started.md` - Learn operators + Prisms
2. `convert-to-functional.md` - Refactor code, including UI state and test fixtures
3. `reader-monad-guide.md` - Dependency injection (and its boundary)
4. `explain-operators.md` - Debug when stuck

**Contributor journey**:
1. Study existing library code
2. `add-monad-support.md` - New types
3. `create-readert-transformer.md` - Transformers
4. Follow library patterns

## Resources

- [Library Documentation](../../README.md)
- [Monad Transformers](../../Sources/FP/FP.docc/Articles/MonadTransformers.md)
- [Operator Vocabulary & Precedence](../../Sources/FP/FP.docc/Articles/OperatorVocabulary.md)
- [Optics](../../Sources/CoreFP/CoreFP.docc/Optics.md)
- [Loading](../../Sources/DataStructure/DataStructure.docc/Loading.md)
- [Haskell Typeclassopedia](https://wiki.haskell.org/Typeclassopedia)

## Remember

**For Users**:
- ✅ Import the modules you need (`FP`, or `CoreFP`/`CoreFPOperators`/`DataStructure`/`DataStructureOperators`)
- ✅ Use operators (`<£>`, `>>-`, `>=>`)
- ✅ Prefer tacit style when readable
- ✅ Compose with `>>>`, `<<<`, `|>`
- ✅ Use `Reader` only for real dependency-injection context, not ordinary parameters
- ✅ Use `Prism`/`PrismKeyPath` composition for reusable, nesting-aware case access

**For Contributors**:
- ✅ Implement `.map`/`.flatMap` (instance) + `fmap`/`bind`/`pure`/`apply`/`liftA2`/`kleisli` (static, curried)
- ✅ Create operators that delegate to those named functions — never re-implement logic inline
- ✅ Add both directions of every directional operator in the same change
- ✅ Test type class laws in every applicable target (named-function tests: no operators; operator tests: must use the operator)
- ✅ Follow module organization (`CoreFP`/`DataStructure` for named functions, `*Operators` for operator syntax)

---

**Operators first. Tacit when clear. Compose everything.**
