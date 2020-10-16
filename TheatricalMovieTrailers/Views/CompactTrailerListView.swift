//
//  TrailerListView.swift
//  TheatricalMovieTrailers
//
//  Created by Chris on 26.06.20.
//

import SwiftUI

struct CompactTrailerListView: View {
    enum SortingMode: String {
        case TitleAscending = "Title (A-Z)"
        case ReleaseAscending = "Release date"
        case ReleaseDescending = "Release (reversed)"
        
        func nextMode() -> SortingMode {
            switch self {
            case .TitleAscending:
                return .ReleaseAscending
            case .ReleaseAscending:
                return .ReleaseDescending
            default:
                return .TitleAscending
            }
        }
        
        var predicate: ((MovieInfo, MovieInfo) -> Bool) {
            get {
                switch self {
                case .ReleaseAscending:
                    return {
                        if let r0 = $0.releaseDate, let r1 = $1.releaseDate {
                            return r0 < r1
                        } else {
                            return $0.title < $1.title
                        }
                    }
                case .ReleaseDescending:
                    return {
                        if let r0 = $0.releaseDate, let r1 = $1.releaseDate {
                            return r0 > r1
                        } else {
                            return $0.title < $1.title
                        }
                    }
                default:
                    return {
                        return $0.title < $1.title
                    }
                }
            }
        }
    }
    
    @Binding var model: [MovieInfo]
    @Binding var settingsShown: Bool
    @State var sortingMode = SortingMode.ReleaseAscending
    
    var body: some View {
        GeometryReader { geo in
            NavigationView {
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVStack(alignment: .leading) {
                        ForEach(model) { model in
                            MovieTrailerView(model: .constant(model))
                                .frame(width: geo.size.width * 0.95)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(geo.size.width * 0.07)
                                .padding([.leading, .bottom], geo.size.width * 0.025)
                        }
                    }
                    .navigationTitle("Theatrical Trailers")
                    .navigationBarItems(leading:
                        Button(action: {
                            let nextMode = sortingMode.nextMode()
                            DispatchQueue.global(qos: .userInteractive).async {
                                let sortedModel = model.sorted(by: nextMode.predicate)
                                DispatchQueue.main.async {
                                    sortingMode = nextMode
                                    model = sortedModel
                                }
                            }
                        }, label: {
                            HStack {
                                Image(systemName: "arrow.up.arrow.down")
                                Text(sortingMode.rawValue)
                            }
                        }), trailing:
                            Button(action: {
                                settingsShown = true
                            }, label: {
                                Image(systemName: "gearshape")
                                    .clipShape(Rectangle())
                                    .accessibility(label: Text("Settings"))
                            })
                    )
                }
            }
        }
        .sheet(isPresented: $settingsShown, content: {
            SettingsView(isPresented: $settingsShown)
        })
    }
}

#if DEBUG
struct CompactTrailerListView_Previews: PreviewProvider {
    static var previews: some View {
        CompactTrailerListView(model: .constant([MovieInfo.Example.AQuietPlaceII, MovieInfo.Example.AQuietPlaceII]), settingsShown: .constant(false))
            .colorScheme(.dark)
            .background(Color.black)
    }
}
#endif
