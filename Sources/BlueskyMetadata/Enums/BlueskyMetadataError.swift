//
//  BlueskyMetadataError.swift
//  BlueskyMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Errors that can occur when fetching Bluesky posts, threads, and profiles.
///
/// ```swift
/// do {
///     let profile = try await BlueskyMetadata.profile("bsky.app")
/// } catch BlueskyMetadataError.notFound {
///     print("No such post or profile")
/// } catch {
///     print(error.localizedDescription)
/// }
/// ```
public enum BlueskyMetadataError: Error, LocalizedError, Equatable, Sendable {

    /// The provided string is not a valid Bluesky post URL, `at://` URI, handle, or DID.
    case invalidInput

    /// The post, thread, or profile does not exist (or could not be resolved).
    case notFound

    /// The AT Protocol public API is rate-limiting requests from this IP (`429`).
    case rateLimited

    /// The API returned an error payload.
    case apiError(String)

    /// A network request failed.
    case networkError(String)

    /// Failed to parse the response data.
    case parsingError(String)

    public var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "Invalid Bluesky input. Provide a bsky.app post URL, an at:// URI, or a handle/DID."
        case .notFound:
            return "The requested Bluesky post or profile was not found."
        case .rateLimited:
            return "Bluesky is rate-limiting requests. Try again later."
        case .apiError(let message):
            return "Bluesky API error: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .parsingError(let message):
            return "Parsing error: \(message)"
        }
    }
}
