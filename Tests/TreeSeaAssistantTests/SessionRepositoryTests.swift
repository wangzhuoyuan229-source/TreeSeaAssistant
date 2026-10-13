import Foundation
import Testing
#if SWIFT_PACKAGE
@testable import TreeSeaAppSupport
#else
@testable import TreeSeaAssistant
#endif
struct SessionRepositoryTests {
    @Test func atomicallyPersistAndPreserveCorruptEvidence() throws {
        let dir=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString),repository=SessionRepository(directory:dir),session=try sampleSession()
        defer {try? FileManager.default.removeItem(at:dir)}
        try repository.save(session)
        #expect(try repository.load(id:session.id)==session); #expect(try repository.list().count==1)
        let url=dir.appendingPathComponent(session.id.uuidString+".json")
        try Data("broken".utf8).write(to:url)
        #expect(throws:SessionError.self) {try repository.load(id:session.id)}
        #expect(try String(contentsOf:url,encoding:.utf8)=="broken")
    }
}
struct SessionRecoveryTests {
    @Test func corruptSessionDoesNotHideOtherValidSessions() throws {
        let dir=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString),repository=SessionRepository(directory:dir),good=try sampleSession();var bad=try sampleSession();bad.id=UUID()
        defer{try? FileManager.default.removeItem(at:dir)}
        try repository.save(good);try repository.save(bad)
        let badFile=dir.appendingPathComponent(bad.id.uuidString+".json");try Data("broken".utf8).write(to:badFile)
        let listed=try repository.listRecoverable()
        #expect(listed.sessions==[good]);#expect(listed.corruptCount==1);#expect(try String(contentsOf:badFile,encoding:.utf8)=="broken")
    }
}
