# Convert Imperative Code to Functional Style

Help convert imperative Swift code to functional style using the FP library.

## Skill Prompt

You are helping a developer refactor imperative Swift code into functional style using the FP library's operators and patterns.

### Instructions:

1. **Identify patterns**: Look for imperative patterns that can be replaced with functional equivalents
2. **Use FP operators**: Replace imperative constructs with `<£>`, `<*>`, `>>-`, `>=>`, etc.
3. **Leverage monads**: Use Optional, Result, Either, Reader, Array for effect handling
4. **Compose functions**: Replace nested calls with function composition `>>>`, `<<<`, `|>`
5. **Eliminate mutation**: Replace var with let, loops with map/flatMap/filter
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
        guard !name.isEmpty else { return nil }
        return name.uppercased()
    }
}

// Or with kleisli composition:
let processUser = findUser >=> (\.profile) >=> (\.name) >=> uppercasedIfValid

func uppercasedIfValid(_ name: String) -> String? {
    name.isEmpty ? nil : name.uppercased()
}
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
    <£> (\.value)
    >>- { guard $0 > 5 else { return [] }; return [$0 * 2] }
    |> { $0.reduce(0, +) }

// Or more readable:
let transform = (\.value) >>> (*2) >>> { $0 > 10 ? [$0] : [] }
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

**After (Functional)**:
```swift
func processData() -> String {
    let result: Result<String, Error> = fetchData()
        >>- parse
        >>- validate
        <£> transform

    return result.match(
        caseLeft: { $0 },
        caseRight: { "Error: \($0)" }
    )
}

// Or with kleisli composition:
let pipeline = fetchData >=> parse >=> validate >=> (Result.success • transform)
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
        bs <£> { b in
            a + b
        }
    }
}

// Or with liftA2:
func combinations(as: [Int], bs: [Int]) -> [Int] {
    liftA2(+)(as, bs)
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

let processUser: (String) -> Reader<Config, String?> = { id in
    fetchUser(id).mapT { $0.name }
}

// Usage:
let config = Config(apiKey: "key", baseURL: URL(string: "https://api.com")!)
let userName = processUser("123")(config)
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
        .partitionEithers()  // Separate lefts and rights
}

// Helper:
extension Array where Element: EitherProtocol {
    func partitionEithers() -> ([Element.LeftType], [Element.RightType]) {
        reduce(into: ([], [])) { result, either in
            either.match(
                caseLeft: { result.0.append($0) },
                caseRight: { result.1.append($0) }
            )
        }
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

**After (Functional)**:
```swift
func validateUser(_ user: User) -> Result<User, ValidationError> {
    .success(user)
        >>- validateName
        >>- validateAge
        >>- validateEmail
}

let validateName: (User) -> Result<User, ValidationError> = { user in
    user.name.isEmpty ? .failure(.emptyName) : .success(user)
}

let validateAge: (User) -> Result<User, ValidationError> = { user in
    user.age < 18 ? .failure(.tooYoung) : .success(user)
}

let validateEmail: (User) -> Result<User, ValidationError> = { user in
    user.email.contains("@") ? .success(user) : .failure(.invalidEmail)
}

// Or with kleisli composition:
let validateUser = validateName >=> validateAge >=> validateEmail
```

### Refactoring Checklist:

- [ ] Replace if-let chains with `>>-` (bind)
- [ ] Replace nested optionals with Kleisli composition `>=>`
- [ ] Replace try/catch with Result monad
- [ ] Replace guard/if-else with functional alternatives
- [ ] Replace for loops with map/flatMap/filter
- [ ] Replace var with let
- [ ] Extract functions for better composition
- [ ] Use function composition `>>>`, `<<<` instead of nested calls
- [ ] Use pipe `|>` for better readability
- [ ] Replace dependency passing with Reader monad
- [ ] Use Either for validation with error accumulation
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
