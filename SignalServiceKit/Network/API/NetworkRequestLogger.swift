//
// Copyright 2024 Signal Messenger, LLC
// SPDX-License-Identifier: AGPL-3.0-only
//

import Foundation

public class NetworkRequestLogger {

    public static let shared = NetworkRequestLogger()

    private init() {}

    // MARK: - Request Logging

    public func logRequest(_ request: TSRequest) {
        let fullURL = request.url.absoluteString

        var logMessage = "🌐 HTTP Request:\n"
        logMessage += "   Method: \(request.method)\n"
        logMessage += "   URL: \(fullURL)\n"

        // Log headers (excluding sensitive ones)
        if !request.headers.headers.isEmpty {
            logMessage += "   Headers:\n"
            for (key, value) in request.headers.headers {
                if isSensitiveHeader(key) {
                    logMessage += "     \(key): [REDACTED]\n"
                } else {
                    logMessage += "     \(key): \(value)\n"
                }
            }
        }

        // Log request body/parameters
        switch request.body {
        case .parameters(let params):
            if !params.isEmpty {
                logMessage += "   Parameters:\n"
                logParameters(params, prefix: "     ", to: &logMessage)
            }
        case .data(let data):
            if !data.isEmpty {
                logMessage += "   Body Data: \(data.count) bytes\n"
                if let bodyString = String(data: data, encoding: .utf8) {
                    logMessage += "   Body Content: \(bodyString)\n"
                }
            }
        }

        Logger.info(logMessage)
    }

    public func logRequest(_ request: URLRequest) {
        guard let url = request.url else { return }

        let fullURL = url.absoluteString

        var logMessage = "🌐 URLRequest:\n"
        logMessage += "   Method: \(request.httpMethod ?? "GET")\n"
        logMessage += "   URL: \(fullURL)\n"

        // Log headers (excluding sensitive ones)
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            logMessage += "   Headers:\n"
            for (key, value) in headers {
                if isSensitiveHeader(key) {
                    logMessage += "     \(key): [REDACTED]\n"
                } else {
                    logMessage += "     \(key): \(value)\n"
                }
            }
        }

        // Log request body
        if let httpBody = request.httpBody, !httpBody.isEmpty {
            logMessage += "   Body Data: \(httpBody.count) bytes\n"
            if let bodyString = String(data: httpBody, encoding: .utf8) {
                logMessage += "   Body Content: \(bodyString)\n"
            }
        }

