import SwiftUI

struct PhotoGridView: View {
    let photos: [String]

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private let spacing: CGFloat = 8

    // Even column counts in both size classes so a gutter, not a photo,
    // lands on the centre line of the container (where the fold sits on
    // the inner display). Branches on size class, never on device identity.
    private var columnCount: Int {
        horizontalSizeClass == .regular ? 4 : 2
    }

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: spacing),
            count: columnCount
        )
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: spacing) {
                ForEach(photos, id: \.self) { photo in
                    // Cell width comes from the grid, so it follows the
                    // container through fold/unfold resizes. No screen
                    // bounds, no cached sizes, no fixed frames.
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

// TODO(duo): No fold/hinge geometry API is verifiable yet (iOS 27.1 SDK not
// public), so the gutter is centred by symmetry rather than by reading the
// fold's actual position. Revisit once the SDK ships.
// NOTE: Unverified on device — no iPhone Duo simulator is available yet.