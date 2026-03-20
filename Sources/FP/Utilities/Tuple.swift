/// Given a function that transforms A into B, it will generate a function that transforms
/// a tuple of As into a tuple of Bs. This is the 2-ary version
/// - Parameter function: (A) - B
/// - Returns: a function that transforms (A, A) into (B, B)
public func mapTuple2<A, B>(
    _ function: @escaping (A) -> B
) -> (A, A) -> (B, B) {
    { input1, input2 in
        (function(input1), function(input2))
    }
}

/// Given a function that transforms A into B, it will generate a function that transforms
/// a tuple of As into a tuple of Bs. This is the 3-ary version
/// - Parameter function: (A) - B
/// - Returns: a function that transforms (A, A, A) into (B, B, B)
public func mapTuple3<A, B>(
    _ function: @escaping (A) -> B
) -> (A, A, A) -> (B, B, B) {
    { input1, input2, input3 in
        (function(input1), function(input2), function(input3))
    }
}
