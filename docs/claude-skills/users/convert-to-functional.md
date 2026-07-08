# Convert Imperative Code to Functional Style

Help convert imperative Swift code to functional style using the FP library.

## Skill Prompt

You are helping a developer refactor imperative Swift code into functional style using the FP library's operators and patterns.

### Instructions:

1. **Identify patterns**: Look for imperative patterns that can be replaced with functional equivalents
2. **Use FP operators**: Replace imperative constructs with `<£>`, `<*>`, `>>-`, `>=>`, etc.
3. **Leverage sum/effect types**: Use `Optional`, `Result`, `Either`, `Validation`, `Reader`, `Array` for effect handling
4. **Compose functions**: Replace nested calls with function composition `>>>`, `<<<`, `|>`
5. **Eliminate mutation**: Replace `var` with `let`, loops with `map`/`flatMap`/`filter`
6. **Add types**: Make types explicit to leverage Swift's type inference with FP operators

### Common Patterns to Replace:

#### Pattern 1: Nested if-let (Pyramid of Doom)

**Before (Imperative)**:
```swift
func processUser(id: String) -> String? {
    if let user = findUser(id) {
        if let profile = user.profile {
            if let name = profile.name {
                if name.count > 0 {
                    return name.uppercased()
                }
            }
        }
    }
    return nil
}
```

**After (Functional)**:
```swift
func processUser(id: String) -> String? {
    findUser(id) >>- { user in
        user.profile
    } >>- { profile in
        profile.name
    } >>- { name in
        name.isEmpty ? nil : name.uppercased()
    }
}

// Or with Kleisli composition, if each step is already a standalone function:
func nonEmptyUppercased(_ name: String) -> String? {
    name.isEmpty ? nil : name.uppercased()
}
let processUser = findUser >=> { $0.profile } >=> { $0.name } >=> nonEmptyUppercased
```

#### Pattern 2: Multiple map/flatMap chains

**Before (Imperative)**:
```swift
let result = array
    .compactMap { $0.value }
    .map { $0 * 2 }
    .filter { $0 > 10 }
    .reduce(0, +)
```

**After (Functional)**:
```swift
let result = array
    <£> { $0.value }
    >>- { x in x.map { $0 * 2 } }
    .filter { $0 > 10 }
    .reduce(0, +)

// Or compose the pipeline once and reuse it:
let transform: (Element) -> [Int] = { element in
    guard let value = element.value else { return [] }
    let doubled = value * 2
    return doubled > 10 ? [doubled] : []
}
let result = array.flatMap(transform).reduce(0, +)
```

#### Pattern 3: Error handling with try/catch

**Before (Imperative)**:
```swift
func processData() -> String {
    do {
        let data = try fetchData()
        let parsed = try parse(data)
        let validated = try validate(parsed)
        return transform(validated)
    } catch {
        return "Error: \(error)"
    }
}
```

**After (Functional — `fetchData`/`parse`/`validate` return `Result`, not `throws`)**:
```swift
func processData() -> String {
    let result: Result<String, Error> = fetchData()
        >>- parse
        >>- validate
        <£> transform

    return result.match(
        caseFailure: { "Error: \($0)" },
        caseSuccess: { $0 }
    )
}

// Or with Kleisli composition:
let pipeline = fetchData >=> parse >=> validate
```

#### Pattern 4: Nested loops

**Before (Imperative)**:
```swift
func combinations(as: [Int], bs: [Int]) -> [Int] {
    var results: [Int] = []
    for a in as {
        for b in bs {
            results.append(a + b)
        }
    }
    return results
}
```

**After (Functional)**:
```swift
func combinations(as: [Int], bs: [Int]) -> [Int] {
    as >>- { a in
        bs.map { b in a + b }
    }
}

// Or with liftA2 (a static method on Array):
func combinations(as: [Int], bs: [Int]) -> [Int] {
    [Int].liftA2(+)(as, bs)
}
```

#### Pattern 5: Dependency injection

**Before (Imperative)**:
```swift
struct Config { let apiKey: String; let baseURL: URL }

func fetchUser(id: String, config: Config) -> User? {
    let url = config.baseURL.appendingPathComponent(id)
    // ... use config.apiKey
    return nil
}

func processUser(id: String, config: Config) -> String? {
    if let user = fetchUser(id: id, config: config) {
        return user.name
    }
    return nil
}
```

