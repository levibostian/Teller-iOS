import Foundation
@testable import Teller

internal class RepositoryRequirementsForTesting: RepositoryRequirements, Equatable {
    var tag: RepositoryRequirements.Tag {
        return "Testing \(foo)"
    }

    let foo: String

    init(foo: String = "") {
        self.foo = foo
    }

    static func == (lhs: RepositoryRequirementsForTesting, rhs: RepositoryRequirementsForTesting) -> Bool {
        return lhs.foo == rhs.foo
    }
}
