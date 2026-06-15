import DataStructure
import Testing

// Minimal property-based law harness over `Gen`, mirroring the generator-driven approach used for
// the algebraic laws. One seeded `SplitMix64` is threaded through every generator and the whole
// run, so a failure replays exactly from its `seed`.

let opticLawSeed: UInt64 = 0xC0FFEE_1234

private func check(
    _ count: Int,
    seed: UInt64,
    _ sourceLocation: SourceLocation,
    _ draw: (inout AnyRandomNumberGenerator) -> Bool
) {
    var rng = AnyRandomNumberGenerator(SplitMix64(seed: seed))
    for index in 0..<count where !draw(&rng) {
        Issue.record("law violated at sample \(index) of \(count) (seed: \(seed))", sourceLocation: sourceLocation)
        return
    }
}

func forAll<A>(
    _ ga: Gen<A>,
    count: Int = 300,
    seed: UInt64 = opticLawSeed,
    sourceLocation: SourceLocation = #_sourceLocation,
    _ property: (A) -> Bool
) {
    check(count, seed: seed, sourceLocation) { property(ga(&$0)) }
}

func forAll<A, B>(
    _ ga: Gen<A>,
    _ gb: Gen<B>,
    count: Int = 300,
    seed: UInt64 = opticLawSeed,
    sourceLocation: SourceLocation = #_sourceLocation,
    _ property: (A, B) -> Bool
) {
    check(count, seed: seed, sourceLocation) { property(ga(&$0), gb(&$0)) }
}

func forAll<A, B, C>(
    _ ga: Gen<A>,
    _ gb: Gen<B>,
    _ gc: Gen<C>,
    count: Int = 300,
    seed: UInt64 = opticLawSeed,
    sourceLocation: SourceLocation = #_sourceLocation,
    _ property: (A, B, C) -> Bool
) {
    check(count, seed: seed, sourceLocation) { property(ga(&$0), gb(&$0), gc(&$0)) }
}
