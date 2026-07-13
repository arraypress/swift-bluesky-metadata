//
//  BlueskyURI.swift
//  BlueskyMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Parses Bluesky post inputs into a reference the API can resolve.
///
/// Supported inputs:
/// - `https://bsky.app/profile/<handle-or-did>/post/<rkey>`
/// - A raw AT Protocol URI, e.g. `at://did:plc:…/app.bsky.feed.post/<rkey>`
///   (a handle in the authority position is also accepted).
public enum BlueskyURI {

    // MARK: - Reference

    /// A parsed reference to a Bluesky post.
    public enum Reference: Equatable, Sendable {

        /// An AT Protocol URI ready to pass straight to the API.
        case atURI(String)

        /// A `bsky.app` web post: an actor (handle or DID) plus the record key.
        ///
        /// A handle actor must be resolved to a DID before building the `at://` URI.
        case webPost(actor: String, rkey: String)
    }

    // MARK: - Parsing

    /// Parses a Bluesky post input into a ``Reference``.
    ///
    /// - Parameter input: A `bsky.app` post URL or an `at://` URI.
    /// - Throws: ``BlueskyMetadataError/invalidInput`` if it is neither.
    /// - Returns: The parsed ``Reference``.
    public static func parse(_ input: String) throws -> Reference {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

        // Raw AT Protocol URI.
        if trimmed.hasPrefix("at://") {
            return .atURI(trimmed)
        }

        // bsky.app web post URL: /profile/<actor>/post/<rkey>
        if let match = firstMatch(#"/profile/([^/]+)/post/([^/?#]+)"#, in: trimmed, groups: 2) {
            return .webPost(actor: match[0], rkey: match[1])
        }

        throw BlueskyMetadataError.invalidInput
    }

    /// Builds an `at://` post URI from a DID and record key.
    ///
    /// - Parameters:
    ///   - did: A DID (e.g. `did:plc:…`).
    ///   - rkey: The post record key.
    /// - Returns: `at://<did>/app.bsky.feed.post/<rkey>`.
    public static func postURI(did: String, rkey: String) -> String {
        "at://\(did)/app.bsky.feed.post/\(rkey)"
    }

    /// Whether a string is an AT Protocol DID (`did:method:…`).
    ///
    /// - Parameter value: The candidate actor string.
    /// - Returns: `true` if it looks like a DID.
    public static func isDID(_ value: String) -> Bool {
        value.hasPrefix("did:")
    }

    // MARK: - Helpers

    private static func firstMatch(_ pattern: String, in text: String, groups: Int) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text))
        else { return nil }

        var captures: [String] = []
        for index in 1...groups {
            guard let range = Range(match.range(at: index), in: text) else { return nil }
            captures.append(String(text[range]))
        }
        return captures
    }
}
