# DeferredStream

**Migrated to LongLiveCombine.** `DeferredStream` now lives in the [`ReactiveConcurrency`](https://github.com/luizmb/LongLiveCombine) module of the LongLiveCombine library.

`DeferredStream<A>` is a lazy `AsyncSequence` whose production doesn't start until you begin iterating. Unlike `AsyncStream`, which starts its producer closure at construction time, `DeferredStream` defers entirely — nothing runs until `makeAsyncIterator()` is called. This makes streams as composable and reusable as values: you can describe, transform, and chain them before deciding to run them.

This type is no longer part of the FP library. Import it from LongLiveCombine instead:

```swift
// Package.swift
.package(url: "https://github.com/luizmb/LongLiveCombine.git", from: "1.0.0")
```

```swift
import ReactiveConcurrency
```

For documentation on all operations (`map`, `flatMap`, `zip`, `<|>` concatenation, monad transformers, Combine bridges, etc.), see the LongLiveCombine repository.
