# DeferredTask

**Migrated to LongLiveCombine.** `DeferredTask` now lives in the [`ReactiveConcurrency`](https://github.com/luizmb/LongLiveCombine) module of the LongLiveCombine library.

`DeferredTask<A>` is a wrapper for a lazy async computation `() async -> A`. It solves the **deferred execution** problem: a `Task` in Swift starts running the moment you create it. `DeferredTask` lets you *describe* an async computation as a value — compose it, transform it, chain it — without running anything until you explicitly call `.run()`. This makes async code as composable and testable as pure functions.

This type is no longer part of the FP library. Import it from LongLiveCombine instead:

```swift
// Package.swift
.package(url: "https://github.com/luizmb/LongLiveCombine.git", from: "1.0.0")
```

```swift
import ReactiveConcurrency
```

For documentation on all operations (`map`, `flatMap`, `zip`, `race`, monad transformers, Combine bridges, etc.), see the LongLiveCombine repository.
