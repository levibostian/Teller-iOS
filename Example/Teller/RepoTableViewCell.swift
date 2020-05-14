import Foundation
import UIKit

class RepoTableViewCell: UITableViewCell {
    @IBOutlet var label: UILabel!

    func populate(repoName: String) {
        label.text = repoName
    }
}
