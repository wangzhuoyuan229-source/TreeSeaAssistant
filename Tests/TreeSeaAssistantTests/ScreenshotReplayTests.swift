import Foundation
import CoreGraphics
import Testing
import TreeSeaCore
#if SWIFT_PACKAGE
@testable import TreeSeaRecognition
@testable import TreeSeaAppSupport
#else
@testable import TreeSeaAssistant
#endif

struct ScreenshotReplayTests {
    // Independently annotated visible cells. Public fixture filenames do not identify
    // the matching MAA catalog template, and must not be used as recognition inputs.
    static let cases: [(String, Int, [Int])] = [
        ("user-floor1.png",1,[1,2,3,4,5,6,7,8,11,12,13,14]),
        ("floor1-template01-normal-001.png",1,[1,2,3,4,5,6,7,8,11,12,13,14]),
        ("floor2-template03-normal-001.png",2,Array(0...17)+[19]),
        ("floor3-template01-op7-001.png",3,Array(0...16)+Array(19...32)),
        ("floor4-template03-normal-001.png",4,Array(0...12)+Array(14...23)+Array(26...31)+Array(34...36)),
        ("floor5-template01-normal-001.png",5,[2,3,4,5,6,7,9,10,11,13,14,16,17,18,19,21,22,23,24,25,26,27,29]+Array(30...42)+Array(44...49))
    ]
    static let roads:[Int:Set<String>] = [
        1:["1:2","2:3","3:4","2:7","3:8","5:6","6:7","7:8","7:12","8:13","11:12","12:13","13:14"],
        2:["0:1","0:5","1:2","1:6","2:3","2:7","3:4","4:9","5:10","6:11","7:8","8:9","8:13","10:15","11:12","11:16","12:13","12:17","13:14","14:19"],
        3:["0:1","1:2","2:3","3:4","3:10","4:5","4:11","5:6","5:12","6:13","7:8","8:9","8:15","9:10","9:16","10:11","11:12","12:13","13:20","14:15","15:22","19:20","19:26","20:27","21:28","22:23","23:24","24:25","25:26","25:32","28:29","29:30","30:31","31:32"],
        4:["0:1","0:8","1:2","1:9","2:3","3:4","3:11","4:5","5:6","6:14","7:15","8:9","8:16","9:10","11:12","12:20","14:15","15:23","16:17","18:19","18:26","19:20","19:27","20:21","21:22","22:23","22:30","26:27","26:34","27:28","28:29","28:36","29:30","30:31","34:35"],
        5:["2:3","3:4","3:13","4:5","4:14","5:6","6:7","6:16","7:17","9:19","10:11","11:21","13:23","14:24","16:26","17:18","17:27","18:19","19:29","21:22","21:31","22:23","22:32","24:34","25:26","27:37","29:39","30:31","31:32","31:41","32:33","33:34","35:36","35:45","36:37","36:46","37:38","37:47","40:41","41:42","44:45","45:46","47:48","48:49"]
    ]

    @Test func labelTableWithoutVisibleNodeDiscsIsRejected() throws {
        let prepared=try ImagePreprocessor.prepare(syntheticPNG(width:800,height:600),crop:nil)
        let image=try ImagePreprocessor.image(prepared)
        let texts=(0..<3).flatMap{r in (0..<5).map{c in RecognizedText(text:"未知的诡秘",center:Point2D(x:100+Double(c)*150,y:100+Double(r)*150))}}
        let centers=try NodeCenterDetector.detect(in:prepared,texts:texts,image:image)
        #expect(GridFitter.fit(centers:centers,rows:3,columns:5)==nil)
    }

