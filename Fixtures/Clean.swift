import SwiftUI
struct V: View {
    var body: some View { GeometryReader { geo in Text("\(geo.size.width)") } }
}
