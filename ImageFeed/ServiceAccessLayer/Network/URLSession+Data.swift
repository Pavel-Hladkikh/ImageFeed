import Foundation

enum NetworkError: Error {
    case httpStatusCode(Int)
    case urlRequestError(Error)
    case urlSessionError
    case invalidRequest
    case decodingError(Error)
    case invalidResponse
}

extension URLSession {
    func data(
        for request: URLRequest,
        completion: @escaping (Result<Data, Error>) -> Void
    ) -> URLSessionTask {
        let completeOnMain: (Result<Data, Error>) -> Void = { result in
            DispatchQueue.main.async { completion(result) }
        }
        
        let task = dataTask(with: request) { data, response, error in
            if let response = response as? HTTPURLResponse {
                let status = response.statusCode
                if (200..<300).contains(status), let data = data {
                    completeOnMain(.success(data))
                } else {
                    print("[dataTask]: NetworkError httpStatusCode \(status)")
                    completeOnMain(.failure(NetworkError.httpStatusCode(status)))
                }
            } else if let error = error {
                print("[dataTask]: NetworkError urlRequestError \(error.localizedDescription)")
                completeOnMain(.failure(NetworkError.urlRequestError(error)))
            } else {
                print("[dataTask]: NetworkError urlSessionError")
                completeOnMain(.failure(NetworkError.urlSessionError))
            }
        }
        
        return task
    }
    
    func objectTask<T: Decodable>(
        for request: URLRequest,
        completion: @escaping (Result<T, Error>) -> Void
    ) -> URLSessionTask {
        let decoder = JSONDecoder()
        
        let task = data(for: request) { result in
            switch result {
            case .success(let data):
                do {
                    let decoded = try decoder.decode(T.self, from: data)
                    completion(.success(decoded))
                } catch {
                    let raw = String(data: data, encoding: .utf8) ?? "nil"
                    print("[objectTask]: NetworkError decodingError \(error.localizedDescription)\nRaw:\n\(raw)")
                    completion(.failure(NetworkError.decodingError(error))
                    )
                }
            case .failure(let error):
                print("[objectTask]: pass-through error \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
        
        return task
    }
}
