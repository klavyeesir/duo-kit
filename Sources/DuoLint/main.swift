import Foundation
import SwiftSyntax
import SwiftParser

final class ScreenBoundsRule: SyntaxVisitor {
    let file: String
    let converter: SourceLocationConverter

    init(file: String, tree: SourceFileSyntax) {
        self.file = file
        self.converter = SourceLocationConverter(fileName: file, tree: tree)
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        if node.declName.baseName.text == "bounds",
           node.base?.trimmedDescription == "UIScreen.main" {
            let loc = node.startLocation(converter: converter)
            print("\(file):\(loc.line): warning: [duo-screen-bounds] Use GeometryReader / size classes instead of UIScreen.main.bounds")
        }
        return .visitChildren
    }
}

for path in CommandLine.arguments.dropFirst() {
    let source = try String(contentsOfFile: path, encoding: .utf8)
    let tree = Parser.parse(source: source)
    ScreenBoundsRule(file: path, tree: tree).walk(tree)
}
