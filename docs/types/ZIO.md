# ZIO

**Migrated to LongLiveCombine.** `ZIO` now lives in the [`ReactiveConcurrency`](https://github.com/luizmb/LongLiveCombine) module of the LongLiveCombine library.

`ZIO<Env, Success, Failure>` is a three-layer monad stack:

```
ReaderT Env (ExceptT Failure DeferredTask) Success
≅ Env -> DeferredTask<Result<Success, Failure>>
```

It combines dependency injection (`Reader`), typed error handling (`Result`), and deferred async execution (`DeferredTask`) into a single composable type. The environment is supplied once via `provide`; nothing executes until the resulting `DeferredTask` is `.run()`.

This type is no longer part of the FP library. Import it from LongLiveCombine instead:

```swift
// Package.swift
.package(url: "https://github.com/luizmb/LongLiveCombine.git", from: "1.0.0")
```

```swift
import ReactiveConcurrency
```

For documentation on all operations (`map`, `mapError`, `contramapEnvironment`, `dimap`, `flatMap`, `>=>`, `provide`, etc.), see the LongLiveCombine repository.
