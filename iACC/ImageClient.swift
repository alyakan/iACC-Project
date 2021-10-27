//	
// Copyright © 2021 Essential Developer. All rights reserved.
//

import Foundation

struct MediaPost: Decodable {
    let id: Int
    let slug: String
    var link: URL?
    let publishedDate: String
    let mediaDetails: MediaDetails

    enum CodingKeys: String, CodingKey {
        case id, slug, link
        case publishedDate = "date_gmt"
        case mediaDetails = "media_details"
        //        case imageURL = "jetpack_featured_media_url"
    }

    struct MediaDetails: Decodable {
        let width: Int
        let height: Int
        let sizes: Sizes

        struct Sizes: Decodable {
            let full: Size

            struct Size: Decodable {
                let sourceUrl: URL

                enum CodingKeys: String, CodingKey {
                    case sourceUrl = "source_url"
                }
            }
        }
    }
}

class MediaClient {
    func media(withID id: Int, _ completion: @escaping (Result<MediaPost, Error>) -> Void) {
        // post #37
        guard let url = URL(string: "https://wordpress.devs.rnd.live.backbaseservices.com/wp-json/wp/v2/media/\(id)") else {
            completion(.failure(ClientError.invalidUrl))
            return
        }

        URLSessionClient().data(url: url) { result in
            switch result {
            case .success(let data):
                do {
                    print("Data:::\(data)")
                    // Parse the JSON data
                    print("Dict:::\(Self.convertToDictionary(text: String(data: data, encoding: .utf8)!) ?? [:])")
                    let results = try JSONDecoder().decode(MediaPost.self, from: data)
                    print("Results:::\(results)")
                    completion(.success(results))
                } catch {
                    print("Error:::\(error)")
                    completion(.failure(error))
                }
            case .failure(let error): completion(.failure(error))
            }
        }
    }

    static func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
}
