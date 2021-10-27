//	
// Copyright © 2021 Essential Developer. All rights reserved.
//

import UIKit

class ImageViewController: UIViewController {
    
    private lazy var imageView: UIImageView = {
        let iv = UIImageView(frame: .zero)
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.image = UIImage(named: "thisisfine.jpeg")
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = .clear
        return iv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(imageView)
        view.backgroundColor = .white

        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            imageView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor),
            imageView.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor),
            imageView.trailingAnchor.constraint(greaterThanOrEqualTo: view.trailingAnchor),
            imageView.bottomAnchor.constraint(greaterThanOrEqualTo: view.bottomAnchor),
        ])

        MediaClient().media(withID: 5) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let media):
                self.fetchImage(from: media, completion: self.updateImageView)
            case .failure(let error): print("Failed to fetch media. \(error)")
            }
        }
    }

    func fetchImage(
        from mediaPost: MediaPost,
        completion: @escaping (Result<UIImage?, Error>) -> Void) {

        let url = mediaPost.mediaDetails.sizes.full.sourceUrl
        URLSessionClient().data(url: url) { result in
            switch result {
            case.success(let data): completion(.success(UIImage(data: data)))
            case .failure(_): print("Failed to complete image fetching.")
            }
        }
    }

    func handleImageFetchCompletion(_ result: Result<Data, Error>) -> UIImage? {
        switch result {
        case.success(let data): return UIImage(data: data)
        case .failure(_): print("Failed to complete image fetching.")
        }
        return nil
    }

    func updateImageView(with result: Result<UIImage?, Error>) {
        switch result {
        case .success(let image): imageView.image = image
        case .failure: print("Failed to update image view.")
        }
    }
}
