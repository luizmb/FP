/// Given an input, applies it into multiple functions that takes that same input type
/// Examples:
/// - If you want the lowest and greatest elements of a `[Int]`:
/// ```swift
/// let fn: ([Int]) -> (Int?, Int?) = fanout({ $0.min() }, { $0.max() })
/// let (min, max) = fn([9, 3, 5, 1, 16, 2])
/// ```
/// - If you want a tuple with only the name and age of a Person:
/// ```swift
/// let fn = fanout(^\Person.name, ^\Person.age)
/// fn(.fixture())
/// ```
/// - If you want to compare Equality of only name and age of a Person:
/// ```swift
/// let fn = fanout(^\Person.name, ^\Person.age)
/// let haveEqualNamesAndAges = (lhs |> b, rhs |> b) |> (==)
/// ```
/// - Parameter functions: one or many functions that transform the same type of input
/// - Returns: a unified function that applies all given functions and returns a tuple
///            with all the results
public func fanout<Input, each Output>(
    _ functions: repeat (@escaping (Input) -> each Output)
) -> (Input) -> (repeat each Output) {
    { input in
        (repeat (each functions)(input))
    }
}
