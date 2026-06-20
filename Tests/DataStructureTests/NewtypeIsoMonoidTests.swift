// SPDX-License-Identifier: Apache-2.0
import CoreFP
import DataStructure
import Testing

private enum UserTag {}
private typealias UserScore = Newtype<UserTag, Int>

@Suite("Newtype — iso & monoid views")
struct NewtypeIsoMonoidTests {
    @Test func isoUnwrapsAndWraps() {
        #expect(UserScore.iso.get(UserScore(42)) == 42)
        #expect(UserScore.iso.reverseGet(7).rawValue == 7)
    }

    @Test func sumView() {
        let scores = [UserScore(2), UserScore(3), UserScore(4)]
        #expect(mconcat(scores.map(\.sum)).rawValue == 9)
    }

    @Test func productView() {
        let scores = [UserScore(2), UserScore(3), UserScore(4)]
        #expect(mconcat(scores.map(\.product)).rawValue == 24)
    }
}
