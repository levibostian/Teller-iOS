import Foundation
import Moya

enum GitHubService {
    case listRepos(user: String, pageNumber: Int)
}

extension GitHubService: TargetType {
    var baseURL: URL { return URL(string: "https://api.github.com")! }

    var path: String {
        switch self {
        case .listRepos(let user, _):
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
        func queryEncoding(_ params: [String: Any]) -> Task {
            return Task.requestParameters(parameters: params, encoding: URLEncoding.default)
        }

        switch self {
        case .listRepos(_, let pageNumber):
            return queryEncoding(["per_page": 50, "page": pageNumber])
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
