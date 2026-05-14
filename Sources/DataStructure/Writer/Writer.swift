import CoreFP
import Foundation

/// A computation that produces a value alongside an accumulated log.
///
/// `Writer<W, A>` is the classic Writer monad. It pairs a computed value `A` with a log `W`
/// that must be a ``Monoid``. When two `Writer` computations are sequenced via `flatMap`,
/// their logs are combined using ``Semigroup/combine(_:_:)``.
///
/// ## When to use Writer
///
/// Use `Writer` when you want to thread an accumulated log, audit trail, or diagnostic
/// alongside a computation — without explicitly passing it through every function.
///
/// Common choices for `W`:
/// - `[String]` (array of log messages)
/// - `String` (concatenated log)
/// - Any custom ``Monoid``
///
/// ## Creating a Writer
///
/// ```swift
/// // A computation that logs its steps:
/// let step1: Writer<[String], Int> = Writer(42, ["fetched value"])
///
/// // Using pure — no log entry:
/// let pure: Writer<[String], Int> = Writer.pure(99)    // log = []
///
/// // Using tell — log-only, no value:
/// let logged: Writer<[String], Void> = Writer.tell(["started computation"])
/// ```
///
/// ## Sequencing with flatMap
///
/// ```swift
/// let result: Writer<[String], String> =
///     Writer(42, ["step 1"])
///         .flatMap { n in Writer(String(n), ["step 2"]) }
/// // result.value == "42"
/// // result.log   == ["step 1", "step 2"]
/// ```
///
/// ## Extracting values
///
/// ```swift
/// let (value, log) = writer.runWriter()   // both value and log
/// let value = writer.evalWriter()         // just the value
/// let log = writer.execWriter()           // just the log
/// ```
///
/// ## Comonad
///
/// `Writer` is a `Comonad`:
/// - ``Writer/extract``: returns the current value (discarding the log).
/// - ``Writer/extend(_:)``: applies a function to the whole writer context, keeping the original log.
/// - ``Writer/duplicate``: wraps the writer inside another with the same log.
///
/// ## Operator forms
///
/// All monad/functor operations have operator forms in `DataStructureOperators`:
///
/// ```swift
/// writer <&> transform     // map
/// writer >>- continuation  // flatMap
/// writer ->> f             // extend (comonad)
/// ```
///
/// - SeeAlso: ``Reader``, ``Stateful``, ``Monoid``
public struct Writer<W: Monoid, A> {
    /// The computed value of this writer step.
    public let value: A
    /// The accumulated log up to this point.
    public let log: W

    public init(_ value: A, _ log: W) {
        self.value = value
        self.log = log
    }

    /// Returns a tuple `(value, log)`.
    public func runWriter() -> (A, W) { (value, log) }
    /// Returns only the computed value, discarding the log.
    public func evalWriter() -> A { value }
    /// Returns only the accumulated log, discarding the value.
    public func execWriter() -> W { log }
}

extension Writer: Equatable where W: Equatable, A: Equatable {}
extension Writer: Hashable where W: Hashable, A: Hashable {}
extension Writer: Sendable where W: Sendable, A: Sendable {}
