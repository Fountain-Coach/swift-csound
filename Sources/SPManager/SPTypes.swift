import Foundation

/// A unique identifier representing a logical synthesizer session managed by
/// ``SPManager``.
public typealias SPSessionID = String

/// Describes an audio program that can be compiled by an ``SPBackend``.
public enum SPProgram: Equatable, Sendable {
    /// A Csound program described by orchestra (`orc`) and score (`sco`)
    /// source strings.
    case csound(orc: String, sco: String)
}

/// Possible errors surfaced by ``SPManager`` while orchestrating backends.
public enum SPManagerError: Error, Equatable {
    case sessionAlreadyRegistered(SPSessionID)
    case sessionNotFound(SPSessionID)
    case backendUnavailable(String)
    case invalidProgram(String)
}
