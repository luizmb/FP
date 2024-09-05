import FP

public extension KeyPath {
    @inline(__always)
    static prefix func ^ (keyPath: KeyPath) -> (Root) -> Value {
        get(keyPath)
    }
}

public extension WritableKeyPath {
    static prefix func ^ (keyPath: WritableKeyPath) -> (@escaping (Value) -> Value)
    -> ((Root) -> Root) {
        { transform in
            set(keyPath, transform)
        }
    }
}
