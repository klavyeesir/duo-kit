import Foundation
import SwiftSyntax
import SwiftParser

let toolVersion = "0.1.0"

// MARK: - Model

struct Finding {
    let file: String
    let line: Int
    let column: Int
    let rule: String
    let message: String
}

struct RuleInfo {
    let id: String
    let summary: String
}

let ruleCatalog: [RuleInfo] = [
    RuleInfo(id: "duo-screen-bounds",
             summary: "Avoid UIScreen.main.bounds; iPhone Duo changes display size at runtime."),
    RuleInfo(id: "duo-odd-grid-columns",
             summary: "Avoid odd grid column counts; the middle column lands on the iPhone Duo fold."),
]

// MARK: - Rules

class Rule: SyntaxVisitor {
    let file: String
    let converter: SourceLocationConverter
    var findings: [Finding] = []

    init(file: String, tree: SourceFileSyntax) {
        self.file = file
        self.converter = SourceLocationConverter(fileName: file, tree: tree)
        super.init(viewMode: .sourceAccurate)
    }

    func report(_ node: some SyntaxProtocol, rule: String, message: String) {
        let loc = node.startLocation(converter: converter)
        findings.append(Finding(file: file, line: loc.line, column: loc.column, rule: rule, message: message))
    }
}

final class ScreenBoundsRule: Rule {
    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        if node.declName.baseName.text == "bounds",
           node.base?.trimmedDescription == "UIScreen.main" {
            report(node, rule: "duo-screen-bounds",
                   message: "Use GeometryReader / size classes instead of UIScreen.main.bounds")
        }
        return .visitChildren
    }
}

final class OddGridColumnsRule: Rule {
    private func isGridItemCall(_ expr: ExprSyntax) -> Bool {
        expr.as(FunctionCallExprSyntax.self)?.calledExpression.trimmedDescription == "GridItem"
    }

    private func reportIfOdd(_ node: some SyntaxProtocol, count: Int) {
        if count >= 3 && count % 2 == 1 {
            report(node, rule: "duo-odd-grid-columns",
                   message: "\(count) grid columns: the middle column lands on the iPhone Duo fold. Use an even column count.")
        }
    }

    override func visit(_ node: ArrayExprSyntax) -> SyntaxVisitorContinueKind {
        let elements = node.elements.map { $0.expression }
        if !elements.isEmpty, elements.allSatisfy(isGridItemCall) {
            reportIfOdd(node, count: elements.count)
        }
        return .visitChildren
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard node.calledExpression.trimmedDescription == "Array" else { return .visitChildren }
        let args = Dictionary(node.arguments.compactMap { arg in arg.label.map { ($0.text, arg.expression) } },
                              uniquingKeysWith: { first, _ in first })
        if let repeating = args["repeating"], isGridItemCall(repeating),
           let countExpr = args["count"]?.as(IntegerLiteralExprSyntax.self),
           let count = Int(countExpr.literal.text) {
            reportIfOdd(node, count: count)
        }
        return .visitChildren
    }
}

// MARK: - SARIF 2.1.0

struct SarifLog: Encodable {
    let version = "2.1.0"
    let schema = "https://json.schemastore.org/sarif-2.1.0.json"
    let runs: [SarifRun]
    enum CodingKeys: String, CodingKey { case version, schema = "$schema", runs }
}
struct SarifRun: Encodable { let tool: SarifTool; let results: [SarifResult] }
struct SarifTool: Encodable { let driver: SarifDriver }
struct SarifDriver: Encodable {
    let name: String
    let version: String
    let informationUri: String
    let rules: [SarifRule]
}
struct SarifRule: Encodable { let id: String; let shortDescription: SarifText }
struct SarifText: Encodable { let text: String }
struct SarifResult: Encodable {
    let ruleId: String
    let level: String
    let message: SarifText
    let locations: [SarifLocation]
}
struct SarifLocation: Encodable { let physicalLocation: SarifPhysicalLocation }
struct SarifPhysicalLocation: Encodable { let artifactLocation: SarifArtifact; let region: SarifRegion }
struct SarifArtifact: Encodable { let uri: String }
struct SarifRegion: Encodable { let startLine: Int; let startColumn: Int }

