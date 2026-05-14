// DeferredTask<Success>: a lazy IO-like computation that runs only when .run() is called.
// Nothing executes until run() — analogous to Haskell's IO monad or Scala's cats-effect IO.

/// A lazy, description of an async computation that executes only when ``run()`` is called.
///
/// `DeferredTask<Success>` is the Swift async/await equivalent of Haskell's `IO` monad or
/// Scala's `cats-effect IO`. It wraps an `async` closure and does nothing until explicitly
/// started — no `Task` is created, no work is performed, until `run()` or `eraseToTask()` is
/// called.
///
/// This makes `DeferredTask` referentially transparent: the same `DeferredTask` value can be
/// run multiple times, returning independent async computations each time, and can be safely
/// stored, passed, and transformed without triggering side effects.
///
/// `DeferredTask` is the single-value complement to ``DeferredStream``. It is a full
/// ``Functor``, ``Applicative``, and ``Monad`` — operator forms are available in
/// `CoreFPOperators`.
///
/// ## Creating a DeferredTask
///
/// ```swift
/// // Wrap any async computation:
/// let fetchUser = DeferredTask {
///     try await apiClient.getUser(id: userId)
/// }
///
/// // Capture a throwing computation and surface it as Result:
/// let safeFetch = DeferredTask.catching {
///     try await apiClient.getUser(id: userId)
/// }
/// // safeFetch: DeferredTask<Result<User, Error>>
/// ```
///
/// ## Running a DeferredTask
///
/// ```swift
/// let user = await fetchUser.run()            // execute inline
/// let task: Task<User, Never> = fetchUser.eraseToTask()  // fire-and-forget
/// ```
///
/// ## Functor / Monad operations
///
/// ```swift
/// let userName: DeferredTask<String> = fetchUser.map(\.name)
///
/// let enriched: DeferredTask<Profile> = fetchUser.flatMap { user in
///     DeferredTask { await profileService.enrich(user) }
/// }
/// ```
///
/// ## Kleisli composition
///
/// ```swift
/// let getProfile: (UserID) -> DeferredTask<Profile> =
///     getUser >=> enrichProfile   // using >=> from CoreFPOperators
/// ```
///
/// - SeeAlso: ``DeferredStream``, ``ZIO``
public struct DeferredTask<Success: Sendable>: Sendable {
    let body: @Sendable () async -> Success

    public init(_ body: @escaping @Sendable () async -> Success) {
        self.body = body
    }

    public static func catching<S, E: Error>(_ body: @escaping @Sendable () async throws(E) -> S) -> DeferredTask<Result<S, E>> {
        .init {
            do throws(E) {
                return Result<S, E>.success(try await body())
            } catch {
                return Result<S, E>.failure(error)
            }
        }
    }

    /// Execute the deferred computation.
    public func run() async -> Success { await body() }

    /// Wrap in a Task for fire-and-forget or structured concurrency contexts.
    public func eraseToTask() -> Task<Success, Never> { Task { await body() } }

    /// Wrap in a Task for fire-and-forget or structured concurrency contexts.
    public func eraseToThrowingTask<S, E: Error>() -> Task<S, any Error> where Success == Result<S, E> {
        Task {
            try await body().get()
        }
    }
}
