//
//  BlueskyMetadata.swift
//  BlueskyMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Fetch Bluesky post threads (comments) and profiles without authentication.
///
/// Uses the AT Protocol public API (`public.api.bsky.app/xrpc`), which returns a
/// post and its entire nested reply tree in a single request. No API key, app
/// password, or login is required.
///
/// ## Quick Start
///
/// ```swift
/// import BlueskyMetadata
///
/// // Root post + full reply (comment) tree in one call
/// let (post, comments) = try await BlueskyMetadata.thread(
///     "https://bsky.app/profile/bsky.app/post/3l6oveex3ii2l"
/// )
///
/// print("\(post.author.handle): \(post.text)")
/// print("\(post.likeCount) likes · \(comments.totalCount) replies")
///
/// for c in comments.flattened {
///     let indent = String(repeating: "  ", count: c.depth)
///     print("\(indent)\(c.author.handle): \(c.text)")
/// }
///
/// // A profile by handle or DID
/// let profile = try await BlueskyMetadata.profile("bsky.app")
/// print("\(profile.displayName ?? profile.handle) — \(profile.followersCount ?? 0) followers")
/// ```
///
/// ## Supported Inputs
///
/// - `https://bsky.app/profile/<handle-or-did>/post/<rkey>` (a handle is resolved
///   to a DID via `com.atproto.identity.resolveHandle`)
/// - A raw `at://<did-or-handle>/app.bsky.feed.post/<rkey>` URI
public enum BlueskyMetadata {

    // MARK: - Public API

    /// Fetches a post **and** its full reply (comment) tree in one request.
    ///
    /// Replies nest via ``BlueskyComment/replies``; use
    /// ``BlueskyComment/flattened`` (or the array's `flattened`) for a
    /// depth-first list with `depth` preserved.
    ///
    /// - Parameters:
    ///   - input: A `bsky.app` post URL or an `at://` post URI.
    ///   - depth: How many levels of replies to fetch (the API caps this).
    /// - Throws: ``BlueskyMetadataError`` if the input is invalid, or the thread
    ///   cannot be retrieved or parsed.
    /// - Returns: The root ``BlueskyPost`` and its top-level ``BlueskyComment`` tree.
    public static func thread(
        _ input: String,
        depth: Int = 6
    ) async throws -> (post: BlueskyPost, comments: [BlueskyComment]) {
        let uri = try await resolvePostURI(input)
        let json = try await BlueskyClient.get(
            "app.bsky.feed.getPostThread",
            queryItems: [
                URLQueryItem(name: "uri", value: uri),
                URLQueryItem(name: "depth", value: String(depth))
            ]
        )
        let data = try JSONSerialization.data(withJSONObject: json)
        return try BlueskyParser.parseThread(data: data)
    }

    /// Fetches only the reply (comment) tree for a post.
    ///
    /// - Parameters:
    ///   - input: A `bsky.app` post URL or an `at://` post URI.
    ///   - depth: How many levels of replies to fetch.
    /// - Returns: The top-level comments, each carrying its nested replies.
    public static func comments(
        _ input: String,
        depth: Int = 6
    ) async throws -> [BlueskyComment] {
        try await thread(input, depth: depth).comments
    }

    /// Fetches a Bluesky actor's public profile.
    ///
    /// - Parameter handleOrDid: A handle (e.g. `bsky.app`) or a DID (e.g. `did:plc:…`).
    /// - Throws: ``BlueskyMetadataError`` if the actor cannot be found or parsed.
    /// - Returns: The ``BlueskyProfile``.
    public static func profile(_ handleOrDid: String) async throws -> BlueskyProfile {
        let actor = handleOrDid.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !actor.isEmpty else { throw BlueskyMetadataError.invalidInput }

        let json = try await BlueskyClient.get(
            "app.bsky.actor.getProfile",
            queryItems: [URLQueryItem(name: "actor", value: actor)]
        )
        let data = try JSONSerialization.data(withJSONObject: json)
        return try BlueskyParser.parseProfile(data: data)
    }

    /// Resolves a Bluesky handle to its DID.
    ///
    /// - Parameter handle: A handle (e.g. `bsky.app`).
    /// - Throws: ``BlueskyMetadataError/notFound`` if the handle cannot be resolved.
    /// - Returns: The resolved DID (e.g. `did:plc:…`).
    public static func resolveHandle(_ handle: String) async throws -> String {
        let json = try await BlueskyClient.get(
            "com.atproto.identity.resolveHandle",
            queryItems: [URLQueryItem(name: "handle", value: handle)]
        )
        guard let did = json["did"] as? String else {
            throw BlueskyMetadataError.notFound
        }
        return did
    }

    // MARK: - Internal

    /// Turns a user-supplied input into an `at://` post URI, resolving a handle
    /// to a DID when necessary.
    private static func resolvePostURI(_ input: String) async throws -> String {
        switch try BlueskyURI.parse(input) {
        case .atURI(let uri):
            return uri
        case .webPost(let actor, let rkey):
            let did = BlueskyURI.isDID(actor) ? actor : try await resolveHandle(actor)
            return BlueskyURI.postURI(did: did, rkey: rkey)
        }
    }
}
