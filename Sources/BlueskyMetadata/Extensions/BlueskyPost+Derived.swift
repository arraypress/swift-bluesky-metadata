//
//  BlueskyPost+Derived.swift
//  BlueskyMetadata
//
//  Created by David Sherlock on 2026.
//
//  Identity and the derived URLs for posts and authors, stated in
//  full — each is a one-liner over stored parts.
//

import Foundation

extension BlueskyAuthor {

    /// The stable identifier for this author (their DID).
    public var id: String { did }
}

extension BlueskyPost {

    /// The stable identifier for this post (its AT Protocol URI).
    public var id: String { uri }

    /// The record key (`rkey`) — the last path component of the ``uri``.
    public var rkey: String {
        uri.split(separator: "/").last.map(String.init) ?? ""
    }

    /// The canonical `bsky.app` web URL for this post.
    public var bskyURL: String {
        "https://bsky.app/profile/\(author.did)/post/\(rkey)"
    }
}
