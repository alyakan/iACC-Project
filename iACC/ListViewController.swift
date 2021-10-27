//
// Copyright © 2021 Essential Developer. All rights reserved.
//

import UIKit

// Strategy Pattern
protocol ItemsService {
    func loadItems(completion: @escaping (Result<[ItemViewModel], Error>) -> Void)
}

class ListViewController: UITableViewController {
    var items = [ItemViewModel]()
    var service: ItemsService? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if tableView.numberOfRows(inSection: 0) == 0 {
            refresh()
        }
    }

    @objc private func refresh() {
        refreshControl?.beginRefreshing()
        service?.loadItems(completion: handleAPIResult)
    }

    private func handleAPIResult(_ result: Result<[ItemViewModel], Error>) {
        switch result {
        case let .success(items):
            self.items = items
            self.refreshControl?.endRefreshing()
            self.tableView.reloadData()
        case let .failure(error):
            showErrorAlert(error)
            self.refreshControl?.endRefreshing()
        }
    }

    private func showErrorAlert(_ error: Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        presenterVC.showDetailViewController(alert, sender: self)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "ItemCell")
        cell.configure(item)
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        item.select()
    }

    func select(friend: Friend) {
        let vc = FriendDetailsViewController()
        vc.friend = friend
        show(vc, sender: self)
    }

    func select(card: Card) {
        let vc = CardDetailsViewController()
        vc.card = card
        show(vc, sender: self)
    }

    func select(transfer: Transfer) {
        let vc = TransferDetailsViewController()
        vc.transfer = transfer
        show(vc, sender: self)
    }

    @objc func addCard() {
        show(AddCardViewController(), sender: self)
    }

    @objc func addFriend() {
        show(AddFriendViewController(), sender: self)
    }

    @objc func sendMoney() {
        show(SendMoneyViewController(), sender: self)
    }

    @objc func requestMoney() {
        show(RequestMoneyViewController(), sender: self)
    }
}

extension UITableViewCell {
    func configure(_ vm: ItemViewModel) {
        if let attributed = vm.attributedString {
            textLabel?.attributedText = attributed
        } else {
            textLabel?.text = vm.title
        }
        detailTextLabel?.text = vm.subtitle
        textLabel?.numberOfLines = 0
        selectionStyle = .none
    }
}
