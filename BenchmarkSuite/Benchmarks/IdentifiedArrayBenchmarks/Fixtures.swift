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

// Plain `[ID: Element]` — the O(1)-but-orderless contender. It wins on raw by-id
// throughput precisely because it carries no order; the gap to IdentifiedArray is
// the price of keeping order.
func makeDictionary(_ count: Int) -> [Int: BenchUser] {
    var dictionary = [Int: BenchUser](minimumCapacity: count)
    for i in 0..<count {
        dictionary[i] = BenchUser(id: i)
    }
    return dictionary
}
