import CoreFP
import CoreFPOperators
import FPMacros
import Testing

// MARK: - Fixtures

@Lenses(init: .internal)
fileprivate struct Config {
    let host: String
    let version = 3       // constant — excluded from init and lens
    var port: Int
    var timeout = 30
}

@Lenses(init: .internal)
fileprivate struct Point {
    let x: Double
    let y: Double
}

// MARK: - Generated init

@Suite("@Lenses — generated init")
struct LensesInitTests {
    @Test func required_params_only_excludes_let_constants() {
        let c = Config(host: "localhost", port: 8_080)
        #expect(c.host == "localhost")
        #expect(c.port == 8_080)
        #expect(c.version == 3)
        #expect(c.timeout == 30)
    }

    @Test func var_default_is_carried_through() {
        let c = Config(host: "localhost", port: 8_080)
        #expect(c.timeout == 30)
    }

    @Test func var_default_can_be_overridden() {
        let c = Config(host: "localhost", port: 8_080, timeout: 60)
        #expect(c.timeout == 60)
    }

    @Test func all_let_params_required() {
        let p = Point(x: 1.0, y: 2.0)
        #expect(p.x == 1.0)
        #expect(p.y == 2.0)
    }
}

// MARK: - Reconstruction lenses (let properties)

@Suite("@Lenses — reconstruction lens (let)")
struct LensesLetTests {
    private let config = Config(host: "localhost", port: 8_080)

    @Test func set_changes_focused_property() {
        let updated = Config.lens.host.set(config, "example.com")
        #expect(updated.host == "example.com")
    }

    @Test func set_preserves_other_properties() {
        let updated = Config.lens.host.set(config, "example.com")
        #expect(updated.port == config.port)
        #expect(updated.timeout == config.timeout)
        #expect(updated.version == 3)
    }

    @Test func over_transforms_focused_property() {
        let updated = Config.lens.host.over({ $0 + ":9000" })(config)
        #expect(updated.host == "localhost:9000")
        #expect(updated.port == config.port)
    }

    @Test func law_get_set() {
        let l = Config.lens.host
        #expect(l.set(config, l.get(config)).host == config.host)
    }

    @Test func law_set_get() {
        let l = Config.lens.host
        #expect(l.get(l.set(config, "new")) == "new")
    }

    @Test func law_set_set() {
        let l = Config.lens.host
        #expect(l.set(l.set(config, "first"), "second").host == l.set(config, "second").host)
    }
}

// MARK: - WritableKeyPath lenses (var properties)

@Suite("@Lenses — WritableKeyPath lens (var)")
struct LensesVarTests {
    private let config = Config(host: "localhost", port: 8_080)

    @Test func set_changes_focused_property() {
        let updated = Config.lens.port.set(config, 9_090)
        #expect(updated.port == 9_090)
    }

    @Test func set_preserves_other_properties() {
        let updated = Config.lens.port.set(config, 9_090)
        #expect(updated.host == config.host)
        #expect(updated.timeout == config.timeout)
        #expect(updated.version == 3)
    }

    @Test func var_with_default_lens_works() {
        let updated = Config.lens.timeout.set(config, 60)
        #expect(updated.timeout == 60)
        #expect(updated.host == config.host)
        #expect(updated.port == config.port)
    }

    @Test func over_transforms_focused_property() {
        let updated = Config.lens.port.over({ $0 + 1 })(config)
        #expect(updated.port == 8_081)
    }

    @Test func law_get_set() {
        let l = Config.lens.port
        #expect(l.set(config, l.get(config)).port == config.port)
    }

    @Test func law_set_get() {
        let l = Config.lens.port
        #expect(l.get(l.set(config, 9_090)) == 9_090)
    }

    @Test func law_set_set() {
        let l = Config.lens.port
        #expect(l.set(l.set(config, 1_000), 9_090).port == l.set(config, 9_090).port)
    }
}

// MARK: - Composition with other optics

