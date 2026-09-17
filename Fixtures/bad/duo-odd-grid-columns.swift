import SwiftUI
struct Gallery: View {
    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    let more = Array(repeating: GridItem(.flexible()), count: 5)
    var body: some View { LazyVGrid(columns: columns) { Text("A") } }
}
