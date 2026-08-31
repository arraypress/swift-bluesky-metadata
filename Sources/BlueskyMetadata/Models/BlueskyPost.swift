//
//  BlueskyPost.swift
//  BlueskyMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// The author of a Bluesky post or reply.
///
/// Fetched from the AT Protocol public API without authentication.
public struct BlueskyAuthor: Sendable, Identifiable, Equatable {

    /// The author's decentralised identifier (e.g. `did:plc:…`). Also the ``id``.
    public let did: String

    /// The author's handle (e.g. `bsky.app`).
    public let handle: String

    /// The author's display name, if set.
    public let displayName: String?

    /// A URL to the author's avatar image, if set.
    public let avatar: String?

    /// Creates a Bluesky author.
    public init(
        did: String,
        handle: String,
        displayName: String?,
        avatar: String?
    ) {
        self.did = did
        self.handle = handle
        self.displayName = displayName
        self.avatar = avatar
    }
}

/// A Bluesky post — the root of a thread returned by ``BlueskyMetadata/thread(_:)``.
///
/// Fetched from the AT Protocol public API (`public.api.bsky.app`) without
/// authentication. The nested replies are exposed separately as a
/// ``BlueskyComment`` tree.
///
/// ```swift
/// let (post, comments) = try await BlueskyMetadata.thread(
///     "https://bsky.app/profile/bsky.app/post/3l6oveex3ii2l"
/// )
/// print("\(post.author.handle): \(post.text)")
/// print("\(post.likeCount) likes · \(comments.totalCount) replies")
/// ```
public struct BlueskyPost: Sendable, Identifiable {

    /// The post's AT Protocol URI (e.g. `at://did:plc:…/app.bsky.feed.post/<rkey>`). Also the ``id``.
    public let uri: String

    /// The post's content identifier (CID).
    public let cid: String

    /// The post's author.
    public let author: BlueskyAuthor

    /// The post's text content.
    public let text: String

    /// When the post was created (from the record), if parseable.
    public let createdAt: Date?

    /// When the post was indexed by the AppView, if parseable.
    public let indexedAt: Date?

    /// The number of direct replies, as reported by the server.
    public let replyCount: Int

    /// The number of reposts.
    public let repostCount: Int

    /// The number of likes.
    public let likeCount: Int

    /// The number of quote posts.
    public let quoteCount: Int

    /// Creates a Bluesky post.
    public init(
        uri: String,
        cid: String,
        author: BlueskyAuthor,
        text: String,
        createdAt: Date?,
        indexedAt: Date?,
        replyCount: Int,
        repostCount: Int,
        likeCount: Int,
        quoteCount: Int
    ) {
        self.uri = uri
        self.cid = cid
        self.author = author
        self.text = text
        self.createdAt = createdAt
        self.indexedAt = indexedAt
        self.replyCount = replyCount
        self.repostCount = repostCount
        self.likeCount = likeCount
        self.quoteCount = quoteCount
    }
}
