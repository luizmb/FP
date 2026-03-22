import DataStructure
import Testing
import Core

@Suite struct StatefulTOptionalTests {

    // MARK: - Stateful<S, A?> — State as outer, Optional as inner

    @Test func mapTSome() {
        let s = Stateful<Int, Int?>.pure(.some(5))
        let mapped = s.mapT { $0 * 2 }
        #expect(mapped.eval(0) == .some(10))
    }

    @Test func mapTNone() {
        let s = Stateful<Int, Int?>.pure(nil)
        let mapped = s.mapT { $0 * 2 }
        #expect(mapped.eval(0) == nil)
    }

    @Test func flatMapTSome() {
        let s = Stateful<Int, Int?> { state in
            let v = state
            state += 1
            return .some(v)
        }
        let result = s.flatMapT { value in
            Stateful<Int, String?> { state in
                state += value
                return .some("\(value)")
            }
        }
        let (output, finalState) = result.runStateful(5)
        #expect(output == .some("5"))
        #expect(finalState == 11) // 5+1=6 from first, 6+5=11 from second
    }

    @Test func flatMapTNone() {
        let s = Stateful<Int, Int?>.pure(nil)
        let result = s.flatMapT { value in
            Stateful<Int, String?>.pure(.some("\(value)"))
        }
        #expect(result.eval(0) == nil)
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

    @Test func optionalTStatefulFlatMapTSome() {
        let opt: Stateful<Int, Int>? = .some(Stateful<Int, Int>.get)
        let result = opt.flatMapT { value in
            Stateful<Int, String> { state in
                state += value
                return "\(value)"
            }
        }
        let (output, finalState) = result!.runStateful(3)
        #expect(output == "3")
        #expect(finalState == 6)
    }

    @Test func optionalTStatefulFlatMapTNone() {
        let opt: Stateful<Int, Int>? = nil
        let result = opt.flatMapT { value in
            Stateful<Int, String>.pure("\(value)")
        }
        #expect(result == nil)
    }
}
