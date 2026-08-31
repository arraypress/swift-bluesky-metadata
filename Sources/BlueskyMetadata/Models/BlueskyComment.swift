//
//  BlueskyComment.swift
//  BlueskyMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A single reply in a Bluesky thread, with its own nested replies.
///
/// Fetched from the AT Protocol public API, which returns the reply tree for a
/// post in one request. Each comment carries its ``replies``; use ``flattened``
/// for a depth-first list.
///
/// ```swift
/// let (_, comments) = try await BlueskyMetadata.thread(input)
/// for c in comments.flattened {
///     let indent = String(repeating: "  ", count: c.depth)
///     print("\(indent)\(c.author.handle): \(c.text)")
/// }
/// ```
public struct BlueskyComment: Sendable, Identifiable {

    /// The reply's AT Protocol URI. Also the ``id``.
    public let uri: String

    /// The reply's author.
    public let author: BlueskyAuthor

    /// The reply's text content.
    public let text: String

    /// When the reply was created (from the record), if parseable.
    public let createdAt: Date?

    /// The number of likes.
    public let likeCount: Int

    /// The number of reposts.
    public let repostCount: Int

    /// The number of direct replies, as reported by the server.
    ///
    /// This may exceed ``replies``.count when the thread was fetched with a
    /// limited depth.
    public let replyCount: Int

    /// Nesting depth: `0` for a top-level reply, `1` for a reply to a reply, and so on.
    public let depth: Int

    /// The direct replies to this comment.
    public let replies: [BlueskyComment]

    /// Creates a Bluesky comment.
    public init(
        uri: String,
        author: BlueskyAuthor,
        text: String,
        createdAt: Date?,
        likeCount: Int,
        repostCount: Int,
        replyCount: Int,
        depth: Int,
        replies: [BlueskyComment]
    ) {
        self.uri = uri
        self.author = author
        self.text = text
        self.createdAt = createdAt
        self.likeCount = likeCount
        self.repostCount = repostCount
        self.replyCount = replyCount
        self.depth = depth
        self.replies = replies
    }
}
