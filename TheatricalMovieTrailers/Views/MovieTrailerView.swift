//
//  MovieDetailsView.swift
//  TheatricalMovieTrailers
//
//  Created by Chris on 26.06.20.
//

import AVKit
import SwiftUI

struct MovieTrailerView: View {
    @Binding var model: MovieInfo!
    @ObservedObject var appDelegate: AppDelegate
    @State var isPlaying: Bool
    
    @State var avPlayer: AVPlayer? = nil
    
    init(model: Binding<MovieInfo?>) {
        self.appDelegate = UIApplication.shared.delegate as! AppDelegate
        self._model = model
        self._isPlaying = State<Bool>(initialValue: (UIApplication.shared.delegate as! AppDelegate).isPlaying)
        if !appDelegate.isExternalScreenConnected, let url = URL(string: model.wrappedValue!.trailerURL) {
            let avPlayer: AVPlayer? = AVPlayer(url: url)
            self._avPlayer = State<AVPlayer?>(initialValue: avPlayer)
        } else {
            avPlayer = nil
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .leading) {
                TrailerMetaView(model: $model, largeTitle: false)
                    .padding([.leading, .trailing])
                
                VStack(alignment: .center) {
                    HStack {
                        // poster image
                        if let maybe = appDelegate.idsAndImages[model.id], let image = maybe {
                            Spacer()
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }
                        Spacer()
                        // Play/Pause button
                        Button(action: {
                            isPlaying.toggle()
                            appDelegate.isPlaying = isPlaying
                            if isPlaying {
                                appDelegate.selectedTrailerModel = model
                            }
                        }, label: {
                            Image(systemName: isPlaying ? "pause" : "play.fill")
                                .frame(width: 60, height: 60)
                        })
                        .background(Color(UIColor.tertiarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        
                        Spacer()
                    }
                    .frame(width: geo.size.width, height: geo.size.width * (9 / 16), alignment: .center)
                    .onChange(of: model.trailerURL, perform: { url in
                        if !appDelegate.isExternalScreenConnected, let url = URL(string: url) {
                            let avPlayer: AVPlayer? = AVPlayer(url: url)
                            self.avPlayer = avPlayer
                            print("new trailer url \(url)")
                        } else {
                            avPlayer = nil
                        }
                    })
                    .overlay(
                        Group {
                            // Trailer Video if no external screen connected
                            if !appDelegate.isExternalScreenConnected && avPlayer != nil && isPlaying {
                                TrailerPlayerView(avPlayer: .constant(avPlayer!), isPlaying: $isPlaying, avPlayerRateChangeHandler: { (player, change) in
                                    guard let newRate = change.newValue else { return }
                                    appDelegate.isPlaying = newRate > 0
                                })
                                .onDisappear {
                                    isPlaying = false
                                }
                                .frame(width: geo.size.width, height: geo.size.width * (9 / 16), alignment: .center)
                            }
                        }
                    )
                }
                
                MovieMetaView(model: $model)
            }
        }
    }
}

#if DEBUG
struct MovieDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MovieTrailerView(model: .constant(MovieInfo.Example.AQuietPlaceII))
                .colorScheme(.dark)
                .background(Color.black)
                .previewLayout(.sizeThatFits)
            MovieTrailerView(model: .constant(MovieInfo.Example.AQuietPlaceII))
                .colorScheme(.dark)
                .background(Color.black)
                .previewLayout(.fixed(width: 1024, height: 1024))
        }
    }
}
#endif
