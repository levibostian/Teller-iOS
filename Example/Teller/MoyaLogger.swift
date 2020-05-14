import Foundation
import Moya

class HttpLoggerMoyaPlugin: PluginType {
    fileprivate let ignoreHeaderKeys: [String] = ["Authorization"]

    func willSend(_ request: RequestType, target: TargetType) {
        var reqBody: String?
        if let body = request.request!.httpBody {
            reqBody = String(decoding: body, as: UTF8.self)
        }
        print("Http request-- method: \(request.request!.httpMethod!), url: \(request.request!.url!.absoluteString), req body: \(reqBody ?? "(none)")")
    }

    func didReceive(_ result: Result<Response, MoyaError>, target: TargetType) {
        switch result {
        case .success(let response):
            let method = response.request!.httpMethod!
            let url = response.request!.url!.absoluteString
            let reqHeaders = response.request!.allHTTPHeaderFields?.description
            let resHeaders = response.response?.allHeaderFields.description
            let resBody = String(decoding: response.data, as: UTF8.self)
            let statusCode = response.statusCode

            if statusCode >= 200, statusCode < 300 {
                print("Http response success-- method: \(method), url: \(url), code: \(response.statusCode)")
            } else {
                print("Http Response Failed! method: \(method), url: \(url), code: \(response.statusCode), req headers: \(reqHeaders ?? "(none)"), res headers: \(resHeaders ?? "(none)"), res body: \(resBody ?? "(none)")")
            }
        case .failure(let error):
            print(error.localizedDescription)
        }
    }
}

private extension HttpLoggerMoyaPlugin {
    func logNetworkRequest(_ request: URLRequest?, target: TargetType) -> String {
        var output = "Request \(target.method) \(target.path): "

        if let headers = request?.allHTTPHeaderFields {
            output += "Headers: "
            headers.forEach { key, value in
                if !ignoreHeaderKeys.contains(key) {
                    output += "\(key):\(value) "
                }
            }
        }

        return output
    }

    func logNetworkResponse(_ response: HTTPURLResponse?, data: Data?, target: TargetType) -> String {
        guard let response = response else {
            return "Response: There is no response body. Target: \(target)."
        }

        var output = "Response \(target.method) \(target.path): Code: \(response.statusCode) "

        // We only want to log response body if failed.
//        if response.statusCode >= 400 {
        if let body = data, let stringBody = String(data: body, encoding: String.Encoding.utf8) {
            output += "Body: \(stringBody)"
        }
//        }

        return output
    }
}
