//	
// Copyright © 2021 Essential Developer. All rights reserved.
//

import Foundation

struct DrupalClient {
    func post(withID id: Int, completion: @escaping (Result<Post, Error>) -> Void) {
        guard let url = URL(string: "https://drupal.devs.rnd.live.backbaseservices.com/jsonapi/node/article") else {
            completion(.failure(ClientError.invalidUrl))
            return
        }

        URLSessionClient().data(url: url, headers: ["Accept": "application/vnd.api+json"]) { result in
            switch result {
            case .success(let data):
                do {
                    print("Data:::\(data)")
                    // Parse the JSON data
                    print("Dict:::\(String(data: data, encoding: .utf8)!.convertToDictionary() ?? [:])")
//                    let results = try JSONDecoder().decode(Post.self, from: data)
//                    print("Results:::\(results)")
//                    completion(.success(results))
                } catch {
                    print("Error:::\(error)")
                    completion(.failure(error))
                }
            case .failure(let error): completion(.failure(error))
            }
        }
    }
}

extension String {
    func convertToDictionary() -> [String: Any]? {
        let text = self
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
