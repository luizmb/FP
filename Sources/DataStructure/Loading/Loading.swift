import CoreFP
import Foundation

/// A four-state lifecycle for any async operation.
///
/// ```
/// idle ───────────────────────────► loading(previous: nil)
///                                         │
///                         ┌───────────────┴──────────────┐
///                         ▼                              ▼
///               loaded(Success)         failed(Failure, previous: Success?)
///                         │                              │
///                         └──────── re-fetch ────────────┘
///                                         │
///                                         ▼
///                                loading(previous: Success?)
/// ```
///
/// The `previous` payload in `.loading` and `.failed` carries the last successful value so UIs
/// can keep showing stale data while a refresh is in flight or after an error.
///
/// ## Functor / Applicative / Monad / Catch
///
/// `Loading` is a `Functor` (``map(_:)``), an `Applicative` with ``zip(_:_:)`` (no `pure` / `apply`
/// because there is no canonical wrap for `.idle` / `.loading` / `.failed`), a `Monad`
/// (``flatMap(_:)``), and supports error recovery via ``catch(_:)``. Operator forms — `<£>`,
/// `<&>`, `£>`, `<£`, `>>-`, `-<<`, `>=>`, `<=<` — live in `DataStructureOperators`.
///
/// ## Driving with `Result`
///
/// ```swift
/// var state: Loading<[Movie], NetworkError> = .idle
///
/// state = state.startLoading()
/// // .loading(previous: nil)
///
/// state = state.applying(.success([movie1, movie2]))
/// // .loaded([movie1, movie2])
///
/// let rows = state.loadedOrPrevious ?? []
/// ```
///
/// ## Prisms
///
/// Each case exposes a `CoreFP.Prism` via the nested `Prisms` struct (`Loading.prism.idle`,
/// `.loading`, `.loaded`, `.failed`) and per-case accessors via `@dynamicMemberLookup`
/// (`state.loaded`, `state.failed`, etc.). An `is(_:)` predicate over the nested
/// `Cases: CaseMatchable` enum is also provided — mirroring what FP's `@Prisms` macro
/// generates for a non-generic enum.
///
/// - SeeAlso: ``map(_:)``, ``zip(_:_:)``, ``flatMap(_:)``, ``catch(_:)``, ``startLoading()``
@dynamicMemberLookup
public enum Loading<Success: Sendable, Failure: Error & Sendable>: Sendable {
    /// No fetch has been initiated yet.
    case idle
    /// A fetch is in progress. `previous` holds the last successful value, if any.
    case loading(previous: Success?)
    /// The last fetch succeeded.
    case loaded(Success)
    /// The last fetch failed. `previous` holds the last successful value, if any.
    case failed(error: Failure, previous: Success?)
}

public extension Loading {
    /// The loaded value, or the `previous` value from `.loading` / `.failed`.
    /// Returns `nil` when `.idle` or when `previous` is absent.
    var loadedOrPrevious: Success? {
        switch self {
        case .idle:                   nil
        case .loading(let prev):      prev
        case .loaded(let value):      value
        case .failed(_, let prev):    prev
        }
    }
}

extension Loading: Equatable where Success: Equatable, Failure: Equatable {}
extension Loading: Hashable where Success: Hashable, Failure: Hashable & Error {}
