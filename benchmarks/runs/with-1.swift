import SwiftUI

// NOTE(duo): Not verified on an iPhone Duo simulator or device; none is available yet.
// No Duo-specific dimensions, insets or hinge values are hard-coded here. The layout
// reads its width from the container and branches only on the horizontal size class.

struct PhotoGridView: View {
    let photos: [String]

    @Environment(\.horizontalSizeClass) private var sizeClass

    private let spacing: CGFloat = 8

    // Compact width (e.g. the outer display): keeps the original 3-column design.
    // Regular width (e.g. the open inner display): uses an even column count so the
    // centre gutter, not a photo, lands on the fold.
    //
    // Trade-off: 4 columns in regular width is a design choice, not a Duo requirement.
    // Any layout that keeps a gutter over the fold is equally valid. Change
    // `regularColumnCount` to another even number if you prefer larger or smaller cells.
    private let compactColumnCount = 3
    private let regularColumnCount = 4

    private var columns: [GridItem] {
        let count = sizeClass == .regular ? regularColumnCount : compactColumnCount
        return Array(repeating: GridItem(.flexible(), spacing: spacing), count: count)
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: spacing) {
                ForEach(photos, id: \.self) { photo in
                    // The cell size follows the grid column, not the screen bounds,
                    // so it stays correct across fold/unfold resize events.
                    Color.clear
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(
                            Image(photo)
                                .resizable()
                                .scaledToFill()
                        )
                        .clipped()
                }
            }
            .padding(.horizontal, spacing)
        }
    }
}