**After (Functional with Reader)**:
```swift
struct Config { let apiKey: String; let baseURL: URL }

let fetchUser: (String) -> Reader<Config, User?> = { id in
    Reader { config in
        let url = config.baseURL.appendingPathComponent(id)
        // ... use config.apiKey
        return nil
    }
}

// ReaderTOptional's mapT reaches through the Optional wrapped inside the Reader
let processUser: (String) -> Reader<Config, String?> = { id in
    fetchUser(id).mapT { $0.name }
}

// Usage:
let config = Config(apiKey: "key", baseURL: URL(string: "https://api.com")!)
let userName = processUser("123")(config)  // Reader has callAsFunction, so it's directly callable
```

#### Pattern 6: State accumulation

**Before (Imperative)**:
```swift
func parseNumbers(_ input: String) -> ([Int], [String]) {
    var numbers: [Int] = []
    var errors: [String] = []

    for token in input.split(separator: ",") {
        if let num = Int(token) {
            numbers.append(num)
        } else {
            errors.append("Invalid: \(token)")
        }
    }

    return (numbers, errors)
}
```

**After (Functional)**:
```swift
func parseNumbers(_ input: String) -> ([Int], [String]) {
    input
        .split(separator: ",")
        .map { token -> Either<String, Int> in
            Int(token).map(Either.right) ?? .left("Invalid: \(token)")
        }
        .reduce(into: ([Int](), [String]())) { result, either in
            either.match(
                caseLeft: { result.1.append($0) },
                caseRight: { result.0.append($0) }
            )
        }
}
```

#### Pattern 7: Validation with multiple checks

**Before (Imperative)**:
```swift
func validateUser(_ user: User) -> Result<User, ValidationError> {
    if user.name.isEmpty {
        return .failure(.emptyName)
    }
    if user.age < 18 {
        return .failure(.tooYoung)
    }
    if !user.email.contains("@") {
        return .failure(.invalidEmail)
    }
    return .success(user)
}
```

**After (Functional — short-circuits on the first failure, matching the original)**:
```swift
let validateName: (User) -> Result<User, ValidationError> = { user in
    user.name.isEmpty ? .failure(.emptyName) : .success(user)
}

let validateAge: (User) -> Result<User, ValidationError> = { user in
    user.age < 18 ? .failure(.tooYoung) : .success(user)
}

let validateEmail: (User) -> Result<User, ValidationError> = { user in
    user.email.contains("@") ? .success(user) : .failure(.invalidEmail)
}

let validateUser = validateName >=> validateAge >=> validateEmail
```

If the goal is to report **every** failing check at once instead of stopping at the first one, reach for `Validation<E, A>` instead of `Result` — see the `Validation` DocC article. `Validation`'s errors accumulate via `Semigroup`, so `E` is typically `[ValidationError]`, not a single case.

#### Pattern 8: UI loading state that doesn't blank the screen on every refresh

**Before (Imperative)**:
```swift
enum ScreenState {
    case idle, loading, loaded([Movie]), failed(Error)
}

// Every refresh (pull-to-refresh, poll, retry) flips this to .loading,
// which blanks whatever the user was looking at.
var state: ScreenState = .idle

switch state {
case .idle, .loading:
    ProgressView()
case let .loaded(movies):
    MovieList(movies)
case .failed:
    ErrorView()
}
```

**After (Functional, with `Loading<Success, Failure>`)**:
```swift
import DataStructure

var state: Loading<[Movie], NetworkError> = .idle

state = state.startLoading()                          // .loading(previous: nil)
state = state.applying(.success([movie1, movie2]))     // .loaded([movie1, movie2])
state = state.startLoading()                           // .loading(previous: [movie1, movie2]) — old data preserved
```

`loadedOrPrevious` is the property to render from — it collapses `.loaded`, `.loading(previous:)`, and `.failed(_, previous:)` down to "the best value there is to show right now," so a refresh in flight or a failed retry doesn't wipe out a screen that already has good content on it:

