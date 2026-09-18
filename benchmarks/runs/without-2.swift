import SwiftUI

struct PhotoGridView: View {
    let photos: [String]

    private let spacing: CGFloat = 8

    // Adaptive columns: the column count follows the actual container width,
    // so the grid reflows when iPhone Duo switches between the outer display
    // and the unfolded inner display (and in any resized/multitasking scene).
    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 110, maximum: 200), spacing: spacing)]
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: spacing) {
                ForEach(photos, id: \.self) { photo in
                    // Size comes from the grid cell, never from UIScreen.main.bounds,
                    // which is stale/wrong when the active display changes.
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