        Logger.info(logMessage)
    }

    // MARK: - Response Logging

    public func logResponse(_ response: HTTPResponse, for request: TSRequest) {
        let fullURL = request.url.absoluteString

        var logMessage = "✅ HTTP Response:\n"
        logMessage += "   URL: \(fullURL)\n"
        logMessage += "   Status: \(response.responseStatusCode)\n"

        // Log response headers
        if !response.headers.headers.isEmpty {
            logMessage += "   Response Headers:\n"
            for (key, value) in response.headers.headers {
                logMessage += "     \(key): \(value)\n"
            }
        }

        // Log response body as JSON if possible
        if let bodyData = response.responseBodyData, !bodyData.isEmpty {
            logMessage += "   Response Data: \(bodyData.count) bytes\n"

            // Try to parse as JSON for pretty printing
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: bodyData, options: [])
                let prettyData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted])
                if let prettyString = String(data: prettyData, encoding: .utf8) {
                    logMessage += "   Response JSON:\n\(prettyString)\n"
                }
            } catch {
                // If not JSON, just log as string
                if let bodyString = String(data: bodyData, encoding: .utf8) {
                    logMessage += "   Response Content: \(bodyString)\n"
                }
            }
        }

        Logger.info(logMessage)
    }

    public func logResponse(_ response: URLResponse?, data: Data?, for request: URLRequest) {
        guard let httpResponse = response as? HTTPURLResponse,
              let url = request.url else { return }

        let fullURL = url.absoluteString

        var logMessage = "✅ URLResponse:\n"
        logMessage += "   URL: \(fullURL)\n"
        logMessage += "   Status: \(httpResponse.statusCode)\n"

        // Log response headers
        if !httpResponse.allHeaderFields.isEmpty {
            logMessage += "   Response Headers:\n"
            for (key, value) in httpResponse.allHeaderFields {
                logMessage += "     \(key): \(value)\n"
            }
        }

        // Log response body
        if let data = data, !data.isEmpty {
            logMessage += "   Response Data: \(data.count) bytes\n"

            // Try to parse as JSON for pretty printing
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                let prettyData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted])
                if let prettyString = String(data: prettyData, encoding: .utf8) {
                    logMessage += "   Response JSON:\n\(prettyString)\n"
                }
            } catch {
                // If not JSON, just log as string
                if let bodyString = String(data: data, encoding: .utf8) {
                    logMessage += "   Response Content: \(bodyString)\n"
                }
            }
        }

        Logger.info(logMessage)
    }

    // MARK: - Error Logging

    public func logError(_ error: Error, for request: TSRequest) {
        let fullURL = request.url.absoluteString

        var logMessage = "❌ HTTP Error:\n"
        logMessage += "   URL: \(fullURL)\n"
        logMessage += "   Error: \(error)\n"

        // Log additional error details if it's an HTTP error
        if let httpError = error as? OWSHTTPError {
            logMessage += "   HTTP Status: \(httpError.responseStatusCode)\n"

            if let responseData = httpError.responseBodyData {
                logMessage += "   Error Response Data: \(responseData.count) bytes\n"

                // Try to parse error response as JSON
                do {
                    let jsonObject = try JSONSerialization.jsonObject(with: responseData, options: [])
                    let prettyData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted])
                    if let prettyString = String(data: prettyData, encoding: .utf8) {
                        logMessage += "   Error Response JSON:\n\(prettyString)\n"
                    }
                } catch {
                    // If not JSON, just log as string
                    if let bodyString = String(data: responseData, encoding: .utf8) {
                        logMessage += "   Error Response Content: \(bodyString)\n"
                    }
                }
            }
        }

        Logger.error(logMessage)
    }

    public func logError(_ error: Error, for request: URLRequest) {
        guard let url = request.url else { return }

        let fullURL = url.absoluteString

        var logMessage = "❌ URLRequest Error:\n"
        logMessage += "   URL: \(fullURL)\n"
        logMessage += "   Error: \(error)\n"

        // Log additional error details if available
        if let nsError = error as NSError? {
            logMessage += "   Error Code: \(nsError.code)\n"
            logMessage += "   Error Domain: \(nsError.domain)\n"

            if !nsError.userInfo.isEmpty {
                logMessage += "   Error User Info:\n"
                logParameters(nsError.userInfo, prefix: "     ", to: &logMessage)
            }
        }

        Logger.error(logMessage)
    }

    // MARK: - Helper Methods

    private func isSensitiveHeader(_ headerName: String) -> Bool {
        let sensitiveHeaders = [
            "authorization",
            "cookie",
            "set-cookie",
            "x-signal-agent",
            "unidentified-access-key",
            "group-send-token"
        ]
        return sensitiveHeaders.contains(headerName.lowercased())
    }

    private func logParameters(_ params: [String: Any], prefix: String, to logMessage: inout String) {
        for (key, value) in params {
            if let dictValue = value as? [String: Any] {
                logMessage += "\(prefix)\(key):\n"
                logParameters(dictValue, prefix: prefix + "  ", to: &logMessage)
            } else if let arrayValue = value as? [Any] {
                logMessage += "\(prefix)\(key): [\(arrayValue.count) items]\n"
                for (index, item) in arrayValue.enumerated() {
                    if let dictItem = item as? [String: Any] {
                        logMessage += "\(prefix)  [\(index)]:\n"
                        logParameters(dictItem, prefix: prefix + "    ", to: &logMessage)
                    } else {
                        logMessage += "\(prefix)  [\(index)]: \(item)\n"
                    }
                }
            } else {
                // Check if this might be sensitive data
                if isSensitiveParameter(key) {
                    logMessage += "\(prefix)\(key): [REDACTED]\n"
                } else {
                    logMessage += "\(prefix)\(key): \(value)\n"
                }
            }
        }
    }

    private func isSensitiveParameter(_ paramName: String) -> Bool {
        let sensitiveParams = [
            "password",
            "token",
            "auth",
            "key",
            "secret",
            "pin",
            "code",
            "verification"
        ]
        let lowerParam = paramName.lowercased()
        return sensitiveParams.contains { lowerParam.contains($0) }
    }
}
