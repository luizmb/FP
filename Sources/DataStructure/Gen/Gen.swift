// SPDX-License-Identifier: Apache-2.0
import Foundation

/// A composable, seedable generator of random `Value`s.
///
/// `Gen` is the random-generator monad familiar from property-based testing — QuickCheck's
/// `Gen a` (Haskell) and ScalaCheck's `Gen[A]` (Scala). It is defined as a ``Stateful``
/// computation threading a random number generator, so it inherits **all** of `Stateful`'s
/// `Functor`/`Applicative`/`Monad` machinery — and every monad transformer built for `Stateful` —
/// for free:
///
/// ```swift
/// public typealias Gen<Value> = Stateful<AnyRandomNumberGenerator, Value>
/// ```
///
/// Because the RNG is threaded `inout` (never captured), `Gen<Value>` is `Sendable` for any
/// `Value` — the Sendability comes from `Stateful`'s `@Sendable` closure, independent of the RNG.
///
/// ## Composing generators
///
/// Build a generator for any type by composing primitives with `map`/`flatMap`/`zip`:
///
/// ```swift
/// let die: Gen<Int> = .int(in: 1...6)
/// let pair = Gen.zip(die, die).map { $0 + $1 }            // 2...12
///
/// struct User: Sendable { let id: UUID; let name: String; let age: Int }
/// let user = Gen.zip(.uuid,
///                    .string(of: .letter, count: .int(in: 3...8)),
///                    .int(in: 0...120)).map(User.init)
/// ```
///
/// ## Running a generator
///
/// Use ``generate(seed:)``/``samples(seed:count:)`` for **reproducible** output (a fresh
/// ``SplitMix64`` seeded with `seed`), or ``generate()`` for system randomness:
///
/// ```swift
/// let value = die.generate(seed: 42)          // deterministic for a given seed
/// let many  = die.samples(seed: 42, count: 100)
/// ```
///
/// - SeeAlso: ``Stateful``, ``AnyRandomNumberGenerator``, ``SplitMix64``
public typealias Gen<Value> = Stateful<AnyRandomNumberGenerator, Value>

// MARK: - Type-erased Sendable RNG

/// A type-erased, `Sendable` `RandomNumberGenerator`.
///
/// Erasing to a single concrete type lets ``Gen`` be a concrete, freely-composable type rather
/// than being generic over the RNG. The wrapped value is constrained to
/// `RandomNumberGenerator & Sendable`, so the eraser is itself `Sendable`.
public struct AnyRandomNumberGenerator: RandomNumberGenerator, Sendable {
    private var base: any RandomNumberGenerator & Sendable

    /// Erases a concrete `Sendable` random number generator.
    public init(_ base: some RandomNumberGenerator & Sendable) {
        self.base = base
    }

    public mutating func next() -> UInt64 {
        base.next()
    }
}

// MARK: - Seedable PRNG

/// A small, fast, **seedable** pseudo-random number generator implementing the public-domain
/// SplitMix64 algorithm.
///
/// SplitMix64 (Steele, Lea & Flood, *"Fast Splittable Pseudorandom Number Generators,"* OOPSLA
/// 2014) has a single 64-bit state seeded from one `UInt64`, which is exactly what reproducible
/// property-based testing needs: the same seed yields the same sequence on every platform. The
/// algorithm is unpatented and the canonical reference implementation is dedicated to the public
/// domain (CC0); this is an independent Swift implementation of the published algorithm.
public struct SplitMix64: RandomNumberGenerator, Sendable {
    private var state: UInt64

    /// Creates a generator seeded with `seed`.
    public init(seed: UInt64) {
        state = seed
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

// MARK: - Running a Gen

extension Stateful where S == AnyRandomNumberGenerator {
    /// Generates one value from a fresh ``SplitMix64`` seeded with `seed` — reproducible.
    public func generate(seed: UInt64) -> A {
        var rng = AnyRandomNumberGenerator(SplitMix64(seed: seed))
        return self(&rng)
    }

    /// Generates one value from the system random number generator — not reproducible.
    public func generate() -> A {
        var rng = AnyRandomNumberGenerator(SystemRandomNumberGenerator())
        return self(&rng)
    }

    /// Generates `count` values threading a single ``SplitMix64`` seeded with `seed`.
    ///
    /// The whole sequence is reproducible from `seed`, which makes a failing property-test case
    /// replayable: rerun with the same seed to get the same inputs.
    public func samples(seed: UInt64, count: Int) -> [A] {
        var rng = AnyRandomNumberGenerator(SplitMix64(seed: seed))
        // swiftlint:disable:next closure_ignoring_args
        return (0..<max(0, count)).map { _ in self(&rng) }  // side effect — rng is mutated; cannot use const()
    }
}
