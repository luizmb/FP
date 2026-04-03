import PlaygroundSupport

/// Run a playground section, keeping the page alive until it finishes.
///
///     learn(functorPublisher)
///     learn(monadDeferredTask)
public func learn(_ fn: @Sendable @escaping () async -> Void) {
    PlaygroundPage.current.needsIndefiniteExecution = true
    Task { @MainActor in
        await fn()
        PlaygroundPage.current.finishExecution()
    }
}
