# Project review plan (2026-10-01)

Findings from a full review of FP 2.2.0 (`3ff729b`): inconsistent API, wrong FP concepts and performance. Four parallel reviews (CoreFP, DataStructure sum/collection types, Reader/Stateful/Writer, macros); most findings were reproduced against the real code with throwaway probes, the rest traced by reading.

Paths are relative to `Sources/` unless stated. Line numbers are as of `3ff729b` and will drift; search for the quoted code.

Workflow: one step per PR, each with regression tests in both the core and operator test targets where an operator is involved. Tick items as they land.

## Done

- [x] **#101** `@Prisms`/`@Lenses` with function-typed payloads and properties: PR #102 (`bugfix/prisms-function-payload`)
- [x] NUL bytes replacing `\U` / `\u` / `\x -` in 9 files (doc comments, test comments, `WitnessMacro.swift:385` string literal): commit `7697f82` on `bugfix/review-findings` (not pushed yet)

---

## Step 1: non-breaking bug fixes (patch release)

### Decisions (2026-10-02)
- IdentifiedArray id changes through optics (`traversed`, `traversed(where:)`, `ix(id:)` `tryModifyMut`, `ix(position)`): **revert id changes** per element (ids immutable through optics, like `ix(id:).set` already does). Update the `traversed` docs that say ids MAY change.
- Power: **remove the `^` operator** outright (no deprecation cycle). Still fix `power` (negative exponents, squaring).
- `private` hosts for `@Iso`/`@DeriveMonoid`/`@Witness`/`@Mock`: **diagnose like `@Lenses`** ("use `fileprivate`").
- `@Lenses` Sendable: **emit `extension S: Sendable {}`** via an extension role when not already declared; fix the `Macros.md` example accordingly.
- `@Mock` on `AnyObject` / `Sendable` protocols: **adapt the output** (`final class` mock for `AnyObject`, `@Sendable` stored closures for `Sendable`).
- `FPMacrosExpander` drift: **delete `ExpandOptic` and `FPMacrosExpander`** (Xcode "Expand Macro" covers it). Touch points: `Package.swift`, `.swiftlint.yml`, `CONTRIBUTING.md`, `CHANGELOG.md`, and outside the repo `~/.claude/skills/fp-optics/SKILL.md` + `expand-optic.sh` (rewrite the skill's "manual boilerplate" section to not depend on the script). This supersedes the ExpandOptic sub-items below.
- `@Witness` / `@Mock` throws: **preserve `throws(E)`** in closure types and forwards; `rethrows` becomes `throws` in the mock closure type, and is diagnosed in `@Witness`.
- `castOptionally` → `<From, T>(T.Type) -> (From) -> T?` and drop `@discardableResult` from `Mutable.mutate`: **both in the patch release**.

### Status (2026-10-02)
All Step 1 items done on `bugfix/review-findings`. Caveats:
- `@Witness` settable-property parents work only when the child protocol is class-bound (`protocol Child: AnyObject, Parent`); the macro can't see parent members. A user-written parent with associated types still fails in generated code (undetectable from syntax).
- `@Mock` `rethrows` requirements call the closure through an immediately-applied closure to stay `rethrows`; that relies on a compiler-checker leniency a future Swift could close.
- `@Lenses` now has an extension role, so (like `@Prisms`) it can't be used on a type declared inside a function body.
- IdentifiedArray: final decision was **last wins, zero-copy** (not "revert"): reverting needs a per-element snapshot because ids are a read-only closure / `let`.
- `affineTraversal(\.optional).set` follows the standard law (no-op on nil); `OpticLawTests` updated.
- Kleisli/bind `@Sendable` returns applied library-wide, including Publisher/AsyncSequence.

### 1.1 Optics laws
- [x] `CoreFP/Utilities/OpticsComposition.swift:57`, Lens ∘ Prism `set: { s, b in set(s, other.review(b)) }` writes even when the prism misses. `S{ r: .failure }` → `set(s, 5).r == .success(5)` while `over` is a no-op. Fix: guard `other.preview(get(s)) != nil`.
- [x] `OpticsComposition.swift:122`, AffineTraversal ∘ Prism checks only the outer preview. Fix: `preview(s).flatMap(other.preview).map { _ in set(s, other.review(b)) } ?? s` (also removes eager `const(...)`).
- [x] `CoreFP/Utilities/AffineTraversal.swift:198`, `affineTraversal(_: WritableKeyPath<S, A?>)` `set` is unconditional (its own `tryModifyMut` at :200 is guarded). Fix: guard non-nil.
- [x] Laws above also leak into `WritableFocus[optic:]` (`WritableFocus.swift:85`) and `Binding[optic:]` (`Binding+Optics.swift:109`); add tests there.
- [x] `CoreFP/Utilities/Prism.swift:138`, `Prism.set` builds `review(a)` eagerly via `const`. Make lazy.

### 1.2 IdentifiedArray invariants
- [x] `DataStructure/IdentifiedArray/IdentifiedArray+Optics.swift:75-100`, `traversed` / `traversed(where:)` call `rebuildIndex()` (`IdentifiedArray.swift:278`) which doesn't dedupe; mapping two ids to the same value then `remove(at:)` + `[id:]` traps "Index out of range". Fix: last-wins dedupe on rebuild (mirror `append`).
- [x] `IdentifiedArray+Optics.swift:32-41`, `ix(id:)` `tryModifyMut` doesn't rekey when `f` changes the id (`set` does guard). Fix: `rekeyIfNeeded` or revert like `set`.
- [x] `IdentifiedArray.swift:51-67`, `ix(position)` documents duplicate ids as a precondition but never enforces it.

### 1.3 Numeric
- [x] `CoreFP/Utilities/NumericOperations.swift:71-74`, `power`: `guard exp > 0 else { return 1 }` → `2.0 ^ -1 == 1`. Handle negative exponents (fractional types: `1 / power(base, -exp)`), use exponentiation by squaring.
- [x] `^` precedence: stdlib's `^` is `AdditionPrecedence`, not what `PrecedenceGroups.swift:48` says; `2.0 * 3.0 ^ 2 == 36`. At minimum fix the docs. **Decision needed:** keep `^` or add `**` with a proper precedence group.
- [x] `CoreFP/Monoid/NumericMonoid.swift:221-269`, Float/Double/CGFloat `HasMin`/`HasMax` use `±greatestFiniteMagnitude`; identity fails at `±.infinity`. Use `±.infinity`.

### 1.4 Concurrency leaks and ordering
- [x] `CoreFP/ModernConcurrency/AsyncThrowingStream+Result.swift:29,55` and `DataStructure/Either/AsyncThrowingStream+Either.swift:20-61`: inner `Task` never cancelled; add `continuation.onTermination = { _ in task.cancel() }`. `toEitherStream` also swallows non-`Failure` errors (:31-33).
- [x] `CoreFPOperators/Combine/Publisher+ApplicativeOperators.swift:28` and `ModernConcurrency/AsyncSequence+ApplicativeOperators.swift:32`: `<*` is `rhs *> lhs`, which runs effects right-first. Delegate to `Publisher.seqLeft`; add a named `AsyncStream.seqLeft`.
- [x] `CoreFP/Combine/Publisher+Alternative.swift:13`, `altPublisher` calls `rhs()` eagerly. Use `Deferred`.

### 1.5 Misc
- [x] `CoreFP/Utilities/Mutable.swift:34,41`, `mutate` is `@discardableResult` but returns a copy, so `x.mutate { … }` silently does nothing. Remove the attribute.
- [x] `CoreFP/Utilities/Cast.swift:9`, `castOptionally<T>(_:) -> (T) -> T?` can't fail. Make it `<From, T>(_: T.Type) -> (From) -> T?`.
- [x] Kleisli `>=>`/`kleisliBack` for `Array+Monad.swift:20`, `Optional+Monad.swift:20`, `Result+Monad.swift:20`, `ArrayTOptional+Monad.swift:27`, `ArrayTResult+Monad.swift:38`, `OptionalTArray+Monad.swift:33`, `OptionalTResult+Monad.swift:37` return non-`@Sendable` closures, so `f >=> g >=> h` doesn't compile in Swift 6. Return `@Sendable`. Same for `Array/Optional/Result.bind`, `Result.foldMap`, `Array.foldLeft/foldRight/foldMap`, `bindT`.
- [x] `DataStructure/Reader/ReaderTWriter+Applicative.swift:21`, `liftA2` calls each reader twice. Bind locals once.

### 1.6 Macros
- [x] Nested in a generic type: `LensesMacro.swift:190,370-376`, `PrismsMacro.swift:141,277-283` emit `static let` → "static stored properties not supported in generic types" (`struct Outer<T> { @Lenses struct Inner {…} }`, also `@ApplyOptics(recursively:)` on generic roots). Fix: always `static var lens: Lenses { Lenses() }`.
- [x] `@Lenses` requires `Sendable` host/properties (`CoreFP.lens` is `<S: Sendable, A: Sendable>`); the `Macros.md:33-39` headline `public struct Config` example doesn't compile. Diagnose or document; fix the doc example.
- [x] Property observers (`var x: Int { didSet {} }`) treated as computed: `LensesMacro.swift:277`, `DeriveMonoidMacro.swift:21`, `@Iso`. Count `willSet`/`didSet`-only accessor blocks as stored.
- [x] Multi-binding `var a, b: Int` loses `a`: `LensesMacro.swift:283-300`, `DeriveMonoidMacro.swift:23`, `@Iso`. Take the type from the last annotated binding.
- [x] Un-annotated stored props are silently skipped by `@DeriveMonoid` (identity law breaks: `var b = Sum(5)` → `combine(identity, x).b == 5`) and `@Iso` (round-trip breaks). Diagnose like `@Lenses` does.
- [x] Initialised `let` included in `@DeriveMonoid`/`@Iso` memberwise call ("extra argument"); exclude like Lenses' `isConstant`.
- [x] IUO `T!` in type positions (`@Lenses`, `@Iso`): rewrite to `T?`.
- [x] `private` hosts break `@Iso`, `@DeriveMonoid`, `@Witness`, `@Mock` (`WitnessMacro.swift:373`). Map to `fileprivate` or diagnose like Lenses/Prisms.
- [x] `private(set)` read as `private` (`LensesMacro.swift:41-67` ignores `modifier.detail`): lens silently dropped; `public private(set)` gets a public writable lens.
- [x] `@Witness`:
  - [x] (partial) Inherited protocols forwarded as raw names (`WitnessMacro.swift:158-160,242-244,278-280`): `Equatable`, `Sendable & AnyObject` compositions, parents with associated types, parents with settable props.
  - [x] `some P` parameters not erased (`:187-197`).
  - [x] Generic erasure unsound when `T` appears more than once or nested (`[T]`, `(T, T)`); `Macros.md:13` promises a diagnostic.
  - [x] Property `{ get async throws }` drops `try await` (`:208-225,271`).
  - [x] Typed `throws(E)` erased to untyped `throws` (`:203-204`).
  - [x] Overload names collide (`f(id: Int)` / `f(id: String)` → both `fWithId`) (`:319-330`).
  - [x] `Self` in requirements resolves to the witness struct. Diagnose.
  - [x] Variadic params become single-element (`:178-183`). Diagnose.
  - [x] `var target = instance` "never mutated" warning (`:275`).
- [x] `@Mock` (`MockMacro.swift`):
  - [x] `AnyObject` / `Sendable` protocols (`:22-24`): emit class / `@Sendable` closures, or diagnose.
  - [x] Non-escaping closure params, `inout`, variadic, `_:` unnamed, `@autoclosure` (`:156,165,172`).
  - [x] `throws(E)` and `rethrows` (`:153-156,166`).
  - [x] Overload collisions (`:158-159`).
- [x] `ExpandOptic` / `FPMacrosExpander` drift:
  - [x] Expander has no `Prismatic` `ExtensionMacro`.
  - [x] `ExpandOptic/main.swift:46-64` wraps members in `extension Name {}`, so the printed `init` redeclares the synthesized memberwise init, and nested types print `extension Inner` not `extension Outer.Inner`.
  - [x] Walker (`main.swift:72-90`) ignores `@ApplyOptics` and `@FPMacros.Lenses`.
  - [x] Stop the manual copy: share sources between Plugin and Expander (symlink / shared target), or add a test diffing outputs. Fix the "always in sync" claims in the fp-optics skill `SKILL.md:214` and `CONTRIBUTING.md:52`.

---

## Step 2: performance (non-breaking)

Items 1–3 (everything except the Zipper) done on `feature/review-step2-performance`. Notes: the
old `reduce` traversals already stopped calling `f` after a failure (only the copying was
quadratic); `ArrayTArray.traverse` is a cartesian product whose output is inherently that large,
so it was left alone; `mconcat`'s `Array(dropFirst())` is an O(n) pointer copy imposed by the
`sconcat(_:_:)` requirement's `[Self]` parameter and was left alone. Zipper done separately (shared array + index).

- [x] Quadratic `acc + [x]` in `reduce`: `ArrayTOptional+Traversable.swift:9`, `ArrayTResult+Traversable.swift:8`, `ArrayTArray+Traversable.swift:8` (measured 4× time for 2× input; also keeps calling `f` after failure), `OptionalTArray+Monad.swift:16-18`, `PublisherTArray+Monad.swift:24-26` (n-deep zip chain), `DataStructure/Either/EitherTArray+Monad.swift:16-17`. Use a loop with `reserveCapacity` and early exit.
- [x] NonEmpty: `NonEmpty+Traversable.swift:92-95` (`ne.append(b)` per element), `OptionalTNonEmpty+Monad.swift:14`, `EitherTNonEmpty+Monad.swift:21`, and `nonEmpties.dropFirst().reduce(first, NonEmpty.combine)` in Reader/Stateful/Writer NonEmpty files. Build once from an array.
- [x] Writer log folds `results.reduce(log) { W.combine($0, $1.log) }` (`WriterTArray+Monad.swift:13`, `WriterTNonEmpty+Monad.swift:15,47`): use `W.sconcat`.
- [x] Default `sconcat`/`mconcat` (`Monoid/Semigroup.swift:65`, `Monoid/Monoid.swift:66` extra `Array(dropFirst())` copy): override for `Set` (`formUnion`) and `Dictionary` (`merge`) with `reduce(into:)`.
- [x] Zero-copy optics:
  - [x] `CoreFP/Utilities/Traversal.swift:118,127`, `Lens.traversal` / `Prism.traversal` use get/set instead of `modifyMut` / `tryModifyMut` (`^\S.items >>> [Item].each` copies the array).
  - [x] `Collection/Collection+Traversal.swift:51-55,92-96`, `Dictionary.eachValue(Indexed)` copies each value and double-hashes. Iterate `dict.values` indices in place.
  - [x] `DataStructure/Stateful/Stateful+Optics.swift:42-44,74`, `zoom` copies the focus (measured ~1700× slower than `lens.lift`); its comment at :15 claims otherwise. Route through `modifyMut`.
- [x] Zipper moves O(n), documented O(1) (`Zipper.swift:8,23-25`, `Zipper+Navigation.swift:12,21`; `duplicate()` O(n²)). Store `left` reversed (closest last) or fix the docs. **Done:** one shared `elements` array + `focusedIndex`; non-mutating O(1) moves, lazy `left`/`right` views (source-breaking type change).

---

## Step 3: law violations that change behaviour (breaking, target 3.0)

### Policy (2026-10-02): Haskell is the source of truth
- A stack gets a monad surface (`flatMapT`/`bindT`/`kleisliT`, `>>-`/`-<<`/`>=>`/`<=<`) **only where Haskell's `transformers` defines one**: `ReaderT r m` (`Reader<E, M<A>>`, any inner), `MaybeT`/`ExceptT` (`M<A?>`, `M<Either>`, `M<Result>`), `WriterT` (`M<Writer<W, A>>`, incl. `EitherTWriter`), and the `Stateful<S, Optional|Either|Result|Writer>` stacks (isomorphic to `MaybeT`/`ExceptT`/`WriterT` over `State`, or `StateT s (Writer w)`).
- Where there is a monad, `<*>`/`liftA2`/`*>`/`<*` are **derived from bind** (`<*> == ap`). The parallel/compose applicative is a separate concept (`Compose`) and does not share the monad's operators.
- Bind always takes a **full-stack continuation** (`a -> t m b`); the inner-only `flatMapT`s get the real bind where lawful.
- Where Haskell has **no** monad (`M<[A]>`/`M<NonEmpty>` over a non-commutative `M`: StatefulTArray/NonEmpty, WriterTArray/NonEmpty; `Writer<W, M<A>>`: WriterTReader/Stateful/Publisher/AsyncStream; `M<Stateful<S, A>>`: XTStateful; `Either<L, Stateful<S, A>>`): **remove** the monad surface (remove, don't rename); functor/applicative stay.
- `Loading` and `Validation` must not require `Failure: Error` (UI-facing failures are strings/view structs; `Error` breaks `Equatable`). Only `Result` bridges are constrained with `where Failure: Error`.

**Resolved by the policy above.** 3a done on `feature/review-step3a` for the 16 non-stream stacks (ArrayT/NonEmptyT/EitherT/OptionalT/StatefulT/WriterT over Either/Optional/Result); `M<Writer>` stacks confirmed already equal to WriterT `ap`. Stream stacks (PublisherT/AsyncSequenceT × Either/Optional/Result) deferred until the base Publisher/AsyncStream `<*>` (zip vs bind) is decided. Also found for 3c: ArrayTWriter, OptionalTWriter and ResultTWriter `flatMapT` take an inner-only `(A) -> Writer<W, B>` continuation (WriterT bind needs `A -> M<Writer<W, B>>`).

### 3.1 `<*>` ≠ `ap` (applicative disagrees with bind)
- [ ] EitherTOptional (`.right(nil) <*> .left(l)`: `.left` vs `.right(nil)`), EitherTResult, EitherTArray, OptionalTEither, ArrayTEither (error duplicated per value), NonEmptyTEither, NonEmptyTResult, NonEmptyTOptional: `DataStructure/Either/*+Applicative.swift`, `DataStructure/NonEmpty/*+Applicative.swift`
- [ ] ArrayTOptional (`[nil] <*> [1,2]` → `[nil, nil]` vs `[nil]`), ArrayTResult, OptionalTArray edge (`.some([]) <*> nil`): `CoreFP/Array/*`, `CoreFP/Optional/*`
- [ ] StatefulTEither / StatefulTResult (`StatefulTResult+Applicative.swift:13` evaluates `sa.run(&s)` eagerly) / StatefulTArray: right-hand state effect always runs. StatefulTOptional is self-inconsistent: `apply` short-circuits (:13,24), `*>`/`<*` don't (:35,43).
- [ ] WriterTEither / WriterTResult / WriterTOptional: log combined even when left fails; bind keeps only the outer log.
- [ ] `Loading` (`Loading+Applicative.swift:20-37,74-80` precedence failed > idle > loading vs `Loading+Monad.swift:13-27`): `.idle <*> .failed(e)` → `.failed` vs `.idle`.
- [ ] AsyncStream / Publisher `apply` is zip (`AsyncSequence+Applicative.swift:9-27`, `Publisher+Applicative.swift:21-25`) while bind is concat/merge, and there's no `pure`. Rename to `zipApply`/`zipWith` or derive from bind.

### 3.2 Exported as monads but not lawful
- [x] Associativity fails (non-commutative outer): StatefulTArray, StatefulTNonEmpty, WriterTArray, WriterTNonEmpty (`*Monad.swift`). Counterexample log `["m","f1","f2","g10","g20"]` vs `["m","f1","g10","f2","g20"]`. Drop `flatMapT`/`>>-`/`-<<`/`>=>` or document "only when S/W commutative". **Removed** (step 3b) together with the other list-inner stacks EitherTArray, EitherTNonEmpty, PublisherTArray, AsyncSequenceTArray; functor/applicative stay.
- [x] Left identity fails (inner log discarded): WriterTReader, WriterTStateful, WriterTPublisher, WriterTAsyncStream (`value.flatMap { fn($0).value }`). No distributive law exists; remove or rename (e.g. `flatMapValueDroppingLog`). **Removed** (step 3b).

### 3.3 `flatMapT` with the wrong shape
- [ ] Continuation can't reach the outer layer (really `fmap(innerBind)`): EitherTStateful, EitherTWriter, ReaderTWriter, ReaderTStateful, StatefulTWriter, ArrayTStateful, OptionalTStateful, ResultTStateful, PublisherTStateful, AsyncStreamTStateful; their `kleisliT`/`>=>` take mismatched arrows. Implement the real bind where lawful (ReaderTWriter, ReaderTStateful, StatefulTWriter, EitherTWriter via Writer traversable) and rename the rest (`flatMapInner`).
  - [x] `XTStateful` (ArrayTStateful, OptionalTStateful, ResultTStateful, PublisherTStateful, AsyncStreamTStateful) and EitherTStateful: no lawful monad, monad surface **removed** (step 3b), not renamed. Also removed the comment-only `+Monad.swift` stubs of StatefulTReader/Publisher/AsyncStream.
  - [x] Real bind for ReaderTWriter, ReaderTStateful, StatefulTWriter (step 3c, `feature/step3c-reader-stateful`): full-stack continuation, inner-only bind removed; applicatives confirmed equal to `ap`; monad laws tested.
  - [x] Real bind (WriterT's, continuation returns the full stack) for EitherTWriter, and also ArrayTWriter, OptionalTWriter, ResultTWriter (step 3c). Inner-only continuation removed, not renamed; applicatives already equal `ap` from the new bind (tested).
- [x] NonEmpty transformers return `NonEmpty<B>?` (not closed, can't chain): EitherTNonEmpty, ReaderTNonEmpty, StatefulTNonEmpty, WriterTNonEmpty. Use `(A) -> M<NonEmpty<B>>`; make `kleisliT` delegate to the bind. (EitherTNonEmpty, StatefulTNonEmpty, WriterTNonEmpty binds were removed in step 3b; ReaderTNonEmpty now binds `(A) -> Reader<E, NonEmpty<B>>` and `kleisliT` delegates to it, step 3c.)

### 3.4 Misnamed / lossy
- [ ] `CoreFP/Array/Array+Monad.swift:63`, `filterM` takes `(Element) -> Bool`, so it's `filter`. Rename or implement real `filterM` (`(Element) -> [Bool]`, powerset).
- [ ] `BasicFreeFunctions+Composition.swift:46`, free `apply(value, fn)` is `|>`, clashing with applicative `apply` everywhere else. Rename (`pipe`) or remove (`call` exists).
- [x] `Validation+Alternative.swift:7-11`, `<|>` drops left errors when both fail; accumulate `E.combine(e1, e2)`. Rename the file to Alt (no `empty`).
- [x] `Loading+Catch.swift:19-20`, `catch` hides `previous`; pass `(Failure, Success?)` or default to keeping it.

---

## Step 4: API consistency (mostly breaking, target 3.0)

- [ ] Operators with inline logic (CLAUDE.md rule): Function `*>`/`<*` (`Function+ApplicativeOperators.swift:17-38`, no named `seqRight`/`seqLeft`), `>>>`/`<<<` (`FunctionComposition.swift:29,51`, and the variadic ones at :75-95 have no named counterpart), `Iso >>>` (`CoreFPOperators/Utilities/IsoComposition.swift:7` ignores `Iso.compose`), AsyncSequence `>=>` (`AsyncSequence+MonadOperators.swift:28-35`), Array `++`, Either `£>` (`Either+FunctorOperators.swift:13-15`), These `£>` (`These+FunctorOperators.swift:13-19`), ReaderTEither `£>` (`ReaderTEither+FunctorOperators.swift:21-25`), ReaderTValidation `<£^>`/`<&^>` (`ReaderTValidation+FunctorOperators.swift:11,19`).
- [ ] Transformer `£>`/`<£` overloads hijack the base operator (`Reader<Int,[Int]> £> "x"` replaces inner elements, `Stateful<Int,[Int]> £> "x"` replaces the whole output). Add transformer-only `£^>` / `<£^` like `<£^>`, remove the transformer `£>` overloads. Only OptionalTArray has them in CoreFP.
- [ ] `mapT` naming: EitherT `mapTEitherX(fn, value)` + `fmapTEitherX(fn)`; ValidationT `mapTValidationX(fn) -> (V) -> V` with no `fmapT`; NonEmptyT/OptionalT/ArrayT methods `.mapT` + static `fmapT`; ReaderT statics named `fmap` (overloading `Reader.fmap`) instead of `fmapT`; StatefulTValidation has no `.mapT`. `EitherTValidation+Functor.swift:7,15` are both `fmapTEitherValidation`. Pick one convention.
- [ ] Add `map` to `Either` and `Validation` (only `mapRight` / `mapSuccess` today).
- [ ] Conversions/labels: `Either.result()` vs `Validation.toResult()` vs `validationFromEither` vs `These.fromEither`; `bifoldMap(leftBy:rightBy:)` vs `bifoldMap(_:_:)`.
- [ ] Missing siblings: `pure` for Validation and Loading (fix `Loading.swift:25-26` doc), `mapFailure`/`bimap` on Loading, `JoinVoid` for NonEmpty/These/Loading, PublisherT*/AsyncStreamT* `apply`/`<*>`/`kleisliT`/`>=>`, `£>` for other transformers, Reader variadic `zip` vs Stateful/Writer `zip3`/`zip4`.
- [ ] Sendable contract: Publisher `apply`/`<*>` take non-`@Sendable` inner closures (`Publisher+Applicative.swift:21`, `ReaderTPublisher+Applicative.swift:11`, `StatefulTPublisher+Applicative.swift:11`, `WriterTPublisher+Applicative.swift:12`); `Result.mapLeft` (`Result+Functor.swift:14`) vs `mapRight`/`bimap` constraints; Publisher `<£>` vs `<&>` Sendable constraints differ; `Function+Monad.swift:43` `kleisli` needs `A: Sendable` unnecessarily.

---

## Step 5: policy decisions (need Luiz's call)

### Decisions (2026-10-02)
- `NonEmpty` / `IdentifiedArray`: **require `Sendable` on the element type** (`NonEmpty<A: Sendable>`, `IdentifiedArray<ID, Element: Sendable>`). A conditional `Semigroup where A: Sendable` is impossible (marker-protocol rule), so the constraint goes on the type.
- Combine and eager `Task`/`AsyncStream` code in FP: **keep both** (behind `#if canImport(Combine)` / availability), as a documented exception to the no-Combine / async-in-sibling-library rules.
- `Gen`: **no runners at all**; it is generic over the RNG (`Gen<R: RandomNumberGenerator & Sendable, Value> = Stateful<R, Value>`) and always runs with an explicitly injected generator (`gen.run(&rng)`, e.g. `SplitMix64(seed:)` or `AnyRandomNumberGenerator`). `generate()`, `generate(seed:)` and `samples(seed:count:)` removed. Binding the RNG early into a `() -> Value` was considered and rejected (needs a shared mutable RNG box).
- Done on `feature/review-step5`.

- [ ] Unconditional `Semigroup` (hence `Sendable`) on `NonEmpty` (`NonEmpty+Semigroup.swift:9`) and `IdentifiedArray` (`IdentifiedArray+Semigroup.swift:17`): `NonEmpty<NonSendableClass>` crosses isolation via `T: Semigroup` with no diagnostic (verified in Swift 6 mode). Accept and document, or gate.
- [ ] Combine in DataStructure (`Either/PublisherTEither+*`, `Completion+Either.swift`, `#if canImport(Combine)`) vs "no Combine in library code".
- [ ] Eager `Task`/`AsyncStream` in `AsyncSequenceTEither+*`, `AsyncThrowingStream+Either.swift` vs DeferredTask rule and "async belongs to sibling library".
- [ ] `Gen.generate()` (`Gen/Gen.swift:103-106`) uses ambient `SystemRandomNumberGenerator`; inject the RNG.