    @Test(.enabled(if:ProcessInfo.processInfo.environment["TREESEA_REPLAY_DIR"] != nil,"Run scripts/test-recognition-replay.sh to supply real screenshots"))
    func realScreenshotGeometryAndUnconfirmedEvidence() async throws {
        let directory=try #require(ProcessInfo.processInfo.environment["TREESEA_REPLAY_DIR"])
        let catalog=try CatalogLoader.bundled().templates
        var reports:[[String:Any]]=[]
        for (filename,floor,expected) in Self.cases {
            let prepared=try ImagePreprocessor.prepare(Data(contentsOf:URL(fileURLWithPath:directory).appendingPathComponent(filename)),crop:nil)
            let image=try ImagePreprocessor.image(prepared)
            let texts=try ScreenshotRecognizer.mapTexts(image,width:prepared.width,height:prepared.height)
            let centers=try NodeCenterDetector.detect(in:prepared,texts:texts,image:image)
            let proposal=try await ScreenshotRecognizer.recognize(prepared,floor:floor,catalog:catalog)
            let dimensions=[1:(3,5),2:(4,5),3:(5,7),4:(5,8),5:(5,10)][floor]!
            let fit=GridFitter.fit(centers:centers,rows:dimensions.0,columns:dimensions.1)
            var report:[String:Any]=["file":filename,"floor":floor,"width":prepared.width,"height":prepared.height,
                "warnings":proposal.warnings,"expectedIDs":expected,"expectedEdges":Self.roads[floor]!.sorted(),
                "centers":centers.map{["x":$0.center.x,"y":$0.center.y,"kind":$0.kind?.rawValue ?? "unknown"]},
                "texts":texts.map{["x":$0.center.x,"y":$0.center.y,"text":$0.text]}]
            if let fit {
                report["positions"]=fit.centers.keys.sorted().map {id -> [String:Any] in
                    let p=fit.centers[id]!.center,original=prepared.transform.toOriginal(CGPoint(x:p.x,y:p.y))
                    return ["id":id,"row":id/dimensions.1,"column":id%dimensions.1,"workingX":p.x,"workingY":p.y,"originalX":original.x,"originalY":original.y]
                }
                report["residual"]=fit.residual
                if filename=="user-floor1.png" {
                    for (id,x,y):(Int,Double,Double) in [(1,422,135),(7,642,355),(14,1082,575)] {
                        let center=try #require(fit.centers[id]?.center),original=prepared.transform.toOriginal(CGPoint(x:center.x,y:center.y))
                        #expect(hypot(original.x-x,original.y-y)<8,"User screenshot node \(id) must lie on its visible icon")
                    }
                }
            }
            #expect(!proposal.confirmed)
            if let map=proposal.map {
                report["map"]=try JSONSerialization.jsonObject(with:JSONEncoder().encode(map))
                #expect(Set(map.nodes.map(\.id))==Set(expected),"\(filename): independently annotated cells")
                #expect(Set(map.edges.map{"\($0.a):\($0.b)"})==Self.roads[floor],"\(filename): visible roads")
                #expect(map.initialStartID==nil && map.currentNodeID==nil && map.startEvidence == .unresolved)
                #expect(!map.topologyVerified && map.originalCoverage == .partial)
                #expect(map.edges.allSatisfy{$0.state == .inferred})
                #expect(map.nodes.allSatisfy{$0.identityEvidence != .userConfirmed && $0.traversalEvidence == .unresolved})
                let expectedExits:Set<Int>=filename=="user-floor1.png" ? [4,14] : [1:[14],2:[9],3:[],4:[],5:[]][floor]!
                #expect(map.exitIDs==expectedExits)
                if floor==4 {#expect(map.node(2)?.observedKind == .exit && map.node(2)?.identityEvidence == .unresolved)}
                #expect(map.exitIDs.allSatisfy{map.node($0)?.observedKind == .exit && map.node($0)?.identityEvidence == .directObservation})
            } else {Issue.record("\(filename): clear full map was rejected")}
            reports.append(report)
        }
        if let output=ProcessInfo.processInfo.environment["TREESEA_REPLAY_OUTPUT"] {
            try JSONSerialization.data(withJSONObject:reports,options:[.prettyPrinted,.sortedKeys]).write(to:URL(fileURLWithPath:output))
        }
    }

    @Test(.enabled(if:ProcessInfo.processInfo.environment["TREESEA_REPLAY_DIR"] != nil,"Run scripts/test-recognition-replay.sh to supply real screenshots"))
    func partialHUDAndWrongFloorRemainRejected() async throws {
        let directory=try #require(ProcessInfo.processInfo.environment["TREESEA_REPLAY_DIR"]),catalog=try CatalogLoader.bundled().templates
        let user=try Data(contentsOf:URL(fileURLWithPath:directory).appendingPathComponent("user-floor1.png"))
        let partial=try ImagePreprocessor.prepare(user,crop:CGRect(x:0,y:0,width:1050,height:866))
        #expect(try await ScreenshotRecognizer.recognize(partial,floor:1,catalog:catalog).map==nil)
        let complete=try ImagePreprocessor.prepare(user,crop:nil)
        #expect(try await ScreenshotRecognizer.recognize(complete,floor:3,catalog:catalog).map==nil)
        let game=try Data(contentsOf:URL(fileURLWithPath:directory).appendingPathComponent("floor1-template01-normal-001.png"))
        let hud=try ImagePreprocessor.prepare(game,crop:CGRect(x:0,y:0,width:2400,height:150))
        #expect(try await ScreenshotRecognizer.recognize(hud,floor:1,catalog:catalog).map==nil)
    }
}


struct RecognitionDatabaseTests {
    private struct DatabaseStub:MapImageRecognitionDatabase {
        let version="test-v1"
        var query:@Sendable (PreparedScreenshot,Int) async throws -> RecognitionProposal?
        func proposal(for screenshot:PreparedScreenshot,floor:Int) async throws -> RecognitionProposal? {try await query(screenshot,floor)}
    }