```swift
if let movies = state.loadedOrPrevious {
    MovieList(movies)          // stays on screen through .loading and .failed alike
} else {
    switch state {
    case .idle: EmptyStateView()
    case .loading: ProgressView()
    case .failed: ErrorView()
    case .loaded: EmptyView()  // unreachable — .loaded always has a loadedOrPrevious
    }
}
```

Pair `loadedOrPrevious` with a lighter-weight, non-blocking signal for the in-flight/error states instead of hiding the content underneath them — e.g. `state.loading != nil` to show a small inline spinner, or `state.failed != nil` to show a dismissible error banner over content that's still visible. See the `Loading` DocC article for the full case-by-case breakdown and the per-case `Prism`/plain-property access (`state.loaded`, `state.failed`, etc.).

#### Pattern 9: Point-free stand-ins for default/ignored closures (especially in test fixtures)

**Before (Imperative — a `{ _, _ in someValue }` lambda just to satisfy a default parameter)**:
```swift
struct ServiceMock {
    var fetchUser: (String, Int) -> User = { _, _ in User(id: "default", name: "Guest") }
    var onEvent: (Event) -> Void = { _ in }
    var validate: (String) -> Bool = { _ in fatalError("validate not implemented in this test") }
}
```

**After (Functional — `const`, `ignore`, and `fail` from `CoreFP` name the intent directly)**:
```swift
import CoreFP

struct ServiceMock {
    // const(value) ignores its arguments and always returns `value` — has overloads
    // for 0 through 4+ ignored parameters, matching whatever arity you need.
    var fetchUser: (String, Int) -> User = const(User(id: "default", name: "Guest"))

    // ignore(...) accepts any arguments and returns Void — for "don't care, no-op" stubs.
    var onEvent: (Event) -> Void = ignore

    // fail(message) returns a function that traps with a clear message if it's
    // ever actually called — better than a silent wrong-default in a fixture
    // that's supposed to be overridden per-test.
    var validate: (String) -> Bool = fail("validate not implemented in this test")
}
```

`withArg(_:)` is the point-free way to adapt a single-argument function (including a bare KeyPath) to a multi-argument call site without writing a wrapping closure:
```swift
let firstCharacter: (String) -> Character? = \.first
// Adapt to a 2-arg call site that only cares about the first element of a tuple:
let firstCharacterOfPair: (String, Int) -> Character? = firstCharacter |> withArg(\.0)
```

Reach for these whenever you'd otherwise write `{ _ in ... }`/`{ _, _ in ... }` purely to discard arguments, or a lambda that just returns a constant — the named function documents *why* the arguments are ignored (default stub vs. genuinely a no-op vs. deliberately unimplemented) better than an anonymous closure does.

### Refactoring Checklist:

- [ ] Replace if-let chains with `>>-` (bind)
- [ ] Replace nested optionals with Kleisli composition `>=>`
- [ ] Replace try/catch with the `Result` monad
- [ ] Replace guard/if-else with functional alternatives
- [ ] Replace for loops with map/flatMap/filter
- [ ] Replace var with let
- [ ] Extract functions for better composition
- [ ] Use function composition `>>>`, `<<<` instead of nested calls
- [ ] Use pipe `|>` for better readability
- [ ] Replace dependency passing with the Reader monad — but only for actual environment/dependency context, not ordinary parameters (see `reader-monad-guide`)
- [ ] Use `Validation` (not `Either`) when you need to accumulate every error instead of short-circuiting
- [ ] Replace hand-rolled multi-state UI enums with `Loading<Success, Failure>` + `loadedOrPrevious`
- [ ] Replace `{ _ in ... }` / `{ _, _ in ... }` default-closure stubs with `const`/`ignore`/`fail`
- [ ] Add type annotations for clarity

### Guidelines:

1. **Keep it readable**: Don't force functional style if it hurts readability
2. **Start small**: Convert one function at a time
3. **Test thoroughly**: Ensure refactored code behaves identically
4. **Use types**: Let the type system guide the refactoring
5. **Compose**: Build larger functions from smaller, composable pieces

### Ask the developer:
1. What code do they want to refactor?
2. What is the main goal (reduce nesting, eliminate mutation, better composition)?
3. Are there any performance requirements?
4. Should we prioritize readability or functional purity?

Provide the refactored code with explanations of the transformations made.
