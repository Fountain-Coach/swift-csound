#if !canImport(Darwin)
import Foundation
import SPManager

public enum CsoundBackendError: Error {
    case unavailable
}

/// Placeholder backend for platforms where Csound is unavailable at build
/// time. The methods throw immediately, instructing callers that the backend is
/// not usable in the current environment.
public final class CsoundBackend: SPBackend, @unchecked Sendable {
    public init() {}

    public func prepare() async throws {
        throw CsoundBackendError.unavailable
    }

    public func compile(program: SPProgram) async throws {
        throw CsoundBackendError.unavailable
    }

    public func start() async throws {
        throw CsoundBackendError.unavailable
    }

    public func stop() async throws {
        throw CsoundBackendError.unavailable
    }

    public func setControl(_ name: String, value: Double) async throws {
        throw CsoundBackendError.unavailable
    }

    public func teardown() async {}
}
#endif
