//
//  BlueskyParser.swift
//  BlueskyMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Parses AT Protocol JSON responses into typed models.
///
/// `getPostThread` returns a `thread` node whose `replies` array recursively
/// contains the reply tree. Nodes that are blocked or not found carry a
/// different `$type` (and no usable `post`), so they are skipped gracefully.
enum BlueskyParser {

    // MARK: - Thread

    /// Parses an `app.bsky.feed.getPostThread` response into a post and reply tree.
    ///
    /// - Parameter data: The raw JSON from the API.
    /// - Throws: ``BlueskyMetadataError/parsingError(_:)`` if malformed, or
    ///   ``BlueskyMetadataError/notFound`` if the thread node is blocked/not found.
    /// - Returns: The root ``BlueskyPost`` and its top-level ``BlueskyComment`` tree.
    static func parseThread(data: Data) throws -> (post: BlueskyPost, comments: [BlueskyComment]) {
        guard let root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              let thread = root["thread"] as? [String: Any] else {
            throw BlueskyMetadataError.parsingError("Invalid Bluesky thread JSON")
        }

        // Blocked / not-found thread nodes have no usable `post`.
        guard let postDict = thread["post"] as? [String: Any] else {
            throw BlueskyMetadataError.notFound
        }

        let post = try parsePost(postDict)
        let comments = parseReplies(thread["replies"], depth: 0)
        return (post, comments)
    }

    /// Parses an `app.bsky.actor.getProfile` response into a ``BlueskyProfile``.
    ///
    /// - Parameter data: The raw JSON from the API.
    /// - Throws: ``BlueskyMetadataError/parsingError(_:)`` if malformed.
    /// - Returns: The parsed ``BlueskyProfile``.
    static func parseProfile(data: Data) throws -> BlueskyProfile {
        guard let node = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              let did = node["did"] as? String,
              let handle = node["handle"] as? String else {
            throw BlueskyMetadataError.parsingError("Invalid Bluesky profile JSON")
        }

        return BlueskyProfile(
            did: did,
            handle: handle,
            displayName: node["displayName"] as? String,
            description: node["description"] as? String,
            avatar: node["avatar"] as? String,
            banner: node["banner"] as? String,
            followersCount: node["followersCount"] as? Int,
            followsCount: node["followsCount"] as? Int,
            postsCount: node["postsCount"] as? Int,
            createdAt: date(from: node["createdAt"])
        )
    }

    // MARK: - Posts & replies

    /// Parses a `post` view (as embedded in a thread node) into a ``BlueskyPost``.
    private static func parsePost(_ node: [String: Any]) throws -> BlueskyPost {
        guard let uri = node["uri"] as? String,
              let authorDict = node["author"] as? [String: Any] else {
            throw BlueskyMetadataError.parsingError("Malformed Bluesky post")
        }
        let record = node["record"] as? [String: Any]

        return BlueskyPost(
            uri: uri,
            cid: node["cid"] as? String ?? "",
            author: parseAuthor(authorDict),
            text: record?["text"] as? String ?? "",
            createdAt: date(from: record?["createdAt"]),
            indexedAt: date(from: node["indexedAt"]),
            replyCount: node["replyCount"] as? Int ?? 0,
            repostCount: node["repostCount"] as? Int ?? 0,
            likeCount: node["likeCount"] as? Int ?? 0,
            quoteCount: node["quoteCount"] as? Int ?? 0
        )
    }

    /// Parses a thread node's `replies` array into a comment tree.
    ///
    /// Blocked / not-found reply nodes (which carry no `post`) are skipped.
    private static func parseReplies(_ value: Any?, depth: Int) -> [BlueskyComment] {
        guard let nodes = value as? [[String: Any]] else { return [] }
        return nodes.compactMap { parseReplyNode($0, depth: depth) }
    }

    /// Parses a single reply node into a ``BlueskyComment``, or `nil` if it is
    /// blocked / not found.
    private static func parseReplyNode(_ node: [String: Any], depth: Int) -> BlueskyComment? {
        guard let post = node["post"] as? [String: Any],
              let uri = post["uri"] as? String,
              let authorDict = post["author"] as? [String: Any] else {
            return nil
        }
        let record = post["record"] as? [String: Any]

        return BlueskyComment(
            uri: uri,
            author: parseAuthor(authorDict),
            text: record?["text"] as? String ?? "",
            createdAt: date(from: record?["createdAt"]),
            likeCount: post["likeCount"] as? Int ?? 0,
            repostCount: post["repostCount"] as? Int ?? 0,
            replyCount: post["replyCount"] as? Int ?? 0,
            depth: depth,
            replies: parseReplies(node["replies"], depth: depth + 1)
        )
    }

    /// Parses an `author` view into a ``BlueskyAuthor``.
    private static func parseAuthor(_ node: [String: Any]) -> BlueskyAuthor {
        BlueskyAuthor(
            did: node["did"] as? String ?? "",
            handle: node["handle"] as? String ?? "",
            displayName: node["displayName"] as? String,
            avatar: node["avatar"] as? String
        )
    }

    // MARK: - Helpers

    /// Parses an ISO-8601 timestamp (with or without fractional seconds).
    ///
    /// Bluesky timestamps typically include fractional seconds
    /// (`2024-10-17T07:06:51.491Z`) but not always, so both forms are tried.
    private static func date(from value: Any?) -> Date? {
        guard let string = value as? String else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: string) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: string)
    }
}