    @Test func importedMatchIsOnlyAnUnconfirmedProposal() async throws {
        let screenshot=try ImagePreprocessor.prepare(syntheticPNG(width:400,height:300),crop:nil)
        let catalog=try CatalogLoader.bundled().templates
        var imported=RecognitionProposal(map:catalog.templates[0].map,warnings:["Imported reference requires review"])
        imported.confirmed=true
        let supplied=imported
        let database=DatabaseStub {image,floor in
            #expect(image.digest==screenshot.digest && floor==1)
            return supplied
        }
        let actual=try await ScreenshotRecognizer.recognize(screenshot,floor:1,catalog:catalog,database:database)
        #expect(actual.map==supplied.map)
        #expect(actual.warnings==supplied.warnings)
        #expect(!actual.confirmed)
    }

    @Test(arguments:[false,true])
    func missingOrWrongFloorMatchFallsBackToCurrentRecognition(wrongFloor:Bool) async throws {
        let screenshot=try ImagePreprocessor.prepare(syntheticPNG(width:400,height:300),crop:nil)
        let catalog=try CatalogLoader.bundled().templates
        var map=catalog.templates[0].map;map.floor=2
        let supplied=RecognitionProposal(map:map)
        let database=DatabaseStub {_,_ in wrongFloor ? supplied : nil}
        let baseline=try await ScreenshotRecognizer.recognize(screenshot,floor:1,catalog:catalog)
        let actual=try await ScreenshotRecognizer.recognize(screenshot,floor:1,catalog:catalog,database:database)
        #expect(actual.map==baseline.map && actual.warnings==baseline.warnings)
        #expect(!actual.confirmed)
    }

    @Test(arguments:[false,true])
    func cancellationBeforeOrDuringDatabaseQueryStopsRecognition(duringQuery:Bool) async throws {
        let screenshot=try ImagePreprocessor.prepare(syntheticPNG(width:400,height:300),crop:nil)
        let catalog=try CatalogLoader.bundled().templates
        let supplied=RecognitionProposal(map:catalog.templates[0].map)
        let database=DatabaseStub {_,_ in
            #expect(duringQuery,"A pre-cancelled recognition must not query the database")
            withUnsafeCurrentTask{$0?.cancel()}
            return supplied
        }
        let task=Task {
            if !duringQuery {withUnsafeCurrentTask{$0?.cancel()}}
            return try await ScreenshotRecognizer.recognize(screenshot,floor:1,catalog:catalog,database:database)
        }
        do {_=try await task.value;Issue.record("Cancelled recognition returned a proposal")}
        catch ScreenshotError.cancelled {}
    }
}
