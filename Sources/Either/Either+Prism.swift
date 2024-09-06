public extension Either {
    var left: T? {
        switch self {
        case let .left(value): return value
        default: return nil
        }
    }

    var right: U? {
        switch self {
        case let .right(value): return value
        default: return nil
        }
    }

    var isLeft: Bool {
        switch self {
        case .left: true
        case .right: false
        }
    }

    var isRight: Bool {
        switch self {
        case .left: false
        case .right: true
        }
    }
}
