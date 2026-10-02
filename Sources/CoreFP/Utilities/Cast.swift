// SPDX-License-Identifier: Apache-2.0
/// Cast an object to the desired type. The origin type must be
/// a subclass of the destination type, eg APIClientError > Swift.Error
public func cast<T>(_: T.Type) -> (_ originObject: T) -> T {
    { $0 as T }
}

/// Cast an object to the desired type if possible. Otherwise returns nil.
///
/// ```swift
/// let ints = [1, "two", 3] as [Any]
/// ints.compactMap(castOptionally(Int.self))   // [1, 3]
/// ```
public func castOptionally<From, T>(_: T.Type) -> (_ originObject: From) -> T? {
    { $0 as? T }
}
