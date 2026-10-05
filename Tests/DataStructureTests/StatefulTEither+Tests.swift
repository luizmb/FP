// SPDX-License-Identifier: Apache-2.0
import DataStructure
import Testing

@Suite struct StatefulEitherTests {
    // MARK: - Stateful<S, Either<L, A>> — State as outer, Either as inner

    @Test func mapRight() {
        let s = Stateful<Int, Either<String, Int>>.pure(.right(5))
        let mapped = s.statefulT.map { $0 * 2 }
        #expect(mapped.rawValue.eval(0) == .right(10))
    }

    @Test func mapLeft() {
        let s = Stateful<Int, Either<String, Int>>.pure(.left("error"))
        let mapped = s.statefulT.map { $0 * 2 }
        #expect(mapped.rawValue.eval(0) == .left("error"))
    }

    @Test func flatMapRight() {
        let s = Stateful<Int, Either<String, Int>> { state in
            let v = state
            state += 1
            return .right(v)
        }
        let result = s.statefulT.flatMap { value in
            StatefulTEither(Stateful<Int, Either<String, String>> { state in
                state += value
                return .right("\(value)")
            })
        }
        let (output, finalState) = result.rawValue.runStateful(5)
        #expect(output == .right("5"))
        #expect(finalState == 11)
    }

    @Test func flatMapLeft() {
        let s = Stateful<Int, Either<String, Int>>.pure(.left("fail"))
        let result = s.statefulT.flatMap { value in
            StatefulTEither(Stateful<Int, Either<String, String>>.pure(.right("\(value)")))
        }
        #expect(result.rawValue.eval(0) == .left("fail"))
    }

    @Test func applyStatefulEitherRight() {
        let sf = Stateful<Int, Either<String, @Sendable (Int) -> String>>.pure(.right { "\($0)" })
        let sa = Stateful<Int, Either<String, Int>>.pure(.right(42))
        let result = StatefulTEither.apply(sf.statefulT, sa.statefulT).rawValue
        #expect(result.eval(0) == .right("42"))
    }

    @Test func applyStatefulEitherLeft() {
        let sf = Stateful<Int, Either<String, @Sendable (Int) -> String>>.pure(.left("err"))
        let sa = Stateful<Int, Either<String, Int>>.pure(.right(42))
        let result = StatefulTEither.apply(sf.statefulT, sa.statefulT).rawValue
        #expect(result.eval(0) == .left("err"))
    }

    @Test func liftA2StatefulEitherRight() {
        let sa = Stateful<Int, Either<String, Int>>.pure(.right(3))
        let sb = Stateful<Int, Either<String, Int>>.pure(.right(4))
        let result = StatefulTEither.liftA2(+)(sa.statefulT, sb.statefulT).rawValue
        #expect(result.eval(0) == .right(7))
    }

    // MARK: - Either<L, Stateful<S, A>> — Either as outer, Stateful as inner

    @Test func eitherTStatefulMapTRight() {
        let e: Either<String, Stateful<Int, Int>> = .right(.get)
        let mapped = e.eitherT.map { $0 * 2 }.rawValue
        #expect(mapped.mapRight { $0.eval(5) } == .right(10))
    }

    @Test func eitherTStatefulMapTLeft() {
        let e: Either<String, Stateful<Int, Int>> = .left("error")
        let mapped: Either<String, Stateful<Int, Int>> = e.eitherT.map { $0 * 2 }.rawValue
        if case let .left(l) = mapped {
            #expect(l == "error")
        } else {
            Issue.record("Expected .left")
        }
    }
}
