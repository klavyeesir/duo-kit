import SwiftUI

struct ReaderView: View {
    @State private var isBookmarked = false
    let article: String

    var body: some View {
        VStack(spacing: 0) {
            ScrollView { Text(article).padding() }
            HStack {
                Button(action: {}) { Image(systemName: "chevron.left") }
                Spacer()
                Button(action: { isBookmarked.toggle() }) {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                }
                Spacer()
                Button(action: {}) { Image(systemName: "textformat.size") }
            }
            .padding()
            .background(.bar)
        }
        .ignoresSafeArea()
        .statusBar(hidden: true)
    }
}
