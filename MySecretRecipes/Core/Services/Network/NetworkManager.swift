//
//  NetworkManager.swift
//  MySecretRecipes
//
//  Created by Yehonatan Yehudai on 05/11/2024.
//

import Foundation

enum NetworkError: Error {
    case general(Error)
    case url(String)
    case connectivity
    case responseDisposition(String)
    case httpStatus(String)
    case decode(String)
}

enum HTTPMethod: String {
    case get = "GET"
}

protocol NetworkManagerProtocol {
    func request<T: Decodable>(_ method: HTTPMethod, path: String, successType: T.Type) async -> Result<T, NetworkError>
}

class NetworkManager: NetworkManagerProtocol {

    static func createRequest(_ method: HTTPMethod, url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = 20
        request.allHTTPHeaderFields = [
            "accept": "application/json",
        ]
        return request
    }

    func request<T: Decodable>(_ method: HTTPMethod, path: String, successType: T.Type) async -> Result<T, NetworkError> {
        guard let url = URL(string: path) else {
            return .failure(.url(path))
        }

        let request = Self.createRequest(method, url: url)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.responseDisposition(URLError(.badServerResponse).localizedDescription))
            }

            switch httpResponse.statusCode {
                case 200:
                    do {
                        let result = try JsonParser.decoder.decode(T.self, from: data)
                        return .success(result)
                    } catch {
                        return .failure(.decode("\(error.localizedDescription)"))
                    }

                default:
                    return .failure(.httpStatus("\(httpResponse.statusCode):\(httpResponse.description)"))
            }
        } catch {
            return .failure(.general(error))
        }
    }
}
