import CoreFP

// OptionalTArray: outer = Optional, inner = Array
// Type: [A]? = Optional<[A]>

// (<£^>) :: (a -> b) -> [a]? -> [b]?
public func <£^> <A, B>(_ fn: @escaping (A) -> B, _ opt: [A]?) -> [B]? {
    opt.mapT(fn)
}

// (£>) :: [a]? -> b -> [b]?
public func £> <A, B>(_ opt: [A]?, _ value: B) -> [B]? {
    opt.mapT(CoreFP.const(value))
}

// (<£) :: b -> [a]? -> [b]?
public func <£ <A, B>(_ value: B, _ opt: [A]?) -> [B]? {
    opt £> value
}

// (<&^>) :: [a]? -> (a -> b) -> [b]?
public func <&^> <A, B>(_ opt: [A]?, _ fn: @escaping (A) -> B) -> [B]? {
    opt.mapT(fn)
}
