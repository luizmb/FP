public func get<Root, Value>(_ keyPath: KeyPath<Root, Value>) -> (Root) -> Value {
    { a in
        a[keyPath: keyPath]
    }
}

/// Functional setter (lens). Given a way to read/write access a property of type `Part`, in an
/// element of type `Whole` (using `WritableKeyPath<Whole, Part>`), and a functional that
/// transforms the current value into the new value, either by modifying it (`{ $0 + 1 }`} or
/// completely replacing it with a new constant value (`const(5)`), it gives back a function
/// `(Whole) -> Whole`, where you can provide any element that it will apply the transformation.
///
/// This is useful in many scenarios where you want to define the transformation of an element,
/// but you don't have the element yet, either because it's a stream in a Publisher, or you are
/// iterating over a collection, or you are using a composition.
///
/// The ability to either modify or replace the current value is very powerful, because you can
/// do things like uppercasing all surnames in a collection of people, or appending a String to
/// the end of all strings in an array, or even ignoring the current value and replacing it
/// completely for all elements in that array.
///
/// Two examples below, using array, but the same applies for Publisher, Result, Optional, etc.
///
/// ```swift
/// struct Person {
///     var name: String
///     var age: Int
/// }
///
/// let people = [
///     Person(name: "John", age: 42),
///     Person(name: "Paul", age: 42),
///     Person(name: "George", age: 42),
///     Person(name: "Ringo", age: 42)
/// ]
/// // Update all to 43 years
/// let updated = people.map(set(\.age, const(43)))
/// // is equivalent to people.map { $0.age = 43 }
///
/// // Increment 2 years for each person
/// let updated2 = people.map(set(\.age, 2 |> curry(+)))
/// // is equivalent to people.map { $0.age += 2 }
/// ```
///
/// The keypath must be Writable, so for structs please resolve to a `var` property. Class is
/// already writable.
///
public func set<Whole, Part>(
    _ keyPath: WritableKeyPath<Whole, Part>,
    _ transform: @escaping (Part) -> Part
) -> (Whole) -> Whole {
    set(
        get: { $0[keyPath: keyPath] },
        set: { whole, newPart in
            var mutableWhole = whole
            mutableWhole[keyPath: keyPath] = newPart
            return mutableWhole
        },
        transform
    )
}

private func set<Whole, Part>(
    get: @escaping (Whole) -> Part,
    set: @escaping (Whole, Part) -> Whole,
    _ transform: @escaping (Part) -> Part
) -> (Whole) -> Whole {
    { whole in
        let currentPart = get(whole)
        let newPart = transform(currentPart)
        return set(whole, newPart)
    }
}
