import SwiftUI

struct PhotoGridView: View {
    let photos: [String]

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private let spacing: CGFloat = 8

    /// Columns are derived from the space the view actually receives, not from the screen.
    /// On iPhone Duo the available width changes while the app is running
    /// (outer display <-> inner display, fold, rotate, multiple windows),
    /// so adaptive grid items re-flow automatically at layout time.
    private var columns: [GridItem] {
        let minimumCellWidth: CGFloat = horizontalSizeClass == .regular ? 140 : 104
        return [GridItem(.adaptive(minimum: minimumCellWidth), spacing: spacing)]
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: spacing) {
                ForEach(photos, id: \.self) { photo in
                    PhotoCell(name: photo)
                }
            }
            // Padding is applied inside the safe area, so the hinge and
            // camera reserved regions are respected on both displays.
            .padding(.horizontal, spacing)
            .padding(.vertical, spacing)
        }
    }
}

private struct PhotoCell: View {
    let name: String

    var body: some View {
        // The cell's size comes from the grid column; the image fills it
        // without any hardcoded width or screen-based math.
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                Image(name)
                    .resizable()
                    .scaledToFill()
            }
            .clipped()
            .contentShape(Rectangle())
    }
}