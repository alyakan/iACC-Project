//	
// Copyright © 2021 Essential Developer. All rights reserved.
//

import XCTest
@testable import iACC

class WPContentLoaderTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

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
}

struct ContentPost: Identifiable, Decodable {
    var id: Int
    var htmlString: String
}

protocol ContentLoader {
    func fetchPosts(_ completion: @escaping (Result<[ContentPost], Error>) -> Void)
}

// WordPress Module

extension ContentPost {
    init(post: Post) {
        id = post.id
        htmlString = post.content?.rendered ?? ""
    }
}

struct WPContentLoader: ContentLoader {
    let client: ContentClient
    func fetchPosts(_ completion: @escaping (Result<[ContentPost], Error>) -> Void) {
        guard let url = URL(string: "https://wordpress.devs.rnd.live.backbaseservices.com/wp-json/wp/v2/posts") else {
            completion(.failure(ClientError.invalidUrl))
            return
        }

        client.data(url: url, headers: nil) { result in
            switch result {
            case .success(let data):
                do {
                    let posts = try JSONDecoder().decode([Post].self, from: data)
                    let contentPosts = posts.map { post in
                        ContentPost(post: post)
                    }
                    completion(.success(contentPosts))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error): completion(.failure(error))
            }
        }
    }

    func parse<T: Decodable>(result: Result<Data, Error>) -> Result<T, Error> {
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
    func data(
        url: URL,
        headers: [String: String]? = nil,
        _ completion: @escaping (Result<Data, Error>) -> Void) {

        guard let data = readLocalFile(forName: "wordpress-posts") else {
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
