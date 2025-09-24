import Foundation

/// Describes the life-cycle and control operations that a backend must
/// implement to participate in the ``SPManager`` orchestration.
///
/// The protocol is class-constrained so that the manager can hold onto a single
/// reference per session without copying state, while the ``Sendable``
/// conformance is marked as unchecked because most audio engines are
/// implemented with reference semantics.
public protocol SPBackend: AnyObject {
    /// Prepare any internal resources. This must be safe to call multiple
    /// times and is expected to be allocation-heavy.
    func prepare() async throws

    /// Compile the supplied program into a runnable form.
    func compile(program: SPProgram) async throws

    /// Start rendering audio. Implementations must be idempotent and
    /// allocation-free in the audio render path.
    func start() async throws

    /// Stop rendering audio. This should block until rendering has ceased.
    func stop() async throws

    /// Update a named control parameter to a scalar value.
    func setControl(_ name: String, value: Double) async throws

    /// Tear down the backend. Called when a session is removed from the manager
    /// or replaced with a new backend.
    func teardown() async
}

extension SPBackend {
    public func prepare() async throws {}
    public func compile(program: SPProgram) async throws {}
    public func start() async throws {}
    public func stop() async throws {}
    public func setControl(_ name: String, value: Double) async throws {}
    public func teardown() async {}
}
