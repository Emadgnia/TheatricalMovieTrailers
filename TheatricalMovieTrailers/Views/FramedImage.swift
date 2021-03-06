//
//  FramedImage.swift
//  TheatricalMovieTrailers
//
//  Created by Christoph Parstorfer on 15.10.20.
//

import SwiftUI

struct FramedImage: View {
    private let inset: CGFloat = 16
    @State var uiImage: UIImage
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width - inset/2, height: geo.size.height - inset/2)
                    .clipped()
                Image("blackFrame")
                    .resizable(capInsets: .init(top: inset, leading: inset, bottom: inset, trailing: inset), resizingMode: .tile)
            }
        }
    }
}

struct FramedImage_Previews: PreviewProvider {
    static var previews: some View {
        FramedImage(uiImage: UIImage(named: "moviePosterPlaceholder")!)
            .previewLayout(.fixed(width: 540, height: 840))
    }
}
