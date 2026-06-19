import DataStructure

// A small identifiable element. `n` is the mutable field the update/optic
// benchmarks bump; `id` keys the lookup.
struct BenchUser: Identifiable, Sendable, Equatable {
    let id: Int
    var n: Int = 0
}

// Sizes swept by every benchmark, so the O(n) → O(1) story is visible as the
// collection grows. The by-id benchmarks target the LAST id (worst case for the
// linear `[Element]` baseline).
let sizes = [100, 1_000, 10_000]

func makeArray(_ count: Int) -> [BenchUser] {
    (0..<count).map { BenchUser(id: $0) }
}

func makeIdentified(_ count: Int) -> IdentifiedArrayOf<BenchUser> {
    IdentifiedArray(makeArray(count))
}
