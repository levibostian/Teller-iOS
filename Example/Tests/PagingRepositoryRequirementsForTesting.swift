import Foundation
@testable import Teller

internal class PagingRepositoryRequirementsForTesting: PagingRepositoryRequirements, Equatable {
    let pageNumber: Int

    init(pageNumber: Int) {
        self.pageNumber = pageNumber
    }

    static func == (lhs: PagingRepositoryRequirementsForTesting, rhs: PagingRepositoryRequirementsForTesting) -> Bool {
        return lhs.pageNumber == rhs.pageNumber
    }
}
