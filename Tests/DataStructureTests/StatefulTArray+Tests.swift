import DataStructure
import Testing
import CoreFP

@Suite struct StatefulTArrayTests {

    // MARK: - Stateful<S, [A]> — State as outer, Array as inner

    @Test func mapT() {
        let s = Stateful<Int, [Int]>.pure([1, 2, 3])
        let mapped = s.mapT { $0 * 2 }
        #expect(mapped.eval(0) == [2, 4, 6])
    }

    @Test func mapTEmpty() {
        let s = Stateful<Int, [Int]>.pure([])
        let mapped = s.mapT { $0 * 2 }
        #expect(mapped.eval(0) == [])
    }

    @Test func flatMapT() {
        let s = Stateful<Int, [Int]> { state in
            let values = [state, state + 1]
            state += 2
            return values
        }
        let result = s.flatMapT { value in
            Stateful<Int, [String]> { state in
                state += value
                return ["\(value)"]
            }
        }
        let (output, finalState) = result.runStateful(0)
        // First: [0, 1], state becomes 2
        // flatMapT: map each through the fn
        // fn(0): state += 0, returns ["0"]
        // fn(1): state += 1, returns ["1"]
        // But flatMapT here uses flatMap (not sequential state threading)
        // mapT sequences: each element builds its own Stateful and they get flatMapped
        #expect(output == ["0", "1"])
        _ = finalState
    }

    // MARK: - [Stateful<S, A>] — Array as outer, Stateful as inner

    @Test func arrayTStatefulMapT() {
        let arr: [Stateful<Int, Int>] = [
            .pure(1),
            .pure(2),
            .pure(3)
        ]
        let mapped = arr.mapT { $0 * 10 }
        let results = mapped.map { $0.eval(0) }
        #expect(results == [10, 20, 30])
    }

    @Test func arrayTStatefulFlatMapT() {
        let arr: [Stateful<Int, Int>] = [.pure(1), .pure(2)]
        let result = arr.flatMapT { value in
            Stateful<Int, String>.pure("\(value)")
        }
        let results = result.map { $0.eval(0) }
        #expect(results == ["1", "2"])
    }
}
