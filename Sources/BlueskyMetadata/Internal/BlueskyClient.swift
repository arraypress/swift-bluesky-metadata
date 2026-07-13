//
//  BlueskyClient.swift
//  BlueskyMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Performs keyless GET requests against the AT Protocol public API.
///
/// All endpoints live under `https://public.api.bsky.app/xrpc/` and require no
/// authentication. Errors are mapped from both HTTP status codes and the
/// `{ "error", "message" }` payloads the XRPC API returns (which often surface
/// "not found" conditions as `400`).
enum BlueskyClient {

    // MARK: - Configuration

    /// The base URL for the AT Protocol public (keyless) API.
    static let host = "https://public.api.bsky.app/xrpc/"

    /// The User-Agent header sent with all requests.
    static let userAgent = "swift-bluesky-metadata/1.0 +https://github.com/arraypress"

    // MARK: - Requests

    /// Performs a GET against an XRPC method and returns the decoded JSON object.
    ///
    /// - Parameters:
    ///   - method: The XRPC method name (e.g. `app.bsky.actor.getProfile`).
    ///   - queryItems: The query parameters for the method.
    /// - Throws: ``BlueskyMetadataError`` mapped from the response.
    /// - Returns: The top-level JSON object.
    static func get(
        _ method: String,
        queryItems: [URLQueryItem]
    ) async throws -> [String: Any] {
        guard var components = URLComponents(string: host + method) else {
            throw BlueskyMetadataError.networkError("Invalid request URL")
        }
        components.queryItems = queryItems
        guard let url = components.url else {
            throw BlueskyMetadataError.networkError("Invalid request URL")
        }

        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw BlueskyMetadataError.networkError(error.localizedDescription)
        }

        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw mapError(status: http.statusCode, data: data)
        }

        guard let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            throw BlueskyMetadataError.parsingError("Invalid JSON response")
        }
        return json
    }

    // MARK: - Error mapping

    /// Maps a non-2xx response to a ``BlueskyMetadataError``.
    ///
    /// The XRPC API returns not-found and unresolvable-handle conditions as
    /// `400 InvalidRequest`, so the payload is inspected as well as the status.
    private static func mapError(status: Int, data: Data) -> BlueskyMetadataError {
        let body = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        let errorName = body?["error"] as? String
        let message = body?["message"] as? String

        if status == 429 || errorName == "RateLimitExceeded" {
            return .rateLimited
        }

        if errorName == "NotFound"
            || message?.localizedCaseInsensitiveContains("not found") == true
            || message?.localizedCaseInsensitiveContains("unable to resolve") == true {
            return .notFound
        }

        return .apiError(message ?? errorName ?? "HTTP \(status)")
    }
}
