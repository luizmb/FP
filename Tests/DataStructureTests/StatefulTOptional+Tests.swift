// SPDX-License-Identifier: Apache-2.0
import DataStructure
import Testing

@Suite struct StatefulTOptionalTests {
    // MARK: - Stateful<S, A?> — State as outer, Optional as inner

    @Test func mapSome() {
        let s = Stateful<Int, Int?>.pure(.some(5))
        let mapped = s.statefulT.map { $0 * 2 }
        #expect(mapped.rawValue.eval(0) == .some(10))
    }

    @Test func mapNone() {
        let s = Stateful<Int, Int?>.pure(nil)
        let mapped = s.statefulT.map { $0 * 2 }
        #expect(mapped.rawValue.eval(0) == nil)
    }

    @Test func flatMapSome() {
        let s = Stateful<Int, Int?> { state in
            let v = state
            state += 1
            return .some(v)
        }
        let result = s.statefulT.flatMap { value in
            StatefulTOptional(Stateful<Int, String?> { state in
                state += value
                return .some("\(value)")
            })
        }
        let (output, finalState) = result.rawValue.runStateful(5)
        #expect(output == .some("5"))
        #expect(finalState == 11) // 5+1=6 from first, 6+5=11 from second
    }

    @Test func flatMapNone() {
        let s = Stateful<Int, Int?>.pure(nil)
        let result = s.statefulT.flatMap { value in
            StatefulTOptional(Stateful<Int, String?>.pure(.some("\(value)")))
        }
        #expect(result.rawValue.eval(0) == nil)
    }

    // MARK: - Optional<Stateful<S, A>> — Optional as outer, Stateful as inner

    @Test func optionalTStatefulMapTSome() {
        let opt: Stateful<Int, Int>? = .some(Stateful<Int, Int>.get)
        let mapped = opt.mapT { $0 * 3 }
        #expect(mapped?.eval(4) == 12)
    }

    @Test func optionalTStatefulMapTNone() {
        let opt: Stateful<Int, Int>? = nil
        let mapped: Stateful<Int, Int>? = opt.mapT { $0 * 3 }
        #expect(mapped == nil)
    }
}
