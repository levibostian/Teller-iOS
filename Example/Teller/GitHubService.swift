import Foundation
import Moya

enum GitHubService {
    case listRepos(user: String)
}

extension GitHubService: TargetType {
    var baseURL: URL { return URL(string: "https://api.github.com")! }

    var path: String {
        switch self {
        case .listRepos(let user):
            return "/users/\(user)/repos"
        }
    }

    var method: Moya.Method {
        switch self {
        case .listRepos:
            return .get
        }
    }

    var task: Task {
        switch self {
        case .listRepos:
            return .requestPlain
        }
    }

    var sampleData: Data {
        switch self {
        case .listRepos:
            return Data()
        }
    }

    var headers: [String: String]? {
        return ["Content-type": "application/json"]
    }
}
