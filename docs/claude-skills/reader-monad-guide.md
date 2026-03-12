# Reader Monad Guide

Help developers understand and effectively use the Reader monad for dependency injection and configuration management.

## Skill Prompt

You are helping a developer understand and implement the Reader monad pattern for elegant dependency injection in Swift.

### What is Reader Monad?

Reader monad represents computations that depend on a shared environment/configuration:
- **Type**: `Reader<Environment, Output> = (Environment) -> Output`
- **Purpose**: Pass dependencies implicitly without threading them through function parameters
- **Benefits**: Composable, testable, referentially transparent

### Core Concepts:

#### 1. Basic Reader

```swift
struct Config {
    let apiKey: String
    let baseURL: URL
    let timeout: TimeInterval
}

// Function that needs config
let fetchData: Reader<Config, Data> = Reader { config in
    // Use config.apiKey, config.baseURL, config.timeout
    return Data()
}

// Run the reader with actual config
let config = Config(apiKey: "...", baseURL: URL(string: "...")!, timeout: 30)
let data = fetchData(config)
```

#### 2. Reader Operations

**ask** - Get the environment:
```swift
let getAPIKey: Reader<Config, String> = Reader.ask.fmap(\.apiKey)

// Usage:
let apiKey = getAPIKey(config)  // Returns config.apiKey
```

**asks** - Query specific part of environment:
```swift
let getBaseURL: Reader<Config, URL> = Reader.asks(\.baseURL)
```

**local** - Modify environment locally:
```swift
let fetchWithLongerTimeout: Reader<Config, Data> = fetchData.local { config in
    Config(
        apiKey: config.apiKey,
        baseURL: config.baseURL,
        timeout: config.timeout * 2  // Double timeout
    )
}
```

#### 3. Composing Readers

**Using fmap** (Functor):
```swift
let userID: Reader<Config, String> = Reader { config in
    // Fetch from config.baseURL
    return "user123"
}

let userName: Reader<Config, String> = userID.fmap { id in
    id.uppercased()
}
```

**Using flatMap** (Monad):
```swift
let fetchUser: (String) -> Reader<Config, User> = { id in
    Reader { config in
        // Use config to fetch user by id
        return User(id: id, name: "John")
    }
}

let processUser: Reader<Config, String> = userID.flatMap(fetchUser).fmap(\.name)

// Or with operators:
let processUser = userID >>- fetchUser <£> (\.name)
```

**Using Kleisli composition**:
```swift
let fetchUser: (String) -> Reader<Config, User> = { id in
    Reader { config in
        // Fetch user using config
        return User(id: id, name: "John")
    }
}

let fetchProfile: (User) -> Reader<Config, Profile> = { user in
    Reader { config in
        // Fetch profile using config
        return Profile(user: user)
    }
}

// Compose the functions
let fetchUserProfile = fetchUser >=> fetchProfile

// Use the composed function
let profile = fetchUserProfile("user123")(config)
```

### Practical Patterns:

#### Pattern 1: Service Layer with Dependencies

```swift
struct Dependencies {
    let database: Database
    let logger: Logger
    let apiClient: APIClient
}

// Services return Readers
struct UserService {
    static func findUser(id: String) -> Reader<Dependencies, User?> {
        Reader { deps in
            deps.logger.log("Finding user \(id)")
            return deps.database.fetchUser(id: id)
        }
    }

    static func saveUser(_ user: User) -> Reader<Dependencies, Void> {
        Reader { deps in
            deps.logger.log("Saving user \(user.id)")
            deps.database.save(user)
        }
    }
}

// Compose services
let updateUser: (String, String) -> Reader<Dependencies, User?> = { id, newName in
    UserService.findUser(id: id) >>- { user in
        guard let user = user else {
            return Reader.pure(nil)
        }
        let updated = User(id: user.id, name: newName)
        return UserService.saveUser(updated) >>- { _ in
            Reader.pure(updated)
        }
    }
}

// Run with dependencies
let deps = Dependencies(database: db, logger: logger, apiClient: client)
let result = updateUser("123", "Jane")(deps)
```

#### Pattern 2: Configuration-based Computation

```swift
struct AppConfig {
    let isDevelopment: Bool
    let apiEndpoint: URL
    let featureFlags: [String: Bool]
}

let fetchEndpoint: Reader<AppConfig, URL> = Reader { config in
    config.isDevelopment
        ? URL(string: "http://localhost:8080")!
        : config.apiEndpoint
}

let isFeatureEnabled: (String) -> Reader<AppConfig, Bool> = { feature in
    Reader { config in
        config.featureFlags[feature] ?? false
    }
}

// Conditional behavior based on config
let conditionalFetch: Reader<AppConfig, Data> = isFeatureEnabled("newAPI") >>- { enabled in
    enabled ? fetchFromNewAPI : fetchFromOldAPI
}
```

#### Pattern 3: Testing with Mock Dependencies

```swift
protocol Database {
    func fetchUser(id: String) -> User?
}

struct MockDatabase: Database {
    var users: [String: User] = [:]

    func fetchUser(id: String) -> User? {
        users[id]
    }
}

// Test using mock dependencies
func testUserService() {
    let mockDB = MockDatabase(users: ["123": User(id: "123", name: "Test")])
    let testDeps = Dependencies(
        database: mockDB,
        logger: MockLogger(),
        apiClient: MockAPIClient()
    )

    let result = UserService.findUser(id: "123")(testDeps)
    assert(result?.name == "Test")
}
```

