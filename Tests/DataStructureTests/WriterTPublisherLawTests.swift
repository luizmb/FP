// SPDX-License-Identifier: Apache-2.0
#if canImport(Combine)
    import Combine
    import CoreFP
    import DataStructure
    import Testing

    // Laws on the `WriterTPublisher` struct API: functor, applicative identity / homomorphism (the inner
    // applicative is Publisher's cartesian `ap`), lifting property and escape hatch.

    @MainActor
    @Suite struct WriterTPublisherLawTests {
        private typealias Stack<A> = WriterTPublisher<[String], Never, A>

        private let inc: @Sendable (Int) -> Int = { $0 + 1 }
        private let dbl: @Sendable (Int) -> Int = { $0 * 2 }
        private let idInt: @Sendable (Int) -> Int = id

        private func stack(_ values: [Int], _ log: [String]) -> Stack<Int> {
            Stack(Writer(values.publisher, log))
        }

        private func observe<A>(_ stack: WriterTPublisher<[String], Never, A>) -> ([A], [String]) {
            var results: [A] = []
            var cancellables = Set<AnyCancellable>()
            stack.rawValue.value.eraseToAnyPublisher()
                .sink(receiveCompletion: { _ in }, receiveValue: { results.append($0) })
                .store(in: &cancellables)
            return (results, stack.rawValue.log)
        }

        @Test func functorLaws() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            let m = stack([1, 2], ["a"])
            #expect(observe(m.map(idInt)) == observe(m))
            let incThenDbl: @Sendable (Int) -> Int = { [inc, dbl] in dbl(inc($0)) }
            #expect(observe(m.map(incThenDbl)) == observe(m.map(inc).map(dbl)))
        }

        @Test func applicativeLaws() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            let m = stack([1, 2], ["a"])
            #expect(observe(Stack.apply(Stack.pure(idInt), m)) == observe(m))
            #expect(observe(Stack.apply(Stack.pure(inc), Stack.pure(3))) == observe(Stack<Int>.pure(4)))
        }

        @Test func applyIsCartesianAp() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            let fns = Stack<@Sendable (Int) -> Int>(Writer([inc, dbl].publisher, ["fns"]))
            #expect(observe(Stack.apply(fns, stack([10, 20], ["xs"]))) == ([11, 21, 20, 40], ["fns", "xs"]))
            #expect(stack([1, 2], ["a"]).seqRight(stack([10, 20], ["b"])).rawValue.log == ["a", "b"])
            #expect(observe(stack([1, 2], ["a"]).seqRight(stack([10, 20], ["b"]))).0 == [10, 20, 10, 20])
            #expect(observe(stack([1, 2], ["a"]).seqLeft(stack([10, 20], ["b"]))).0 == [1, 1, 2, 2])
        }

        @Test func liftingProperty() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            let nested = Writer<[String], AnyPublisher<Int, Never>>([1, 2].publisher.eraseToAnyPublisher(), ["a"])
            #expect(observe(nested.writerT) == ([1, 2], ["a"]))
        }

        @Test func escapeHatch() {
            guard #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) else { return }
            let hatched = stack([1], ["a"]).mapWriterT { Writer($0.value, $0.log + ["hatch"]) }
            #expect(observe(hatched) == ([1], ["a", "hatch"]))
        }
    }
#endif
