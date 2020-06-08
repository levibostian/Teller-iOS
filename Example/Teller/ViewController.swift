import RxSwift
import UIKit

class ViewController: UIViewController {
    @IBOutlet var tableView: UITableView!
    private var scrollingManager: ScrollingTableViewManager!

    var repoNames: [String] = []

    let reposViewModel = ReposViewModel()

    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.showFooter = false // hide by default

        scrollingManager = ScrollingTableViewManager(tableView: tableView)
        scrollingManager.delegate = self
        tableView.dataSource = self
        tableView.delegate = self

        reposViewModel.observeRepoNames()
            .subscribe(onNext: { dataState in
                switch dataState.state {
                case .noCache:
                    break
                case .cache(let cache, let cacheAge):
                    if let pagedCache = cache {
                        let repoNames = pagedCache.cache

                        print("number of repos: \(repoNames.count)")

                        self.tableView.showFooter = pagedCache.areMorePages

                        self.repoNames = repoNames
                        self.tableView.reloadData()
                        self.scrollingManager.reloadData()
                    }
                }
            }).disposed(by: disposeBag)

        reposViewModel.setReposToObserve(username: "levibostian")
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource, ScrollingTableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return repoNames.count
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        scrollingManager.tableView(tableView, willDisplay: cell, forRowAt: indexPath)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let repoName = repoNames[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "RepoTableViewCellId") as! RepoTableViewCell

        cell.populate(repoName: repoName)

        return cell
    }

    func reachedBottom(in tableView: UITableView) {
        reposViewModel.gotoNextPageOfRepos()
        print("Going to next page...")
    }
}

protocol ScrollingTableViewDelegate: AnyObject {
    func numberOfSections(in tableView: UITableView) -> Int
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    func reachedBottom(in tableView: UITableView)
}

/**
 Tells you when you scroll to the bottom of the tableview.

 use by
 1. setting delegate
 2. call reloadData() when you call tableView.reloadData()
 3. call `tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)` from your delegate
 */
class ScrollingTableViewManager {
    weak var delegate: ScrollingTableViewDelegate?

    private var alertedReachedBottom = false

    weak var tableView: UITableView?

    init(tableView: UITableView) {
        self.tableView = tableView
    }

    var numberOfRowsInLastSection: Int?
    var numberOfSections: Int?

    func reloadData() {
        if let delegate = self.delegate, let tableView = self.tableView {
            let oldNumberOfSections = numberOfSections
            let oldNumberOfRowsInLastSection = numberOfRowsInLastSection

            let newNumberOfSections = delegate.numberOfSections(in: tableView)
            let newNumberOfRowsInLastSection = delegate.tableView(tableView, numberOfRowsInSection: newNumberOfSections - 1) // zero index the section number

            guard oldNumberOfSections != newNumberOfSections || oldNumberOfRowsInLastSection != newNumberOfRowsInLastSection else {
                return
            }

            numberOfSections = newNumberOfSections
            numberOfRowsInLastSection = newNumberOfRowsInLastSection

            alertedReachedBottom = false // reset
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let numberOfSections = self.numberOfSections, let numberOfRowsInLastSection = self.numberOfRowsInLastSection else {
            fatalError("You forgot to call reloadData()")
        }
        guard let tableView = self.tableView else {
            return
        }

        let isLastSection = indexPath.section == (numberOfSections - 1)
        guard isLastSection else {
            return
        }

        var isCloseToEnd = true
        if numberOfRowsInLastSection > 5 {
            isCloseToEnd = indexPath.row > ((numberOfRowsInLastSection - 1) - 5)
        }

        if isCloseToEnd {
            print("Table close to the end! Current row: \(indexPath.row), number rows in last section: \(numberOfRowsInLastSection)")

            // to prevent spamming the delegate
            if !alertedReachedBottom {
                print("Told delegate reached bottom")
                delegate?.reachedBottom(in: tableView)
                alertedReachedBottom = true
            }
        } else {
            print("Current row: \(indexPath.row), number rows in last section: \(numberOfRowsInLastSection)")
        }
    }
}
