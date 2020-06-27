//
//  TrailerModel.swift
//  MovieTrailers
//
//  Created by Chris on 25.06.20.
//

import Foundation

struct MovieInfo: Identifiable, Hashable {
    let id: Int
    
    let title: String
    let posterURL: String
    let trailerURL: String
    let trailerLength: String
    let synopsis: String
    
    let studio: String
    let director: String
    let actors: [String]
    let genres: [String]
    let releaseDate: String
    let copyright: String
    
    #if DEBUG
    struct Example {
        static let AQuietPlaceII = MovieInfo(
            id: 21837,
            title: "A Quiet Place Part II",
            posterURL: "http://trailers.apple.com/trailers/paramount/a-quiet-place-part-ii/images/poster-xlarge.jpg",
            trailerURL: "https://trailers.apple.com/movies/paramount/a-quiet-place-part-2/a-quiet-place-part-2-trailer-2_a720p.m4v",
            trailerLength: "2:37",
            synopsis:
                """
                Following the deadly events at home, the Abbott family (Emily Blunt, Millicent Simmonds, Noah Jupe) must now face the terrors of the outside world as they continue their fight for survival in silence. Forced to venture into the unknown, they quickly realize that the creatures that hunt by sound are not the only threats that lurk beyond the sand path.
                """,
            studio: "Paramount Pictures",
            director: "John Krasinski",
            actors: ["Emily Blunt", "Cillian Murphy", "Millicent Simmonds", "Noah Jupe", "Djimon Hounsou"],
            genres: ["Horror", "Thriller"],
            releaseDate: "2020-09-04",
            copyright: "© Copyright 2020 Paramount Pictures"
        )
    }
    #endif
}

// MARK: - Load Movie Info from XML & URL

extension MovieInfo {
    static func loadTrailers(loadHighDefinition: Bool = true, parserDelegate: MovieInfoXMLParserDelegate) {
        var urlString: String!
        if loadHighDefinition {
            urlString = "https://trailers.apple.com/trailers/home/xml/current_720p.xml"
        } else {
            urlString = "https://trailers.apple.com/trailers/home/xml/current.xml"
        }
        let url = URL(string: urlString)!
        loadFromURL(url, parserDelegate: parserDelegate)
    }
    
    private static func loadFromURL(_ url: URL, parserDelegate: MovieInfoXMLParserDelegate) {
        DispatchQueue.global(qos: .userInitiated).async {
            if let xmlParser = XMLParser(contentsOf: url) {
                xmlParser.delegate = parserDelegate
                xmlParser.parse()
                // when finished, completion is called by the parser
            } else {
                DispatchQueue.main.async {
                    parserDelegate.completion(nil)
                }
            }
        }
    }
}

fileprivate class MutableMovieInfo {
    enum ExpectedValue {
        case title, posterURL, trailerURL, trailerLength, synopsis, studio, director, actors, genres, releaseDate, copyright, none
    }
    var id = 0
    var title = ""
    var posterURL = ""
    var trailerURL = ""
    var trailerLength = ""
    var synopsis = ""
    
    var studio = ""
    var director = ""
    var actors = [String]()
    var genres = [String]()
    var releaseDate = ""
    var copyright = ""
    
    private var expectedValue: ExpectedValue = .title
    func expectValue(_ expectedValue: ExpectedValue) {
        self.expectedValue = expectedValue
    }
    
    func saveValue(_ value: String) {
        switch expectedValue {
        case .none:
            return
        case .title:
            title = value
        case .posterURL:
            posterURL = value
        case .trailerURL:
            trailerURL = value
        case .trailerLength:
            trailerLength = value
        case .synopsis:
            synopsis += value
            // this is sometimes split into multiple detected strings,
            //  and is followed by the "cast" element (.actors), so keep concatenating
            return
        case .studio:
            studio = value
        case .director:
            director = value
        case .actors:
            actors.append(value)
            return // this is made up of multiple detected strings, so keep appending
        case .genres:
            genres.append(value)
            return // this is made up of multiple detected strings, so keep appending
        case .releaseDate:
            releaseDate = value
        case .copyright:
            copyright = value
        }
        expectedValue = .none
    }
    
    var movieInfo: MovieInfo {
        MovieInfo(id: id, title: title, posterURL: posterURL, trailerURL: trailerURL, trailerLength: trailerLength, synopsis: synopsis, studio: studio, director: director, actors: actors, genres: genres, releaseDate: releaseDate, copyright: copyright)
    }
}

class MovieInfoXMLParserDelegate: NSObject, XMLParserDelegate {
    var completion: (([MovieInfo]?) -> ())!
    // store parsed data
    private var mutableMI = MutableMovieInfo()
    private var resultMI = [MovieInfo]()
    
    init(completion: @escaping (([MovieInfo]?) -> ())) {
        self.completion = completion
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        switch elementName {
        case "movieinfo":
            // new movie entry, save previous one
            resultMI.append(mutableMI.movieInfo)
            mutableMI = MutableMovieInfo()
            mutableMI.id = Int(attributeDict["id"]!)!
        case "title":
            mutableMI.expectValue(.title)
        case "runtime":
            mutableMI.expectValue(.trailerLength)
        case "studio":
            mutableMI.expectValue(.studio)
        case "releasedate":
            mutableMI.expectValue(.releaseDate)
        case "copyright":
            mutableMI.expectValue(.copyright)
        case "director":
            mutableMI.expectValue(.director)
        case "description":
            mutableMI.expectValue(.synopsis)
        case "cast":
            mutableMI.expectValue(.actors)
        case "genre":
            mutableMI.expectValue(.genres)
        case "xlarge":
            mutableMI.expectValue(.posterURL)
        case "large":
            mutableMI.expectValue(.trailerURL)
        case "location": // follows the last "genre" name tag, contains the low res poster link. must skip
            mutableMI.expectValue(.none)
        default:
            // ignored
            return
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        mutableMI.saveValue(string)
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        DispatchQueue.main.async {
            self.completion(Array(self.resultMI.dropFirst()))
            self.completion = nil
        }
    }
}
