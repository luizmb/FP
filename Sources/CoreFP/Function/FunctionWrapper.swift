public protocol FunctionWrapper<Input, Output> {
    associatedtype Input
    associatedtype Output

    init(_ fn: @escaping (Input) -> Output)
    func callAsFunction(_ input: Input) -> Output
}
