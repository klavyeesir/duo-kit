import SwiftUI
struct Bar: View {
    var body: some View {
        Text("Content")
            .toolbar {
                ToolbarItem(placement: .navigation) { Button("Back") {} }
                ToolbarItem(placement: .primaryAction) { Button("Share") {} }
            }
    }
}