#### Pattern 4: ReaderT for Multiple Effects

Combine Reader with other monads using ReaderT:

**ReaderT + Optional** (for nullable results with dependencies):
```swift
let findUserOptional: (String) -> Reader<Dependencies, User?> = { id in
    Reader { deps in
        deps.database.fetchUser(id: id)
    }
}

let getUserName: (String) -> Reader<Dependencies, String?> =
    findUserOptional >=> { Reader { _ in $0?.name } }

// Or using mapT:
let getUserName2: (String) -> Reader<Dependencies, String?> = { id in
    findUserOptional(id).mapT(\.name)
}
```

**ReaderT + Result** (for error handling with dependencies):
```swift
enum DatabaseError: Error {
    case notFound
    case connectionFailed
}

let findUserResult: (String) -> Reader<Dependencies, Result<User, DatabaseError>> = { id in
    Reader { deps in
        guard let user = deps.database.fetchUser(id: id) else {
            return .failure(.notFound)
        }
        return .success(user)
    }
}

let processUserResult = findUserResult("123") >>- { result in
    Reader { deps in
        result.flatMap { user in
            // Process user with deps
            .success(user.name)
        }
    }
}
```

**ReaderT + AsyncSequence** (for streaming with dependencies):
```swift
@available(macOS 10.15, *)
let streamUsers: Reader<Dependencies, AsyncStream<User>> = Reader { deps in
    AsyncStream { continuation in
        for user in deps.database.allUsers() {
            continuation.yield(user)
        }
        continuation.finish()
    }
}

let userNames = streamUsers.mapT(\.name)
```

### Advanced Techniques:

#### Technique 1: Environment Extension

```swift
// Add computed properties to environment for convenience
extension Dependencies {
    var isProduction: Bool {
        !logger.isDebugMode
    }

    var defaultTimeout: TimeInterval {
        isProduction ? 30 : 5
    }
}

let timeout: Reader<Dependencies, TimeInterval> = Reader.asks(\.defaultTimeout)
```

#### Technique 2: Nested Environments

```swift
struct OuterEnv {
    let inner: InnerEnv
    let outerValue: String
}

struct InnerEnv {
    let innerValue: Int
}

// Access nested environment
let getInnerValue: Reader<OuterEnv, Int> = Reader.asks(\.inner.innerValue)

// Or compose Readers
let innerComputation: Reader<InnerEnv, String> = Reader { inner in
    "Value: \(inner.innerValue)"
}

let outerComputation: Reader<OuterEnv, String> = Reader { outer in
    innerComputation(outer.inner)
}
```

#### Technique 3: Multi-level Dependency Injection

```swift
// Different layers with different dependencies
struct DatabaseDeps {
    let connection: Connection
}

struct ServiceDeps {
    let database: DatabaseDeps
    let cache: Cache
}

struct AppDeps {
    let services: ServiceDeps
    let config: Config
}

// Each layer uses its own Reader
let dbQuery: Reader<DatabaseDeps, [Row]> = Reader { deps in
    deps.connection.execute("SELECT * FROM users")
}

let cacheableService: Reader<ServiceDeps, [User]> = Reader { deps in
    if let cached = deps.cache.get("users") {
        return cached
    }
    let rows = dbQuery(deps.database)
    let users = rows.map(User.init)
    deps.cache.set("users", users)
    return users
}

let appOperation: Reader<AppDeps, [User]> = Reader { deps in
    cacheableService(deps.services)
}
```

### Migration Guide:

#### From Manual Dependency Passing:

**Before**:
```swift
func fetchUser(id: String, db: Database, logger: Logger) -> User? {
    logger.log("Fetching \(id)")
    return db.fetchUser(id: id)
}

func processUser(id: String, db: Database, logger: Logger) -> String? {
    fetchUser(id: id, db: db, logger: logger)?.name
}
```

**After**:
```swift
struct Deps {
    let db: Database
    let logger: Logger
}

let fetchUser: (String) -> Reader<Deps, User?> = { id in
    Reader { deps in
        deps.logger.log("Fetching \(id)")
        return deps.db.fetchUser(id: id)
    }
}

let processUser: (String) -> Reader<Deps, String?> =
    fetchUser >=> { Reader { _ in $0?.name } }
```

### Best Practices:

1. **Keep environments small**: Only include what's needed
2. **Use protocols**: Make dependencies mockable for testing
3. **Compose freely**: Leverage Reader's composability
4. **Type aliases**: Create readable type aliases for common Reader types
5. **Start simple**: Begin with basic Reader before moving to ReaderT

### Common Pitfalls:

❌ **Over-using Reader**: Not everything needs to be in Reader
✅ **Use Reader for**: Cross-cutting concerns, configuration, dependencies

❌ **Huge environments**: Putting everything in one giant environment struct
✅ **Split concerns**: Use multiple environment types for different layers

❌ **Ignoring ReaderT**: Trying to handle effects manually
✅ **Use ReaderT**: Combine Reader with Optional, Result, etc.

### Ask the developer:
1. What dependencies do they want to inject?
2. What's the scope of the Reader usage (module, app-wide)?
3. Do they need to combine with other effects (Optional, Result, AsyncSequence)?
4. Are they migrating existing code or starting fresh?
5. What's their testing strategy?

Provide complete, practical examples with best practices and clear explanations.