@Suite("@Lenses — composition")
struct LensesCompositionTests {
    @Lenses(init: .internal)
    fileprivate struct Server {
        let config: Config
        var name: String
    }

    @Test func compose_two_let_lenses() {
        let serverHostLens = Server.lens.config >>> Config.lens.host
        let server = Server(config: Config(host: "localhost", port: 8_080), name: "main")
        let updated = serverHostLens.set(server, "example.com")
        #expect(updated.config.host == "example.com")
        #expect(updated.name == "main")
    }

    @Test func compose_let_and_var_lenses() {
        let serverPortLens = Server.lens.config >>> Config.lens.port
        let server = Server(config: Config(host: "localhost", port: 8_080), name: "main")
        let updated = serverPortLens.set(server, 9_090)
        #expect(updated.config.port == 9_090)
        #expect(updated.config.host == "localhost")
    }
}

// MARK: - with(...) helper

@Suite("@Lenses — with(...) helper")
struct LensesWithTests {
    private let config = Config(host: "localhost", port: 8_080)

    @Test func with_no_args_returns_equivalent_value() {
        let same = config.with()
        #expect(same.host == config.host)
        #expect(same.port == config.port)
        #expect(same.timeout == config.timeout)
    }

    @Test func with_single_override_keeps_other_fields() {
        let updated = config.with(host: "example.com")
        #expect(updated.host == "example.com")
        #expect(updated.port == config.port)
        #expect(updated.timeout == config.timeout)
    }

    @Test func with_multiple_overrides() {
        let updated = config.with(host: "example.com", port: 9_090, timeout: 120)
        #expect(updated.host == "example.com")
        #expect(updated.port == 9_090)
        #expect(updated.timeout == 120)
    }
}

// MARK: - LensesEmit — granular emission

@Lenses(.initOnly)
fileprivate struct InitOnlyStruct {
    let name: String
    var count: Int
}

@Lenses(.lensesOnly)
fileprivate struct LensesOnlyStruct {
    var x: Int
    var y: Int
    // No explicit init — Swift synthesizes the memberwise init since `.lensesOnly`
    // tells the macro to skip its own emission.
}

@Suite("@Lenses — options slicing")
struct LensesEmitTests {
    @Test func initOnly_emits_init() {
        let v = InitOnlyStruct(name: "abc", count: 7)
        #expect(v.name == "abc")
        #expect(v.count == 7)
    }

    @Test func lensesOnly_skips_init_uses_user_init() {
        let v = LensesOnlyStruct(x: 1, y: 2)
        let updated = LensesOnlyStruct.lens.x.set(v, 10)
        #expect(updated.x == 10)
        #expect(updated.y == 2)
    }

    @Test func lensesOnly_emits_with() {
        let v = LensesOnlyStruct(x: 1, y: 2)
        let updated = v.with(x: 10)
        #expect(updated.x == 10)
        #expect(updated.y == 2)
    }
}

// MARK: - Init conflict detection

@Lenses(init: .internal)
fileprivate struct UserHasMatchingInit {
    let name: String
    var count: Int

    // User-declared init with same labels — macro should skip its own init
    init(name: String, count: Int) {
        self.name = name.uppercased()
        self.count = count * 2
    }
}

@Suite("@Lenses — init conflict detection")
struct LensesInitConflictTests {
    @Test func macro_skips_init_when_user_has_matching_one() {
        // User's init transforms the inputs — proof their init was used, not the macro's
        let v = UserHasMatchingInit(name: "abc", count: 5)
        #expect(v.name == "ABC")
        #expect(v.count == 10)
    }

    @Test func lens_set_resolves_through_user_init() {
        let v = UserHasMatchingInit(name: "abc", count: 5)
        let updated = UserHasMatchingInit.lens.name.set(v, "xyz")
        // Reconstruction lens calls Self(name:count:) → resolves to user's init
        #expect(updated.name == "XYZ")
    }
}
