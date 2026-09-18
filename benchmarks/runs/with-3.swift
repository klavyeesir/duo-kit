import SwiftUI

struct PhotoGridView: View {
    let photos: [String]

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private let spacing: CGFloat = 8

    // Even column counts keep the centre gutter, not a photo, on the fold.
    // Compact width (outer display): 2 columns. Regular width (inner display): 4 columns.
    private var columns: [GridItem] {
        let count = horizontalSizeClass == .regular ? 4 : 2
        return Array(repeating: GridItem(.flexible(), spacing: spacing), count: count)
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: spacing) {
                ForEach(photos, id: \.self) { photo in
                    // Cell size follows the grid column, so it survives fold/unfold resizes.
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
        // TODO(duo): fold/hinge geometry API is not public yet (iOS 27.1 SDK); the centre gutter
        // is assumed to align with the fold. Unverified: no Duo simulator available.
    }
}