import Foundation
import Core

public struct Reader<Environment, Output>: FunctionWrapper {
    public let runReader: (Environment) -> Output

    public init(_ fn: @escaping (Environment) -> Output) {
        self.runReader = fn
    }

    public func callAsFunction(_ value: Environment) -> Output {
        runReader(value)
    }
}
