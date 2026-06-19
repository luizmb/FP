import Benchmark
import CoreFP
import DataStructure

// Benchmarks for IdentifiedArray. Each by-id operation is measured against the
// plain `[Element]` baseline that the library used before IdentifiedArray
// existed (`first(where:)` / `firstIndex(where:)`) — so the chart tells the
// O(n) → O(1) story directly, across the sizes in `Fixtures.sizes`.

// A fresh configuration per benchmark — `Benchmark.Configuration` is not Sendable,
// so it cannot be a shared global.
func config() -> Benchmark.Configuration {
    Benchmark.Configuration(metrics: [.wallClock, .throughput, .mallocCountTotal])
}

let benchmarks: @Sendable () -> Void = {
    lookupBenchmarks()
    updateInPlaceBenchmarks()
    deepOpticBenchmarks()
    iterateBenchmarks()
    buildBenchmarks()
    middleInsertBenchmarks()
}

// MARK: - Lookup by id (the hot read path)

func lookupBenchmarks() {
    for size in sizes {
        let target = size - 1
        let identified = makeIdentified(size)
        Benchmark("Lookup by id — IdentifiedArray (\(size))", configuration: config()) { benchmark in
            for _ in benchmark.scaledIterations {
                blackHole(identified[id: target]?.n)
            }
        }

        let array = makeArray(size)
        Benchmark("Lookup by id — [Element] first(where:) baseline (\(size))", configuration: config()) { benchmark in
            for _ in benchmark.scaledIterations {
                blackHole(array.first { $0.id == target }?.n)
            }
        }
    }
}

// MARK: - Update in place by id

func updateInPlaceBenchmarks() {
    for size in sizes {
        let target = size - 1
        Benchmark("Update by id — IdentifiedArray (\(size))", configuration: config()) { benchmark in
            var identified = makeIdentified(size)
            benchmark.startMeasurement() // exclude construction; measure only the in-place updates
            for _ in benchmark.scaledIterations {
                identified[id: target] = BenchUser(id: target, n: 1)
                blackHole(identified[id: target]?.n)
            }
        }

        Benchmark("Update by id — [Element] firstIndex baseline (\(size))", configuration: config()) { benchmark in
            var array = makeArray(size)
            benchmark.startMeasurement()
            for _ in benchmark.scaledIterations {
                if let i = array.firstIndex(where: { $0.id == target }) { array[i].n = 1 }
                blackHole(array[target].n)
            }
        }
    }
}

// MARK: - Deep, zero-copy mutation through the by-id optic

func deepOpticBenchmarks() {
    for size in sizes {
        let target = size - 1
        // ix(id:).lift(EndoMut) is the O(1) focus + zero-copy in-place mutation path.
        let mutate = IdentifiedArrayOf<BenchUser>.ix(id: target).lift(EndoMut { $0.n += 1 })
        Benchmark("Optic mutate by id — IdentifiedArray ix(id:).lift (\(size))", configuration: config()) { benchmark in
            var identified = makeIdentified(size)
            benchmark.startMeasurement() // exclude construction; measure only the optic mutation
            for _ in benchmark.scaledIterations {
                mutate.runEndoMut(&identified)
                blackHole(identified[id: target]?.n)
            }
        }

        Benchmark("Optic mutate by id — [Element] firstIndex baseline (\(size))", configuration: config()) { benchmark in
            var array = makeArray(size)
            benchmark.startMeasurement()
            for _ in benchmark.scaledIterations {
                if let i = array.firstIndex(where: { $0.id == target }) { array[i].n += 1 }
                blackHole(array[target].n)
            }
        }
    }
}

// MARK: - Ordered iteration (must stay competitive with a plain array)

func iterateBenchmarks() {
    for size in sizes {
        let identified = makeIdentified(size)
        Benchmark("Iterate sum — IdentifiedArray (\(size))", configuration: config()) { benchmark in
            for _ in benchmark.scaledIterations {
                var sum = 0
                for user in identified { sum &+= user.id }
                blackHole(sum)
            }
        }

        let array = makeArray(size)
        Benchmark("Iterate sum — [Element] baseline (\(size))", configuration: config()) { benchmark in
            for _ in benchmark.scaledIterations {
                var sum = 0
                for user in array { sum &+= user.id }
                blackHole(sum)
            }
        }
    }
}

// MARK: - Insert at the exact middle (positional shift + tail reindex)
//
// A pure repeated insert would grow the collection without bound, so each step
// inserts at the middle and then removes the just-inserted element from the
// middle — a size-stable pair. Both IA and the array pay insert(mid)+remove(mid);
// IA additionally reindexes the shifted tail, which is what this isolates.

func middleInsertBenchmarks() {
    for size in sizes {
        let mid = size / 2
        let freshID = size // unique: existing ids are 0..<size

        Benchmark("Insert+remove at middle — IdentifiedArray (\(size))", configuration: config()) { benchmark in
            var identified = makeIdentified(size)
            benchmark.startMeasurement()
            for _ in benchmark.scaledIterations {
                identified.insert(BenchUser(id: freshID, n: 0), at: mid)
                identified.remove(at: mid)
                blackHole(identified.count)
            }
        }

        Benchmark("Insert+remove at middle — [Element] baseline (\(size))", configuration: config()) { benchmark in
            var array = makeArray(size)
            benchmark.startMeasurement()
            for _ in benchmark.scaledIterations {
                array.insert(BenchUser(id: freshID, n: 0), at: mid)
                array.remove(at: mid)
                blackHole(array.count)
            }
        }
    }
}

// MARK: - Build by appending (amortised append + index maintenance)

func buildBenchmarks() {
    for size in sizes {
        Benchmark("Build by append — IdentifiedArray (\(size))", configuration: config()) { benchmark in
            for _ in benchmark.scaledIterations {
                var identified = IdentifiedArray<Int, BenchUser>(id: { $0.id })
                for i in 0..<size { identified.append(BenchUser(id: i)) }
                blackHole(identified.count)
            }
        }

        Benchmark("Build by append — [Element] baseline (\(size))", configuration: config()) { benchmark in
            for _ in benchmark.scaledIterations {
                var array: [BenchUser] = []
                for i in 0..<size { array.append(BenchUser(id: i)) }
                blackHole(array.count)
            }
        }
    }
}
