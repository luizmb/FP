// SPDX-License-Identifier: Apache-2.0
import DataStructure
import Testing

@Suite struct EitherTStatefulApplicativeTests {
    // MARK: - Either<L, Stateful<S, A>> — Either as outer, Stateful as inner

    @Test func applyBothRight() {
        let eithF: Either<String, Stateful<Int, @Sendable (Int) -> String>> = .right(.pure { "\($0)" })
        let eithA: Either<String, Stateful<Int, Int>> = .right(.get)
        let result = EitherTStateful.apply(eithF.eitherT, eithA.eitherT).rawValue
        #expect(result.mapRight { $0.eval(5) } == .right("5"))
    }

    @Test func applyLeftFn() {
        let eithF: Either<String, Stateful<Int, @Sendable (Int) -> String>> = .left("err")
        let eithA: Either<String, Stateful<Int, Int>> = .right(.pure(5))
        let result = EitherTStateful.apply(eithF.eitherT, eithA.eitherT).rawValue
        if case let .left(l) = result { #expect(l == "err") } else { Issue.record("Expected .left") }
    }

    @Test func applyLeftVal() {
        let eithF: Either<String, Stateful<Int, @Sendable (Int) -> String>> = .right(.pure { "\($0)" })
        let eithA: Either<String, Stateful<Int, Int>> = .left("err")
        let result = EitherTStateful.apply(eithF.eitherT, eithA.eitherT).rawValue
        if case let .left(l) = result { #expect(l == "err") } else { Issue.record("Expected .left") }
    }

    @Test func liftA2BothRight() {
        let ea: Either<String, Stateful<Int, Int>> = .right(.pure(3))
        let eb: Either<String, Stateful<Int, Int>> = .right(.pure(4))
        let result = EitherTStateful.liftA2(+)(ea.eitherT, eb.eitherT).rawValue
        #expect(result.mapRight { $0.eval(0) } == .right(7))
    }

    @Test func seqRightBothRight() {
        let lhs: Either<String, Stateful<Int, Int>> = .right(.pure(1))
        let rhs: Either<String, Stateful<Int, String>> = .right(.pure("hello"))
        let result = lhs.eitherT.seqRight(rhs.eitherT).rawValue
        #expect(result.mapRight { $0.eval(0) } == .right("hello"))
    }

    @Test func seqRightLeft() {
        let lhs: Either<String, Stateful<Int, Int>> = .left("fail")
        let rhs: Either<String, Stateful<Int, String>> = .right(.pure("hello"))
        let result = lhs.eitherT.seqRight(rhs.eitherT).rawValue
        if case let .left(l) = result { #expect(l == "fail") } else { Issue.record("Expected .left") }
    }

    @Test func seqLeftBothRight() {
        let lhs: Either<String, Stateful<Int, Int>> = .right(.pure(99))
        let rhs: Either<String, Stateful<Int, String>> = .right(.pure("ignored"))
        let result = lhs.eitherT.seqLeft(rhs.eitherT).rawValue
        #expect(result.mapRight { $0.eval(0) } == .right(99))
    }

    @Test func seqLeftRightSide() {
        let lhs: Either<String, Stateful<Int, Int>> = .right(.pure(99))
        let rhs: Either<String, Stateful<Int, String>> = .left("fail")
        let result = lhs.eitherT.seqLeft(rhs.eitherT).rawValue
        if case let .left(l) = result { #expect(l == "fail") } else { Issue.record("Expected .left") }
    }
}
