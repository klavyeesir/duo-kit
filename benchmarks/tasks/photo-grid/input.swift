import SwiftUI
import UIKit

struct PhotoGridView: View {
    let photos: [String]
    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(photos, id: \.self) { photo in
                    Image(photo)
                        .resizable()
                        .frame(width: UIScreen.main.bounds.width / 3 - 12, height: 120)
                }
            }
        }
    }
}
