import SwiftUI

struct PhotoGridView: View {
    let photos: [String]

    private let spacing: CGFloat = 8
    private let minCellWidth: CGFloat = 110
    private let maxCellWidth: CGFloat = 180

    // Adaptive columns: ~3 columns on the closed outer display,
    // more columns automatically when the inner display is unfolded.
    // No dependency on UIScreen, so the grid reflows live when the
    // window size changes (fold/unfold, rotation, multitasking).
    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: minCellWidth, maximum: maxCellWidth), spacing: spacing)]
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: spacing) {
                ForEach(photos, id: \.self) { photo in
                    Color.clear
                        .aspectRatio(1, contentMode: .fit)
                        .overlay {
                            Image(photo)
                                .resizable()
                                .scaledToFill()
                        }
                        .clipped()
                        .contentShape(Rectangle())
                }
            }
            .padding(.horizontal, spacing)
        }
    }
}