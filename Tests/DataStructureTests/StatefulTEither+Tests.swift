// SPDX-License-Identifier: Apache-2.0
import DataStructure
import Testing

@Suite struct StatefulEitherTests {
    // MARK: - Stateful<S, Either<L, A>> — State as outer, Either as inner

    @Test func mapTRight() {
        let s = Stateful<Int, Either<String, Int>>.pure(.right(5))
        let mapped = s.mapT { $0 * 2 }
        #expect(mapped.eval(0) == .right(10))
    }

    @Test func mapTLeft() {
        let s = Stateful<Int, Either<String, Int>>.pure(.left("error"))
        let mapped = s.mapT { $0 * 2 }
        #expect(mapped.eval(0) == .left("error"))
    }

    @Test func flatMapTRight() {
        let s = Stateful<Int, Either<String, Int>> { state in
            let v = state
            state += 1
            return .right(v)
        }
        let result = s.flatMapT { value in
            Stateful<Int, Either<String, String>> { state in
                state += value
                return .right("\(value)")
            }
        }
        let (output, finalState) = result.runStateful(5)
        #expect(output == .right("5"))
        #expect(finalState == 11)
    }

    @Test func flatMapTLeft() {
        let s = Stateful<Int, Either<String, Int>>.pure(.left("fail"))
        let result = s.flatMapT { value in
            Stateful<Int, Either<String, String>>.pure(.right("\(value)"))
        }
        #expect(result.eval(0) == .left("fail"))
    }

    @Test func applyStatefulEitherRight() {
        let sf = Stateful<Int, Either<String, @Sendable (Int) -> String>>.pure(.right { "\($0)" })
        let sa = Stateful<Int, Either<String, Int>>.pure(.right(42))
        let result = applyStatefulEither(sf, sa)
        #expect(result.eval(0) == .right("42"))
    }

    @Test func applyStatefulEitherLeft() {
        let sf = Stateful<Int, Either<String, @Sendable (Int) -> String>>.pure(.left("err"))
        let sa = Stateful<Int, Either<String, Int>>.pure(.right(42))
        let result = applyStatefulEither(sf, sa)
        #expect(result.eval(0) == .left("err"))
    }

    @Test func liftA2StatefulEitherRight() {
        let sa = Stateful<Int, Either<String, Int>>.pure(.right(3))
        let sb = Stateful<Int, Either<String, Int>>.pure(.right(4))
        let result = liftA2StatefulEither(+)(sa, sb)
        #expect(result.eval(0) == .right(7))
    }

    // MARK: - Either<L, Stateful<S, A>> — Either as outer, Stateful as inner

    @Test func eitherTStatefulMapTRight() {
        let e: Either<String, Stateful<Int, Int>> = .right(.get)
        let mapped = e.mapT { $0 * 2 }
        #expect(mapped.mapRight { $0.eval(5) } == .right(10))
    }

    @Test func eitherTStatefulMapTLeft() {
        let e: Either<String, Stateful<Int, Int>> = .left("error")
        let mapped: Either<String, Stateful<Int, Int>> = e.mapT { $0 * 2 }
        if case .left(let l) = mapped {
            #expect(l == "error")
        } else {
            Issue.record("Expected .left")
        }
    }

    @Test func eitherTStatefulFlatMapTRight() {
        let e: Either<String, Stateful<Int, Int>> = .right(.get)
        let result = e.flatMapT { value in
            Stateful<Int, String>.pure("\(value)")
        }
        #expect(result.mapRight { $0.eval(7) } == .right("7"))
    }

    @Test func eitherTStatefulFlatMapTLeft() {
        let e: Either<String, Stateful<Int, Int>> = .left("fail")
        let result: Either<String, Stateful<Int, String>> = e.flatMapT { value in
            Stateful<Int, String>.pure("\(value)")
        }
        if case .left(let l) = result {
            #expect(l == "fail")
        } else {
            Issue.record("Expected .left")
        }
    }
}
