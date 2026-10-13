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
