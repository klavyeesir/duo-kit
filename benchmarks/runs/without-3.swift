import SwiftUI

struct PhotoGridView: View {
    let photos: [String]

    private let spacing: CGFloat = 8
    private let minCellWidth: CGFloat = 110

    // Adaptive columns: 3 across on the closed outer display,
    // more columns automatically when the inner display is opened.
    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: minCellWidth), spacing: spacing)]
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: spacing) {
                ForEach(photos, id: \.self) { photo in
                    // Size comes from the container, never from UIScreen,
                    // so the grid relayouts live on fold/unfold and resize.
                    Color.clear
                        .aspectRatio(1, contentMode: .fit)
                        .overlay {
                            Image(photo)
                                .resizable()
                                .scaledToFill()
                        }
                        .clipped()
                }
            }
            .padding(.horizontal, spacing)
        }
    }
}