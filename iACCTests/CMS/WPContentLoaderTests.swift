//	
// Copyright © 2021 Essential Developer. All rights reserved.
//

import XCTest
@testable import iACC

class WPContentLoaderTests: XCTestCase {
    func test_fetchPosts_fetchesAllPosts() throws {
        let sut = WPContentLoader(client: MockConentClient())

        let exp = XCTestExpectation(description: "failed to fetch posts.")
        sut.fetchPosts { result in
            switch result {
            case .success(let posts):
                XCTAssertEqual(posts.count, 7)
                XCTAssertEqual(posts.first?.id, 58)
                XCTAssertEqual(posts.first?.htmlString, "Hello Test\n\n\n<p></p>\n")
            case .failure(let error): XCTFail(error.localizedDescription)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }

    func test_fetchPostWithID_fetchesTheCorrectPost() {
        let sut = WPContentLoader(client: MockConentClient(fileName: "wordpress-post"))

        let exp = XCTestExpectation(description: "failed to fetch posts.")
        sut.fetchPost(withID: "58") { result in
            switch result {
            case .success(let post):
                XCTAssertEqual(post.id, 58)
                XCTAssertEqual(post.htmlString, "Hello Test\n\n\n<p></p>\n")
            case .failure(let error): XCTFail(error.localizedDescription)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1)
    }

    // todo: fetch image
    // todo: try with drupal (when you get it working first)
}

struct ContentPost: Identifiable, Decodable {
    var id: Int
    var htmlString: String
}

protocol ContentLoader {
    typealias ContentListResult = (Result<[ContentPost], Error>) -> Void
    typealias ContentPostResult = (Result<ContentPost, Error>) -> Void
    func fetchPosts(_ completion: @escaping ContentListResult)
    func fetchPost(withID id: String, completion: @escaping ContentPostResult)
}

// WordPress Module

extension ContentPost {
    init(post: Post) {
        id = post.id
        htmlString = post.content?.rendered ?? ""
    }
}

struct WPContentLoader: ContentLoader {
    // Could also be called an adapter
    let client: ContentClient

    func fetchPosts(_ completion: @escaping ContentListResult) {
        guard let url = URL(string: "https://wordpress.devs.rnd.live.backbaseservices.com/wp-json/wp/v2/posts") else {
            completion(.failure(ClientError.invalidUrl))
            return
        }

        client.data(url: url, headers: nil) { result in
            let parsed: Result<[Post], Error> = parse(result)
            switch parsed {
            case .success(let posts):
                let contentPosts = posts.map { post in ContentPost(post: post) }
                completion(.success(contentPosts))
            case .failure(let error): completion(.failure(error))
            }
        }
    }

    func fetchPost(withID id: String, completion: @escaping ContentPostResult) {
        guard let url = URL(string: "https://wordpress.devs.rnd.live.backbaseservices.com/wp-json/wp/v2/posts/\(id)") else {
            completion(.failure(ClientError.invalidUrl))
            return
        }

        client.data(url: url, headers: nil) { result in
            let parsed: Result<Post, Error> = parse(result)
            switch parsed {
            case .success(let post): completion(.success(ContentPost(post: post)))
            case .failure(let error): completion(.failure(error))
            }
        }
    }

    func parse<T: Decodable>(_ result: Result<Data, Error>) -> Result<T, Error> {
        switch result {
        case .success(let data):
            do {
                let object = try JSONDecoder().decode(T.self, from: data)
                return Result.success(object)
            } catch {
                return Result.failure(error)
            }
        case .failure(let error): return Result.failure(error)
        }
    }
}

// Client Module

protocol ContentClient {
    func data(url: URL, headers: [String: String]?, _ completion: @escaping (Result<Data, Error>) -> Void)
}

enum TestError: Error {
    case failedToReadFile
}

struct MockConentClient: ContentClient {
    var fileName = "wordpress-posts"

    func data(
        url: URL,
        headers: [String: String]? = nil,
        _ completion: @escaping (Result<Data, Error>) -> Void) {

        guard let data = readLocalFile(forName: fileName) else {
            completion(.failure(TestError.failedToReadFile))
            return
        }
        completion(.success(data))
    }

    private func readLocalFile(forName name: String) -> Data? {
        do {
            for bundle in Bundle.allBundles {
                if let bundlePath = bundle.path(forResource: name, ofType: "json"),
                    let jsonData = try String(contentsOfFile: bundlePath).data(using: .utf8) {

                    return jsonData
                }
            }
        } catch {
            print(error)
        }
        return nil
    }
}
