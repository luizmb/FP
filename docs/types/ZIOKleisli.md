# ZIOKleisli

**Migrated to LongLiveCombine.** `ZIOKleisli` now lives in the [`ReactiveConcurrency`](https://github.com/luizmb/LongLiveCombine) module of the LongLiveCombine library.

`ZIOKleisli<Input, Env, Success, Failure>` is a first-class Kleisli arrow in the ZIO monad:

```
ZIOKleisli<Input, Env, Success, Failure>
≅ (Input) -> ZIO<Env, Success, Failure>
≅ (Input) -> Env -> DeferredTask<Result<Success, Failure>>
```

It wraps a function from some input type to a `ZIO`, promoting it into a named value with its own Functor, Monad, and Kleisli composition operations.

This type is no longer part of the FP library. Import it from LongLiveCombine instead:

```swift
// Package.swift
.package(url: "https://github.com/luizmb/LongLiveCombine.git", from: "1.0.0")
```

```swift
import ReactiveConcurrency
```

For documentation on all operations (`map`, `contramap`, `contramapEnvironment`, `dimap`, `flatMap`, `andThen`, `>=>`, etc.), see the LongLiveCombine repository.
