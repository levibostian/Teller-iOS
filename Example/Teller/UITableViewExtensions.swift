import Foundation
import UIKit

extension UITableView {
    var showFooter: Bool {
        set {
            tableFooterView?.isHidden = !newValue
        }
        get {
            guard let footerView = tableFooterView else {
                return false
            }

            return !footerView.isHidden
        }
    }
}
