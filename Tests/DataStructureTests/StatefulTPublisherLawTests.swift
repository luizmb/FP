// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
    import Combine
    import CoreFP
    import DataStructure
    import Testing

    /// StatefulTPublisher (applicative-only) laws on the struct API: functor identity / composition,
    /// applicative identity / homomorphism, plus the `mapStateT` escape hatch and the `.statefulT` lifting property.
    @MainActor
    @Suite struct StatefulTPublisherLawTests {
        private enum Failure: Error, Equatable { case boom }

        private let initialStates = [0, 3]
        private let identity: @Sendable (Int) -> Int = id
        private let increment: @Sendable (Int) -> Int = { $0 + 1 }
        private let describe: @Sendable (Int) -> String = { "<\($0)>" }

        private func collect<A>(_ publisher: any Publisher<A, Failure>) -> [A] {
            var results: [A] = []
            var cancellables = Set<AnyCancellable>()
            publisher.eraseToAnyPublisher()
                .sink(receiveCompletion: { _ in }, receiveValue: { results.append($0) })
                .store(in: &cancellables)
            return results
        }

        @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
        private func stack(_ values: [Int]) -> StatefulTPublisher<Int, Failure, Int> {
            StatefulTPublisher(Stateful { s in
                s += 1
                return values.publisher.setFailureType(to: Failure.self).eraseToAnyPublisher()
            })
        }

        @available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
        private func expectSame<A: Equatable>(
            _ actual: StatefulTPublisher<Int, Failure, A>,
            _ expected: StatefulTPublisher<Int, Failure, A>,
            sourceLocation: SourceLocation = #_sourceLocation
        ) {
            for initial in initialStates {
                let (actualPublisher, actualState) = actual.rawValue.runStateful(initial)
                let (expectedPublisher, expectedState) = expected.rawValue.runStateful(initial)
                #expect(collect(actualPublisher) == collect(expectedPublisher), sourceLocation: sourceLocation)
                #expect(actualState == expectedState, sourceLocation: sourceLocation)
            }
        }

        @Test func functorIdentity() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            for values in [[1, 2], []] {
                expectSame(stack(values).map(identity), stack(values))
            }
        }

        @Test func functorComposition() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            let increment = increment
            let describe = describe
            for values in [[1, 2], []] {
                expectSame(stack(values).map(increment).map(describe), stack(values).map { describe(increment($0)) })
            }
        }

        @Test func applicativeIdentity() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            typealias Stack<A> = StatefulTPublisher<Int, Failure, A>
            for values in [[1, 2], []] {
                expectSame(Stack<Int>.apply(Stack.pure(identity), stack(values)), stack(values))
            }
        }

        @Test func applicativeHomomorphism() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            typealias Stack<A> = StatefulTPublisher<Int, Failure, A>
            expectSame(Stack<String>.apply(Stack.pure(describe), Stack.pure(4)), Stack<String>.pure(describe(4)))
        }

        @Test func applicativeIsCartesianNotZip() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            typealias Stack<A> = StatefulTPublisher<Int, Failure, A>
            let add: @Sendable (Int, Int) -> Int = { $0 + $1 }
            let (sum, sumState) = Stack<Int>.liftA2(add)(stack([1, 2]), stack([10, 20])).rawValue.runStateful(0)
            let (right, _) = stack([1, 2]).seqRight(stack([10, 20])).rawValue.runStateful(0)
            let (left, _) = stack([1, 2]).seqLeft(stack([10, 20])).rawValue.runStateful(0)
            #expect(collect(sum) == [11, 21, 12, 22])
            #expect(sumState == 2)
            #expect(collect(right) == [10, 20, 10, 20])
            #expect(collect(left) == [1, 1, 2, 2])
        }

        @Test func escapeHatch() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            let firstOnly: StatefulTPublisher<Int, Failure, Int> = stack([1, 2, 3]).mapStateT { stateful in
                stateful.mapStateful { $0.eraseToAnyPublisher().first().eraseToAnyPublisher() }
            }
            let (publisher, state) = firstOnly.rawValue.runStateful(0)
            #expect(collect(publisher) == [1])
            #expect(state == 1)
        }

        @Test func liftingProperty() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            let nested = Stateful<Int, AnyPublisher<Int, Failure>> { s in
                s += 1
                return [1, 2].publisher.setFailureType(to: Failure.self).eraseToAnyPublisher()
            }
            let (publisher, state) = nested.statefulT.rawValue.runStateful(0)
            #expect(collect(publisher) == [1, 2])
            #expect(state == 1)
        }
    }
#endif