func makeSarif(_ findings: [Finding]) -> SarifLog {
    let driver = SarifDriver(
        name: "DuoLint",
        version: toolVersion,
        informationUri: "https://github.com/klavyeesir/duo-kit",
        rules: ruleCatalog.map { SarifRule(id: $0.id, shortDescription: SarifText(text: $0.summary)) })
    let results = findings.map { f in
        SarifResult(
            ruleId: f.rule,
            level: "warning",
            message: SarifText(text: f.message),
            locations: [SarifLocation(physicalLocation: SarifPhysicalLocation(
                artifactLocation: SarifArtifact(uri: f.file),
                region: SarifRegion(startLine: f.line, startColumn: f.column)))])
    }
    return SarifLog(runs: [SarifRun(tool: SarifTool(driver: driver), results: results)])
}

// MARK: - CLI

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("error: \(message)\n".utf8))
    exit(2)
}

func normalized(_ path: String) -> String {
    path.hasPrefix("./") ? String(path.dropFirst(2)) : path
}

let skippedDirectories: Set<String> = [".build", ".git", "Pods", "DerivedData", "node_modules"]

func swiftFiles(at path: String) -> [String] {
    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) else {
        fail("path not found: \(path)")
    }
    if !isDirectory.boolValue {
        return path.hasSuffix(".swift") ? [normalized(path)] : []
    }
    guard let enumerator = FileManager.default.enumerator(atPath: path) else { return [] }
    var files: [String] = []
    while let relative = enumerator.nextObject() as? String {
        let components = relative.split(separator: "/").map(String.init)
        if components.contains(where: skippedDirectories.contains) { continue }
        if relative.hasSuffix(".swift") {
            files.append(normalized((path as NSString).appendingPathComponent(relative)))
        }
    }
    return files.sorted()
}

var format = "text"
var inputs: [String] = []
var arguments = Array(CommandLine.arguments.dropFirst())

while !arguments.isEmpty {
    let argument = arguments.removeFirst()
    if argument == "--format" {
        guard let value = arguments.first, ["text", "sarif", "github"].contains(value) else {
            fail("--format expects 'text', 'sarif' or 'github'")
        }
        format = value
        arguments.removeFirst()
    } else {
        inputs.append(argument)
    }
}

if inputs.isEmpty {
    fail("usage: DuoLint [--format text|sarif|github] <file-or-directory>...")
}

var allFindings: [Finding] = []

for file in inputs.flatMap(swiftFiles) {
    guard let source = try? String(contentsOfFile: file, encoding: .utf8) else {
        fail("cannot read \(file)")
    }
    let tree = Parser.parse(source: source)
    let rules: [Rule] = [
        ScreenBoundsRule(file: file, tree: tree),
        OddGridColumnsRule(file: file, tree: tree),
    ]
    for rule in rules {
        rule.walk(tree)
        allFindings += rule.findings
    }
}

switch format {

    case "github":
    // GitHub workflow command formatı; özel karakterler kaçırılmalı (escape)
    func esc(_ s: String) -> String {
        s.replacingOccurrences(of: "%", with: "%25")
         .replacingOccurrences(of: "\r", with: "%0D")
         .replacingOccurrences(of: "\n", with: "%0A")
    }
    func escProperty(_ s: String) -> String {
        esc(s).replacingOccurrences(of: ":", with: "%3A")
              .replacingOccurrences(of: ",", with: "%2C")
    }
    for f in allFindings {
        print("::warning file=\(escProperty(f.file)),line=\(f.line),col=\(f.column),title=\(escProperty(f.rule))::\(esc(f.message))")
    }
    
case "sarif":
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(makeSarif(allFindings))
    print(String(decoding: data, as: UTF8.self))
default:
    for f in allFindings {
        print("\(f.file):\(f.line):\(f.column): warning: [\(f.rule)] \(f.message)")
    }
}

exit(allFindings.isEmpty ? 0 : 1)
