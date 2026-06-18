// SPDX-License-Identifier: Apache-2.0
import CoreFP
import Testing

@Suite struct BoolOperationsTests {
    private struct User { let name: String; let age: Int; let isAdmin: Bool }

    private let alice = User(name: "Alice", age: 30, isAdmin: false)
    private let bob   = User(name: "Bob", age: 16, isAdmin: true)

    // MARK: - equals / notEquals

    @Test func equalsPartial() {
        let isAlice = equals("Alice")
        #expect(isAlice("Alice") == true)
        #expect(isAlice("Bob") == false)
    }

    @Test func notEqualsPartial() {
        let notAlice = notEquals("Alice")
        #expect(notAlice("Bob") == true)
        #expect(notAlice("Alice") == false)
    }

    // MARK: - not (Bool value)

    @Test func notBool() {
        #expect(not(true) == false)
        #expect(not(false) == true)
    }

    @Test func notReturnsHigherOrder() {
        let negate = not()
        #expect(negate(true) == false)
        #expect(negate(false) == true)
    }

    // MARK: - not (predicate lifting)

    @Test func notPredicate() {
        let isAdmin: @Sendable (User) -> Bool = get(\.isAdmin)
        let nonAdmin = not(isAdmin)
        #expect(nonAdmin(alice) == true)
        #expect(nonAdmin(bob) == false)
    }

    @Test func notPredicateComposed() {
        let nameIsAlice = compose(get(\User.name), equals("Alice"))
        let notAlice = not(nameIsAlice)
        #expect(notAlice(alice) == false)
        #expect(notAlice(bob) == true)
    }

    // MARK: - and (predicate combining)

    @Test func andPredicates() {
        let isAdmin: @Sendable (User) -> Bool = get(\.isAdmin)
        let isAdult: @Sendable (User) -> Bool = compose(get(\User.age), flip(>=)(18))
        let adultNonAdmin = and(not(isAdmin), isAdult)
        #expect(adultNonAdmin(alice) == true)
        #expect(adultNonAdmin(bob) == false)
    }

    @Test func andPredicatesFilter() {
        let users = [alice, bob]
        let isAdmin: @Sendable (User) -> Bool = get(\.isAdmin)
        let isAdult: @Sendable (User) -> Bool = compose(get(\User.age), flip(>=)(18))
        let result = users.filter(and(not(isAdmin), isAdult))
        #expect(result.count == 1)
        #expect(result[0].name == "Alice")
    }

    // MARK: - or (predicate combining)

    @Test func orPredicates() {
        let isAdmin: @Sendable (User) -> Bool = get(\.isAdmin)
        let nameIsAlice = compose(get(\User.name), equals("Alice"))
        let aliceOrAdmin = or(nameIsAlice, isAdmin)
        #expect(aliceOrAdmin(alice) == true)   // name matches
        #expect(aliceOrAdmin(bob) == true)   // isAdmin
    }

    @Test func orPredicatesFilter() {
        let users = [alice, bob]
        let nameIsAlice = compose(get(\User.name), equals("Alice"))
        let nameIsBob   = compose(get(\User.name), equals("Bob"))
        let result = users.filter(or(nameIsAlice, nameIsBob))
        #expect(result.count == 2)
    }

    // MARK: - flip-based tacit predicates (mirrors README examples)

    @Test func flipBasedAgeFilter() {
        // flip(>=)(18) is (Int) -> Bool equivalent to { $0 >= 18 }
        let users = [alice, bob]
        let result = users.filter(and(not(get(\.isAdmin)), compose(get(\User.age), flip(>=)(18))))
        #expect(result.map(\.name) == ["Alice"])
    }

    @Test func flipBasedEvenPositives() {
        // mirrors: [0,1,2,-1,4].filter(and(equals(0) <<< flip(%)(2), flip(>)(0)))
        let isEven: @Sendable (Int) -> Bool = compose(flip(%)(2) as @Sendable (Int) -> Int, equals(0))
        let isPositive: @Sendable (Int) -> Bool = flip(>)(0)
        let result = [0, 1, 2, -1, 4].filter(and(isEven, isPositive))
        #expect(result == [2, 4])
    }

    // MARK: - and / or (Bool value — original overloads untouched)

    @Test func andBool() {
        #expect(and(true)(true) == true)
        #expect(and(true)(false) == false)
        #expect(and(false)(true) == false)
    }

    @Test func orBool() {
        #expect(or(false)(false) == false)
        #expect(or(true)(false) == true)
        #expect(or(false)(true) == true)
    }
}
