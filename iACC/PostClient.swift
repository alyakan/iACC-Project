//	
// Copyright © 2021 Essential Developer. All rights reserved.
//

import Foundation

enum ClientError: String, Error {
    case invalidUrl = "URL provided is invalid."
    case missingData = "No data found in the response."
    case invalidStatusCode = "Received a status code other than 200."
}

struct PostContent: Decodable {
    let protected: Bool
    let rendered: String
}

struct Post: Identifiable, Decodable {
    let id: Int
    let slug: String
    var link: URL?
    let content: PostContent
    let publishedDate: String

    enum CodingKeys: String, CodingKey {
        case id, slug, link, content
        case publishedDate = "date_gmt"
        //        case imageURL = "jetpack_featured_media_url"
    }
}

class URLSessionClient {
    func data(url: URL, _ completion: @escaping (Result<Data, Error>) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in

            if let error = error {
                print("Error:::\(error)")
                completion(.failure(error))
                return
            }

            if let httpResponse = (response as? HTTPURLResponse), httpResponse.statusCode != 200 {
                print("Error:::Received an invalid status Code \(httpResponse.statusCode)")
                completion(.failure(ClientError.invalidStatusCode))
                return
            }

            guard let data = data else {
                print("Error:::Couldn't find data")
                completion(.failure(ClientError.missingData))
                return
            }

            completion(.success(data))

        }.resume()
    }
}

class PostClient {
    func posts(_ completion: @escaping (Result<[Post], Error>) -> Void) {
        // post #37
        guard let url = URL(string: "https://wordpress.devs.rnd.live.backbaseservices.com/wp-json/wp/v2/posts") else {
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
                    let results = try JSONDecoder().decode([Post].self, from: data)
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

    func post(withID id: Int, completion: @escaping (Result<Post, Error>) -> Void) {
        guard let url = URL(string: "https://wordpress.devs.rnd.live.backbaseservices.com/wp-json/wp/v2/posts/\(id)") else {
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
                    let results = try JSONDecoder().decode(Post.self, from: data)
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

extension ItemViewModel {
    init(post: Post, selection: @escaping (() -> Void) = {}) {
        title = post.content.rendered
        subtitle = post.publishedDate
        select = selection
        let data = Data(title.utf8)
        if let attributedString = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) {
            self.attributedString = attributedString
        }
    }
}

struct PostListItemsService: ItemsService {
    let client = PostClient()
    let select: (Post) -> Void
    func loadItems(completion: @escaping (Result<[ItemViewModel], Error>) -> Void) {
        client.posts { result in
            DispatchQueue.mainAsyncIfNeeded {
                completion(result.map({ items in
                    items.map { item in
                        ItemViewModel(post: item) {
                            select(item)
                        }
                    }
                }))
            }
        }
    }
}

extension ListViewController {
    func select(post: Post) {
        let vc = WebViewController()
        vc.post = post
        show(vc, sender: self)
    }
}

