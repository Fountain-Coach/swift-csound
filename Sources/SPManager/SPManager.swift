import Foundation

/// High level orchestrator that keeps track of synthesizer sessions and their
/// associated backends.
public actor SPManager {
    private struct SessionState {
        var backend: SPBackend
        var lastProgram: SPProgram?

        init(backend: SPBackend) {
            self.backend = backend
        }
    }

    private var sessions: [SPSessionID: SessionState] = [:]

    public init() {}

    /// Register or replace the backend associated with a session identifier.
    @discardableResult
    public func upsertSession(id: SPSessionID, backend: SPBackend) async throws -> SPBackend {
        if var state = sessions[id] {
            await state.backend.teardown()
            state.backend = backend
            sessions[id] = state
        } else {
            sessions[id] = SessionState(backend: backend)
        }

        try await backend.prepare()
        return backend
    }

    /// Remove a session entirely, shutting down its backend.
    public func removeSession(id: SPSessionID) async {
        if let state = sessions.removeValue(forKey: id) {
            await state.backend.teardown()
        }
    }

    /// Compile a program for a particular session.
    public func compile(id: SPSessionID, program: SPProgram) async throws {
        guard var state = sessions[id] else {
            throw SPManagerError.sessionNotFound(id)
        }

        try await state.backend.compile(program: program)
        state.lastProgram = program
        sessions[id] = state
    }

    /// Start rendering audio for a session.
    public func start(id: SPSessionID) async throws {
        guard let state = sessions[id] else {
            throw SPManagerError.sessionNotFound(id)
        }
        try await state.backend.start()
    }

    /// Stop rendering audio for a session.
    public func stop(id: SPSessionID) async throws {
        guard let state = sessions[id] else {
            throw SPManagerError.sessionNotFound(id)
        }
        try await state.backend.stop()
    }

    /// Apply a control parameter update to the session backend.
    public func setControl(id: SPSessionID, _ name: String, value: Double) async throws {
        guard let state = sessions[id] else {
            throw SPManagerError.sessionNotFound(id)
        }
        try await state.backend.setControl(name, value: value)
    }

    /// Retrieve the last compiled program for inspection.
    public func lastProgram(id: SPSessionID) async -> SPProgram? {
        sessions[id]?.lastProgram
    }

    /// Returns whether a session is currently registered.
    public func hasSession(id: SPSessionID) async -> Bool {
        sessions[id] != nil
    }
}
