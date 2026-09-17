import Foundation
import SwiftSyntax
import SwiftParser

struct Finding {
    let file: String
    let line: Int
    let rule: String
    let message: String
}

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
        findings.append(Finding(file: file, line: loc.line, rule: rule, message: message))
    }
}

// Kural 1: UIScreen.main.bounds
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

// Kural 2: tek sayılı (3, 5, 7...) GridItem kolonları
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

    // [GridItem(...), GridItem(...), GridItem(...)]
    override func visit(_ node: ArrayExprSyntax) -> SyntaxVisitorContinueKind {
        let elements = node.elements.map { $0.expression }
        if !elements.isEmpty, elements.allSatisfy(isGridItemCall) {
            reportIfOdd(node, count: elements.count)
        }
        return .visitChildren
    }

    // Array(repeating: GridItem(...), count: 3)
    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard node.calledExpression.trimmedDescription == "Array" else { return .visitChildren }
        let args = Dictionary(uniqueKeysWithValues:
            node.arguments.compactMap { arg in arg.label.map { ($0.text, arg.expression) } })
        if let repeating = args["repeating"], isGridItemCall(repeating),
           let countExpr = args["count"]?.as(IntegerLiteralExprSyntax.self),
           let count = Int(countExpr.literal.text) {
            reportIfOdd(node, count: count)
        }
        return .visitChildren
    }
}

var allFindings: [Finding] = []

for path in CommandLine.arguments.dropFirst() {
    guard let source = try? String(contentsOfFile: path, encoding: .utf8) else {
        FileHandle.standardError.write("error: cannot read \(path)\n".data(using: .utf8)!)
        exit(2)
    }
    let tree = Parser.parse(source: source)
    let rules: [Rule] = [
        ScreenBoundsRule(file: path, tree: tree),
        OddGridColumnsRule(file: path, tree: tree),
    ]
    for rule in rules {
        rule.walk(tree)
        allFindings += rule.findings
    }
}

for f in allFindings {
    print("\(f.file):\(f.line): warning: [\(f.rule)] \(f.message)")
}

exit(allFindings.isEmpty ? 0 : 1)
