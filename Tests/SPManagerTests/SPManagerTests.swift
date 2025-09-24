import XCTest
@testable import SPManager

final class SPManagerTests: XCTestCase {
    func testSessionLifecycle() async throws {
        let manager = SPManager()
        let backend = SPMockBackend()
        let session: SPSessionID = "main"

        try await manager.upsertSession(id: session, backend: backend)
        try await manager.compile(id: session, program: .csound(orc: "instr 1", sco: "i1 0 1"))
        try await manager.start(id: session)
        try await manager.setControl(id: session, "freq", value: 440)
        try await manager.stop(id: session)

        XCTAssertEqual(backend.preparedCount, 1)
        XCTAssertEqual(backend.startedCount, 1)
        XCTAssertEqual(backend.stoppedCount, 1)
        XCTAssertEqual(backend.controlEvents.count, 1)

        await manager.removeSession(id: session)
        let stillRegistered = await manager.hasSession(id: session)
        XCTAssertFalse(stillRegistered)
        XCTAssertTrue(backend.controlEvents.isEmpty)
    }

    func testCompileWithoutSessionFails() async {
        let manager = SPManager()
        await XCTAssertThrowsErrorAsync(try await manager.compile(id: "missing", program: .csound(orc: "", sco: "")))
    }
}

extension XCTestCase {
    func XCTAssertThrowsErrorAsync<T>(_ expression: @autoclosure () async throws -> T, _ message: @autoclosure () -> String = "", file: StaticString = #filePath, line: UInt = #line) async {
        do {
            _ = try await expression()
            XCTFail(message(), file: file, line: line)
        } catch {
            // expected
        }
    }
}
