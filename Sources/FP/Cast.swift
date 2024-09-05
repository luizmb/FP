/// Cast an object to the desired type. The origin type must be
/// a subclass of the destination type, eg APIClientError > Swift.Error
public func cast<T>(_ destinationType: T.Type) -> (_ originObject: T) -> T {
    { $0 as T }
}
