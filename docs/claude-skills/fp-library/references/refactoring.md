# Refactoring imperative Swift into FP-library style

How to approach a refactor, then one section per pattern with a before and an after. Every after compiles against the library; the shared model types are declared once at the top.

## Contents

- How to approach it
- Shared model
- Nested if-let and optional chains
- try / catch
- Nested loops
- Validation: first error vs every error
- Splitting successes from failures
- UI loading state
- Test fixtures and stubs
- Checklist

## How to approach it

1. Name the effect of each step: can fail without a reason (`Optional`), fail with a reason (`Result`, or `Either` when the left side isn't an `Error`), collect every error (`Validation`), need a dependency (`Reader`), produce several results (`Array`).
2. Turn each step into a small function `(A) -> Effect<B>` with a `@Sendable` type.
3. Join them with `>>-` (have a value) or `>=>` (build a reusable function). Independent steps join with `<*>` / `liftA2`, which also tells the reader they don't depend on each other.
4. Stop when it stops reading better. A refactor that trades a clear `guard` for a wall of operators isn't a win, and the named methods (`map`, `flatMap`) are always fine.
5. Behaviour must not change: keep short-circuit vs accumulate semantics the same unless changing them is the point.

## Shared model

```swift
import FP

struct Address: Sendable { let city: String? }
struct User: Sendable { let id: String; let name: String; let age: Int; let email: String; let address: Address? }

enum AppError: Error, Equatable, Sendable { case notFound, invalid(String) }

let users: [String: User] = [
    "1": User(id: "1", name: "Ada", age: 36, email: "ada@example.com", address: Address(city: "London"))
]

let findUser: @Sendable (String) -> User? = { users[$0] }
```

## Nested if-let and optional chains

Before:

```swift
func cityImperative(of id: String) -> String? {
    if let user = findUser(id) {
        if let address = user.address {
            if let city = address.city, !city.isEmpty {
                return city.uppercased()
            }
        }
    }
    return nil
}
```

After, as a value flowing through binds, or as a reusable Kleisli pipeline:

```swift
let address: @Sendable (User) -> Address? = { $0.address }
let city: @Sendable (Address) -> String? = { $0.city }
let nonEmpty: @Sendable (String) -> String? = { $0.isEmpty ? nil : $0 }

func city(of id: String) -> String? {
    findUser(id) >>- address >>- city >>- nonEmpty <&> { $0.uppercased() }
}

let cityOfUser = findUser >=> address >=> city >=> nonEmpty
```

(`<&>` shares a precedence group with `>>-`, so a container-first chain reads left to right; `<£>` binds tighter than `>>-`, so `f <£> x >>- g` is `(f <£> x) >>- g`.)

Several independent optionals, all needed: `zip` or `liftA2` instead of a multi-`guard`:

```swift
func greeting(_ name: String?, _ age: Int?) -> String? {
    Optional<String>.liftA2 { (name: String, age: Int) in "\(name), \(age)" }(name, age)
}
```

## try / catch

Make the steps return `Result` with a specific error type instead of throwing, then chain:

```swift
let parseAge: @Sendable (String) -> Result<Int, AppError> = { Int($0).map(Result.success) ?? .failure(.invalid("age")) }
let checkAdult: @Sendable (Int) -> Result<Int, AppError> = { $0 >= 18 ? .success($0) : .failure(.invalid("too young")) }

let adultAge = parseAge >=> checkAdult

let message: String = adultAge("21").match(
    caseLeft: { "ok: \($0)" },
    caseRight: { "error: \($0)" }
)
```

Careful with `match` on `Result`: its `SumType2` conformance puts success on the left (`caseLeft`) and failure on the right, which is the opposite of `Either`, where the right side is the success. When in doubt, a plain `switch` is never ambiguous.

## Nested loops

```swift
func sumsImperative(_ xs: [Int], _ ys: [Int]) -> [Int] {
    var result: [Int] = []
    for x in xs {
        for y in ys {
            result.append(x + y)
        }
    }
    return result
}

func sums(_ xs: [Int], _ ys: [Int]) -> [Int] {
    [Int].liftA2(+)(xs, ys)
}

func sumsWithBind(_ xs: [Int], _ ys: [Int]) -> [Int] {
    xs >>- { x in ys.map { x + $0 } }
}
```

## Validation: first error vs every error

`Result` with Kleisli stops at the first failing check, like a sequence of early returns:

```swift
let validName: @Sendable (User) -> Result<User, AppError> = { $0.name.isEmpty ? .failure(.invalid("name")) : .success($0) }
let validAge: @Sendable (User) -> Result<User, AppError> = { $0.age < 18 ? .failure(.invalid("age")) : .success($0) }
let validateFirstError = validName >=> validAge
```

To report every problem at once (a form, say), validate the fields independently with `Validation` and combine applicatively; errors accumulate through the error type's `Semigroup` (`[String]` here):

```swift
struct SignUp: Sendable { let name: String; let email: String }

let nameField: @Sendable (String) -> Validation<[String], String> = { $0.isEmpty ? .failure(["name is empty"]) : .success($0) }
let emailField: @Sendable (String) -> Validation<[String], String> = { $0.contains("@") ? .success($0) : .failure(["email has no @"]) }

func signUp(name: String, email: String) -> Validation<[String], SignUp> {
    Validation<[String], SignUp>.liftA2(SignUp.init)(nameField(name), emailField(email))
}
// signUp(name: "", email: "x") == .failure(["name is empty", "email has no @"])
```

Moving between the two: `Validation(result)`, `Validation(either)`, `either.toValidation()`, `either.toResult()`.

## Splitting successes from failures

```swift
let parsed: [Either<String, Int>] = ["1", "x", "3"].map { token in
    Int(token).map(Either.right) ?? .left("not a number: \(token)")
}

let numbers: [Int] = parsed.compactMap(\.b)
let problems: [String] = parsed.compactMap(\.a)
```

`a` / `b` are the `SumType2` projections (left / right for `Either`). If every element must succeed, `traverse` turns `[A]` into `Result<[B], E>` or `[B]?` in one go:

```swift
let allNumbers: [Int]? = ["1", "2", "3"].traverse { Int($0) }
```

## UI loading state

A hand-rolled `idle / loading / loaded / failed` enum blanks the screen on every refresh. `Loading<Success, Failure>` keeps the last good value through reloads and failures, and `Failure` can be anything `Sendable` (a `String` for the UI is fine; only the `Result` bridges need an `Error`):

```swift
func reloadedMovies(_ state: Loading<[String], AppError>, _ result: Result<[String], AppError>) -> Loading<[String], AppError> {
    state.startLoading().applying(result)
}

let firstLoad = reloadedMovies(.idle, .success(["Alien"]))  // .loaded(["Alien"])
let failedRefresh = reloadedMovies(firstLoad, .failure(.notFound))  // .failed(error: .notFound, previous: ["Alien"])
let stillOnScreen = failedRefresh.loadedOrPrevious  // ["Alien"]
```

Render from `loadedOrPrevious`, and show progress and errors as lighter signals on top (`state.loading != nil` for a small spinner, `state.failed != nil` for a banner). `Loading` has `map`, `flatMap`, `catch`, `mapError`, `zip` and `pessimisticCombine` (failed beats loading beats idle, for combining two screens' states).

## Test fixtures and stubs

`{ _, _ in value }` closures in a mock say less than the named helpers:

```swift
struct UserServiceMock: Sendable {
    // const: ignore the arguments, always return this
    var fetch: @Sendable (String, Int) -> User? = const(users["1"])
    // ignore: a no-op that accepts anything
    var track: @Sendable (String) -> Void = { ignore($0) }
}

struct ValidatorMock {
    // fail: traps if it's ever called, for dependencies a test must override
    var validate: (String) -> Bool = fail("validate not expected in this test")
}

// withArg: adapt a one-argument function to a two-argument call site
let firstCharacter: @Sendable (String) -> Character? = { $0.first }
let firstOfPair: @Sendable (String, Int) -> Character? = withArg(\.0)(firstCharacter)
```

(`fail` returns non-`@Sendable` closures, so store it in a plain `() -> T` or call it inline.) The `@Mock` macro in `FPMacros` generates this kind of mock from a protocol, with every requirement defaulting to `fail(...)`.

## Checklist

- if-let / guard chains on optionals: `>>-` or `>=>`; independent ones: `liftA2` / `zip`.
- try / catch: steps return `Result<A, SpecificError>`, chained with `>>-` / `>=>`.
- Loops that build arrays: `map`, `flatMap` / `>>-`, `liftA2`, `traverse`.
- Validation: `Result` for first error, `Validation` for every error.
- Dependencies threaded through every call: maybe `Reader` (read `reader.md` first, it's easy to overuse).
- Nested effects (`Reader<Env, Result<A, E>>`): a transformer stack (`transformer-stacks.md`).
- UI state machines: `Loading` and `loadedOrPrevious`.
- Stub closures: `const`, `ignore`, `fail`, `withArg`.
