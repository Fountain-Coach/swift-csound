import Foundation

/// Lightweight in-memory backend that records lifecycle invocations. Useful for
/// previews and unit tests where a real audio engine is undesirable.
public final class SPMockBackend: SPBackend, @unchecked Sendable {
    public private(set) var preparedCount = 0
    public private(set) var compiledPrograms: [SPProgram] = []
    public private(set) var startedCount = 0
    public private(set) var stoppedCount = 0
    public private(set) var controlEvents: [(String, Double)] = []

    public init() {}

    public func prepare() async throws {
        preparedCount += 1
    }

    public func compile(program: SPProgram) async throws {
        compiledPrograms.append(program)
    }

    public func start() async throws {
        startedCount += 1
    }

    public func stop() async throws {
        stoppedCount += 1
    }

    public func setControl(_ name: String, value: Double) async throws {
        controlEvents.append((name, value))
    }

    public func teardown() async {
        compiledPrograms.removeAll(keepingCapacity: true)
        controlEvents.removeAll(keepingCapacity: true)
    }
}
