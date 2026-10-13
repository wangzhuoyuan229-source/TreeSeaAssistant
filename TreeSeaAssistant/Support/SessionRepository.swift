import Foundation
import TreeSeaCore
nonisolated public struct SessionListing:Sendable {public var sessions:[MapSession];public var corruptCount:Int}
nonisolated public struct SessionRepository: Sendable {
    public var directory: URL
    public init(directory: URL) {self.directory=directory}
    public func save(_ session: MapSession) throws {
        try MapValidator.validate(session.map)
        try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true)
        let encoder=JSONEncoder();encoder.outputFormatting=[.sortedKeys]
        try encoder.encode(session).write(to:directory.appendingPathComponent(session.id.uuidString+".json"),options:.atomic)
    }
    public func load(id: UUID) throws -> MapSession? {
        let url=directory.appendingPathComponent(id.uuidString+".json")
        guard FileManager.default.fileExists(atPath:url.path) else {return nil}
        do {
            let session=try JSONDecoder().decode(MapSession.self,from:Data(contentsOf:url))
            try MapValidator.validate(session.map)
            guard session.id==id,(0...1000).contains(session.resources.actionPoints),session.mustPass.count<=8,session.mustPass.allSatisfy({session.map.node($0) != nil}),session.resources.items.count<=64,
                  Set(session.resources.items.map(\.instanceID)).count==session.resources.items.count,session.resources.items.allSatisfy({(0...100).contains($0.remainingCharges)}) else {throw SessionError.corruptSession}
            return session
        } catch {throw SessionError.corruptSession}
    }
    public func listRecoverable() throws -> SessionListing {
        guard FileManager.default.fileExists(atPath:directory.path) else {return SessionListing(sessions:[],corruptCount:0)}
        let files=try FileManager.default.contentsOfDirectory(at:directory,includingPropertiesForKeys:nil)
        var sessions:[MapSession]=[],corrupt=0
        for url in files where url.pathExtension=="json" {
            guard let id=UUID(uuidString:url.deletingPathExtension().lastPathComponent) else {corrupt += 1;continue}
            do {if let session=try load(id:id) {sessions.append(session)}} catch {corrupt += 1}
        }
        return SessionListing(sessions:sessions.sorted{$0.updatedAt>$1.updatedAt},corruptCount:corrupt)
    }
    public func list() throws -> [MapSession] {
        guard FileManager.default.fileExists(atPath:directory.path) else {return []}
        let files=try FileManager.default.contentsOfDirectory(at:directory,includingPropertiesForKeys:nil)
        return try files.filter{$0.pathExtension=="json"}.compactMap {url in guard let id=UUID(uuidString:url.deletingPathExtension().lastPathComponent) else {throw SessionError.corruptSession};return try load(id:id)}.sorted{$0.updatedAt>$1.updatedAt}
    }
}
