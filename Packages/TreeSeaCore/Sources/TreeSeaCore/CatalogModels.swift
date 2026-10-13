import Foundation
public enum ValidationStatus: String, Codable, Sendable {
    case researchReference, independentlyVerified, authorizedReviewed
    public var strong: Bool { self != .researchReference }
}
public struct Provenance: Codable, Sendable, Equatable {
    public var sourceURL: String; public var commit: String; public var status: ValidationStatus
    public init(sourceURL: String, commit: String, status: ValidationStatus = .researchReference) { self.sourceURL=sourceURL; self.commit=commit; self.status=status }
}
public enum DistanceRule: Codable, Sendable, Equatable {
    case forbidden, unrestricted, closedRange(min: Int, max: Int)
    public func allows(_ distance: Int) -> Bool {
        switch self { case .forbidden: false; case .unrestricted: true; case let .closedRange(a,b): (a...b).contains(distance) }
    }
}
public enum CountRule: Codable, Sendable, Equatable {
    case range(min: Int, max: Int), discrete([Int])
    public var allowed: [Int] { switch self { case let .range(a,b): a<=b ? Array(a...b) : []; case let .discrete(v): v.sorted() } }
    public var maximum: Int { allowed.max() ?? -1 }
    public var minimum: Int { allowed.min() ?? -1 }
}
public struct TypeRule: Codable, Sendable, Equatable {
    public var kind: NodeKind; public var floor: Int; public var distance: DistanceRule?; public var count: CountRule?; public var provenance: Provenance
    public init(kind: NodeKind, floor: Int, distance: DistanceRule? = nil, count: CountRule? = nil, provenance: Provenance) { self.kind=kind; self.floor=floor; self.distance=distance; self.count=count; self.provenance=provenance }
}
public struct RuleCatalog: Codable, Sendable, Equatable {
    public var version: String; public var order: [NodeKind]; public var rules: [TypeRule]
    public init(version: String, order: [NodeKind] = NodeKind.mysteryOrder, rules: [TypeRule]) { self.version=version; self.order=order; self.rules=rules }
    public func rule(_ kind: NodeKind, floor: Int) -> TypeRule? { rules.first { $0.kind == kind && $0.floor == floor } }
}
public struct MapTemplate: Codable, Sendable, Equatable, Identifiable {
    public var id: String; public var map: FloorMap; public var provenance: Provenance
    public init(id: String, map: FloorMap, provenance: Provenance) { self.id=id; self.map=map; self.provenance=provenance }
}
public struct TemplateCatalog: Codable, Sendable, Equatable {
    public var version: String; public var templates: [MapTemplate]
    public init(version: String, templates: [MapTemplate]) { self.version=version; self.templates=templates }
}
public struct CatalogBundle: Codable, Sendable, Equatable {
    public var rules: RuleCatalog; public var templates: TemplateCatalog
    public init(rules: RuleCatalog, templates: TemplateCatalog) { self.rules=rules; self.templates=templates }
}
public enum MovementRange: String, Codable, Sendable { case orthogonalTwo, surroundingEight, manhattanTwo, orthogonalThree, fullMap }
public enum TargetFilter: String, Codable, Sendable { case all, nonCombat, shop }
public struct MovementSpec: Codable, Sendable, Equatable, Identifiable {
    public var id: String; public var sourceID: String; public var name: String; public var aliases: [String]
    public var range: MovementRange; public var targetFilter: TargetFilter
    public var apCost: Int; public var minimumAPToStart: Int; public var initialCharges: Int
    public var randomTarget: Bool; public var expiresOnFloorEnd: Bool; public var effects: ItemEffects; public var provenance: Provenance
}
public struct MovementCatalog: Codable, Sendable, Equatable {
    public var version: String; public var movements: [MovementSpec]
    public func spec(_ id: String) -> MovementSpec? { movements.first { $0.id == id } }
    public init(version: String, movements: [MovementSpec]) { self.version=version; self.movements=movements }
}
public enum CatalogLoader {
    public static func decode(_ data: Data) throws -> CatalogBundle {
        let value = try JSONDecoder().decode(CatalogBundle.self, from:data)
        guard !value.rules.version.isEmpty, Set(value.rules.order).count == value.rules.order.count,
              value.rules.order.allSatisfy({ NodeKind.mysteryOrder.contains($0) }) else { throw CoreError.invalidCatalog("候选分类无效") }
        var seen = Set<String>()
        for rule in value.rules.rules {
            guard (1...5).contains(rule.floor), seen.insert("\(rule.floor):\(rule.kind)").inserted, !rule.provenance.sourceURL.isEmpty else { throw CoreError.invalidCatalog("规则来源或楼层无效") }
            if case let .closedRange(a,b) = rule.distance { guard a >= 0, b >= a, b <= 64 else { throw CoreError.invalidCatalog("距离范围无效") } }
            if let count = rule.count {
                guard count.minimum >= 0, count.maximum <= 64, !count.allowed.isEmpty else { throw CoreError.invalidCatalog("数量范围无效") }
            }
        }
        guard Set(value.templates.templates.map(\.id)).count == value.templates.templates.count else { throw CoreError.invalidCatalog("模板重复") }
        for template in value.templates.templates { try MapValidator.validate(template.map); guard !template.provenance.sourceURL.isEmpty else { throw CoreError.invalidCatalog("模板来源缺失") } }
        return value
    }
    public static func decodeMovements(_ data: Data) throws -> MovementCatalog {
        let value = try JSONDecoder().decode(MovementCatalog.self,from:data)
        guard !value.version.isEmpty, Set(value.movements.map(\.id)).count == value.movements.count else { throw CoreError.invalidCatalog("加工品重复") }
        for spec in value.movements {
            guard (0...1000).contains(spec.apCost), (0...1000).contains(spec.minimumAPToStart), (0...100).contains(spec.initialCharges),
                  [spec.effects.ap,spec.effects.hope,spec.effects.ingots].allSatisfy({ (0...1000).contains($0) }), !spec.provenance.sourceURL.isEmpty else { throw CoreError.invalidCatalog("加工品资源或来源无效") }
        }
        return value
    }
    public static func bundled() throws -> CatalogBundle { try decode(Data(contentsOf: Bundle.module.url(forResource:"catalog",withExtension:"json")!)) }
    public static func bundledMovements() throws -> MovementCatalog { try decodeMovements(Data(contentsOf: Bundle.module.url(forResource:"movement-catalog",withExtension:"json")!)) }
}
