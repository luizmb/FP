import CoreFP
import Foundation

public struct Stateful<S, A> {
    public let run: (inout S) -> A

    public init(_ fn: @escaping (inout S) -> A) {
        run = fn
    }

    @discardableResult
    public func callAsFunction(_ state: inout S) -> A { run(&state) }

    public func eval(_ initial: S) -> A {
        var s = initial
        return run(&s)
    }

    public func exec(_ initial: S) -> S {
        var s = initial
        _ = run(&s)
        return s
    }

    public func runStateful(_ initial: S) -> (A, S) {
        var s = initial
        let a = run(&s)
        return (a, s)
    }
}
