//	
// Copyright © 2021 Essential Developer. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController {
    var post: Post?

    private lazy var webView: WKWebView = {
        let wv = WKWebView(frame: .zero)
        wv.translatesAutoresizingMaskIntoConstraints = false
        return wv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(webView)
        view.backgroundColor = .white

        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

//        PostClient().post(withID: post?.id ?? 7) { [weak self] result in
//            switch result {
//            case .success(let post):
//                DispatchQueue.mainAsyncIfNeeded {
//                    self?.webView.loadHTMLString(
//                        "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n\(post.content.rendered)",
//                        baseURL: nil)
//                }
//            case.failure(_): print("Failed to fetch post")
//            }
//        }

        DrupalClient().post(withID: 8) { result in
            
        }
    }
}
