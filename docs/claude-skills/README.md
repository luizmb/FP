# Claude AI Skills for FP Library

AI-powered development assistance for using and extending the FP (Functional Programming) library.

## Philosophy: Operators + Tacit Programming

This library encourages:
1. **Operators over methods**: Use `<£>` not `.fmap()`, use `>>-` not `.flatMap()`
2. **Tacit (point-free) style**: Use `curry(*)` not `{ $0 * $1 }`, use `(+1)` not `{ $0 + 1 }`
3. **Composition**: Build complex functions from simple pieces

Example:
```swift
// ❌ Avoid: Explicit lambdas with methods
array.map { $0 * 2 }.flatMap { [$0, $0 + 1] }

// ✅ Better: Operators with lambdas
{ $0 * 2 } <£> array >>- { [$0, $0 + 1] }

// ✅✅ Best: Tacit style with operators
let double = curry(*)(2)
let expand = { [$ 0, $0 + 1] }  // Some cases still need lambdas
double <£> array >>- expand
```

## Two Audiences

### 👤 Library Users (`users/`)

**Use the library** in your Swift projects with operators and tacit style.

**Core principle**: Import operator modules, use operators, prefer point-free style when readable.

### 🔧 Library Contributors (`contributors/`)

**Extend the library** with new types, transformers, following library conventions.

**Core principle**: Implement methods, then wrap with operators, ensure type class laws.

## Skills for Users

### ⭐ 1. getting-started.md (START HERE)
Learn FP library operators and tacit programming style.

```
Use the getting-started skill to learn how to use operators and
point-free style with the FP library.
```

### 2. convert-to-functional.md
Refactor imperative code to functional style with operators.

```
Use the convert-to-functional skill to refactor this code using
FP operators and tacit style: [paste code]
```

### 3. explain-operators.md
Understand operator compositions and precedence.

```
Use the explain-operators skill to explain how this composes:
curry(*)(2) <£> array >>- expand
```

### 4. reader-monad-guide.md
Use Reader monad for dependency injection.

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
Implement type classes for new library types.

```
Use the add-monad-support skill to add Functor/Applicative/Monad
to the new Validation type I'm adding to the library.
```

### 2. create-readert-transformer.md
Create ReaderT transformers following library patterns.

```
Use the create-readert-transformer skill to implement ReaderT + Validation
transformer with all operators.
```

## Tacit Programming Utilities

The library provides utilities for point-free style (in `FP.Functions`):

```swift
curry      // (A, B) -> C becomes (A) -> (B) -> C
flip       // Reverse parameter order
partialApply  // Fix first parameter
identity   // id function: (A) -> A
const      // Constant function: ignores input
compose    // Function composition (also >>> and <<<)
|>         // Pipe operator
```

### Tacit Examples

**Multiplication**:
```swift
// Explicit lambda
{ $0 * 2 }

// Tacit with curry
curry(*)(2)

// Or using partial application
2 |> curry(*)
```

**Addition**:
```swift
// Explicit
{ $0 + 1 }

// Tacit
curry(+)(1)

// Or
(+1)  // Swift supports this directly!
```

**Composition**:
```swift
// Explicit
{ transform2(transform1($0)) }

// Tacit
transform1 >>> transform2
```

**With operators**:
```swift
// Instead of:
array <£> { $0 * 2 } >>- { [$0, $0 + 1] }

// Tacit:
let double = curry(*)(2)
let expand = curry(Array.init(repeating:count:))(2) >>> /* or keep lambda for clarity */

double <£> array >>- expand
```

## Key Differences: Users vs Contributors

| Aspect | Users | Contributors |
|--------|-------|--------------|
| **Goal** | Use library | Extend library |
| **Style** | Operators + tacit | Methods + operators |
| **Import** | Operators modules | Create modules |
| **Methods** | Avoid (use operators) | Implement |
| **Tests** | App logic | Type class laws |

## Quick Start

**User journey**:
1. `getting-started.md` - Learn operators
2. `convert-to-functional.md` - Refactor code
3. `reader-monad-guide.md` - Dependency injection
4. `explain-operators.md` - Debug when stuck

**Contributor journey**:
1. Study existing library code
2. `add-monad-support.md` - New types
3. `create-readert-transformer.md` - Transformers
4. Follow library patterns

## Resources

- [Library Documentation](../../README.md)
- [Implementation Summary](../../IMPLEMENTATION_SUMMARY.md)
- [Operator Precedence](../../PRECEDENCE_CORRECTIONS.md)
- [Haskell Typeclassopedia](https://wiki.haskell.org/Typeclassopedia)

## Remember

**For Users**:
- ✅ Import operator modules
- ✅ Use operators (`<£>`, `>>-`, `>=>`)
- ✅ Prefer tacit style when readable
- ✅ Compose with `>>>`, `<<<`, `|>`

**For Contributors**:
- ✅ Implement methods (fmap, flatMap)
- ✅ Create operators that use methods
- ✅ Test type class laws
- ✅ Follow module organization

---

**Operators first. Tacit when clear. Compose everything.**
