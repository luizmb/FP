import FPMacros
import CoreFP
import CoreFPOperators
import Testing

// MARK: - Fixtures

@Lenses(init: .internal)
private struct Config {
    let host: String
    let version = 3       // constant — excluded from init and lens
    var port: Int
    var timeout = 30
}

@Lenses(init: .internal)
private struct Point {
    let x: Double
    let y: Double
}

// MARK: - Generated init

@Suite("@Lenses — generated init")
struct LensesInitTests {
    @Test func required_params_only_excludes_let_constants() {
        let c = Config(host: "localhost", port: 8080)
        #expect(c.host == "localhost")
        #expect(c.port == 8080)
        #expect(c.version == 3)
        #expect(c.timeout == 30)
    }

    @Test func var_default_is_carried_through() {
        let c = Config(host: "localhost", port: 8080)
        #expect(c.timeout == 30)
    }

    @Test func var_default_can_be_overridden() {
        let c = Config(host: "localhost", port: 8080, timeout: 60)
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
    private let config = Config(host: "localhost", port: 8080)

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
    private let config = Config(host: "localhost", port: 8080)

    @Test func set_changes_focused_property() {
        let updated = Config.lens.port.set(config, 9090)
        #expect(updated.port == 9090)
    }

    @Test func set_preserves_other_properties() {
        let updated = Config.lens.port.set(config, 9090)
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
        #expect(updated.port == 8081)
    }

    @Test func law_get_set() {
        let l = Config.lens.port
        #expect(l.set(config, l.get(config)).port == config.port)
    }

    @Test func law_set_get() {
        let l = Config.lens.port
        #expect(l.get(l.set(config, 9090)) == 9090)
    }

    @Test func law_set_set() {
        let l = Config.lens.port
        #expect(l.set(l.set(config, 1000), 9090).port == l.set(config, 9090).port)
    }
}

// MARK: - Composition with other optics

@Suite("@Lenses — composition")
struct LensesCompositionTests {
    @Lenses(init: .internal)
    private struct Server {
        let config: Config
        var name: String
    }

    @Test func compose_two_let_lenses() {
        let serverHostLens = Server.lens.config >>> Config.lens.host
        let server = Server(config: Config(host: "localhost", port: 8080), name: "main")
        let updated = serverHostLens.set(server, "example.com")
        #expect(updated.config.host == "example.com")
        #expect(updated.name == "main")
    }

    @Test func compose_let_and_var_lenses() {
        let serverPortLens = Server.lens.config >>> Config.lens.port
        let server = Server(config: Config(host: "localhost", port: 8080), name: "main")
        let updated = serverPortLens.set(server, 9090)
        #expect(updated.config.port == 9090)
        #expect(updated.config.host == "localhost")
    }
}
