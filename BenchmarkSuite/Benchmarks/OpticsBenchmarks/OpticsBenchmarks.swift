import Benchmark
import CoreFP

// Optic read/write paths through composed chains, measured in time, instructions, mallocs and
// retains/releases. Compare a change with `swift package benchmark baseline update <name>` before
// and after, then `baseline compare`. The `fold —` benchmarks use `Traversal.reduce` / `count`;
// their `getAll +` twins do the same work through an array.
//
// The org fixture is 100 departments × 10 teams × 10 members = 10_000 leaf foci.

struct Member: Sendable { var name: String; var age: Int }
struct Team: Sendable { var members: [Member]; var lead: Member? }
struct Department: Sendable { var teams: [Team] }
struct Org: Sendable { var departments: [Department] }

enum Session: Sendable { case guest; case signedIn(Org) }
struct App: Sendable { var session: Session; var draft: Member? }

func makeOrg(departments: Int = 100, teams: Int = 10, members: Int = 10) -> Org {
    Org(departments: (0 ..< departments).map { d in
        Department(teams: (0 ..< teams).map { t in
            Team(
                members: (0 ..< members).map { m in Member(name: "member-\(d)-\(t)-\(m)-with-a-long-name", age: m) },
                lead: t.isMultiple(of: 2) ? Member(name: "lead-\(d)-\(t)-with-a-long-name", age: 40) : nil
            )
        })
    })
}

let signedInPrism: Prism<Session, Org> = prism(
    preview: { if case let .signedIn(org) = $0 { org } else { nil } },
    review: Session.signedIn
)

// Traversal chains of increasing depth.
let names1: Traversal<[Member], String> = [Member].each.compose(lens(\Member.name))
let names2: Traversal<[Team], String> = [Team].each.compose(lens(\Team.members)).compose([Member].each).compose(lens(\Member.name))
let names3: Traversal<Org, String> = lens(\Org.departments)
    .compose([Department].each)
    .compose(lens(\Department.teams))
    .compose([Team].each)
    .compose(lens(\Team.members))
    .compose([Member].each)
    .compose(lens(\Member.name))
let ages3: Traversal<Org, Int> = lens(\Org.departments)
    .compose([Department].each)
    .compose(lens(\Department.teams))
    .compose([Team].each)
    .compose(lens(\Team.members))
    .compose([Member].each)
    .compose(lens(\Member.age))
// Traversal → Prism-like (AffineTraversal) link: optional team leads.
let leadAges: Traversal<Org, Int> = lens(\Org.departments)
    .compose([Department].each)
    .compose(lens(\Department.teams))
    .compose([Team].each)
    .compose(affineTraversal(\Team.lead))
    .compose(lens(\Member.age))
// Indexed.
let indexedNames: IndexedTraversal<[Member], Int, String> = [Member].eachIndexed.compose(lens(\Member.name))
// No traversal at all: lens → prism → lens → affine → lens.
let firstTeamLeadAge: AffineTraversal<App, Int> = lens(\App.session)
    .compose(signedInPrism)
    .compose(lens(\Org.departments))
    .compose([Department].ix(0))
    .compose(lens(\Department.teams))
    .compose([Team].ix(0))
    .compose(affineTraversal(\Team.lead))
    .compose(lens(\Member.age))

func config() -> Benchmark.Configuration {
    Benchmark.Configuration(
        metrics: [.wallClock, .instructions, .mallocCountTotal, .retainCount, .releaseCount],
        // Raw counts, so a small change in instructions or allocations isn't hidden by K/M rounding.
        units: [.instructions: .count, .mallocCountTotal: .count, .retainCount: .count, .releaseCount: .count],
        maxDuration: .seconds(2)
    )
}

let benchmarks: @Sendable () -> Void = {
    let ints = Array(0 ..< 10_000)
    Benchmark("getAll — [Int].each, 1 layer (10k)", configuration: config()) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole([Int].each.getAll(ints))
        }
    }
    let intsEach = [Int].each
    Benchmark("getAll — [Int].each built once, 1 layer (10k)", configuration: config()) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(intsEach.getAll(ints))
        }
    }
    Benchmark("build — [Int].each", configuration: config()) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole([Int].each)
        }
    }

    struct Box: Sendable { var values: [Int] }
    let box = Box(values: ints)
    let boxValues: Traversal<Box, Int> = lens(\Box.values).compose([Int].each)
    Benchmark("getAll — lens >>> [Int].each, leaf is a whole array (10k)", configuration: config()) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(boxValues.getAll(box))
        }
    }

    let grid = (0 ..< 100).map { row in Array(row * 100 ..< row * 100 + 100) }
    let cells: Traversal<[[Int]], Int> = [[Int]].each.compose([Int].each)
    Benchmark("getAll — each >>> each, 100 × 100 Int grid", configuration: config()) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(cells.getAll(grid))
        }
    }

    let members = makeOrg().departments.flatMap { $0.teams.flatMap(\.members) }
    Benchmark("getAll — each >>> lens, 2 links (10k)", configuration: config()) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(names1.getAll(members))
        }
    }

    let teams = makeOrg().departments.flatMap(\.teams)
    Benchmark("getAll — each >>> lens >>> each >>> lens, 4 links (10k)", configuration: config()) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(names2.getAll(teams))
        }
    }

    let org = makeOrg()
    Benchmark("getAll — 7-link chain, 3 nested each (10k)", configuration: config()) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(names3.getAll(org))
        }
    }
    Benchmark("getAll + reduce — sum of ages, 7-link chain (10k)", configuration: config()) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(ages3.getAll(org).reduce(0, +))
        }
    }
    Benchmark("getAll + count — 7-link chain (10k)", configuration: config()) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(names3.getAll(org).count)
        }
    }
    Benchmark("fold — reduce(into:) sum of ages, 7-link chain (10k)", configuration: config()) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(ages3.reduce(org, into: 0) { $0 &+= $1 })
        }
    }
    Benchmark("fold — count, 7-link chain (10k)", configuration: config()) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(names3.count(org))
        }
    }
    Benchmark("getAll — chain with affine link, optional leads (500 of 1k)", configuration: config()) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(leadAges.getAll(org))
        }
    }
    Benchmark("getAll — eachIndexed >>> lens (10k)", configuration: config()) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(indexedNames.getAll(members))
        }
    }

    Benchmark("modifyMut — 7-link chain, in place (10k)", configuration: config()) { benchmark in
        var whole = makeOrg()
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            ages3.modifyMut(&whole) { $0 &+= 1 }
        }
        benchmark.stopMeasurement()
        blackHole(whole)
    }
    Benchmark("over — 7-link chain, handed over (10k)", configuration: config()) { benchmark in
        var whole = makeOrg()
        let bump = ages3.over { $0 &+ 1 }
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            whole = bump(consume whole)
        }
        benchmark.stopMeasurement()
        blackHole(whole)
    }

    let app = App(session: .signedIn(org), draft: nil)
    Benchmark("preview — lens/prism/affine chain, no traversal", configuration: config()) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(firstTeamLeadAge.preview(app))
        }
    }
    Benchmark("tryModifyMut — lens/prism/affine chain, no traversal", configuration: config()) { benchmark in
        var whole = App(session: .signedIn(makeOrg()), draft: nil)
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            firstTeamLeadAge.tryModifyMut(&whole) { $0 &+= 1 }
        }
        benchmark.stopMeasurement()
        blackHole(whole)
    }
}
