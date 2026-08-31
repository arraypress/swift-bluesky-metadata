//
//  BlueskyComment+Tree.swift
//  BlueskyMetadata
//
//  Created by David Sherlock on 2026.
//
//  The reply tree's derived facts — identity, flattening, counting —
//  kept out of the model file so the shape reads alone.
//

import Foundation

extension BlueskyComment {

    /// The stable identifier for this comment (its AT Protocol URI).
    public var id: String { uri }

    /// Whether this comment has any fetched replies.
    public var hasReplies: Bool { !replies.isEmpty }

    /// The total number of descendant comments beneath this one (fetched).
    public var descendantCount: Int {
        replies.reduce(replies.count) { $0 + $1.descendantCount }
    }

    /// This comment followed by all of its descendants, depth-first.
    public var flattened: [BlueskyComment] {
        [self] + replies.flatMap(\.flattened)
    }
}

// MARK: - Array helpers

public extension Array where Element == BlueskyComment {

    /// All comments in the tree, depth-first (each comment followed by its replies).
    var flattened: [BlueskyComment] {
        flatMap(\.flattened)
    }

    /// The total number of comments in the tree (top-level + all nested replies).
    var totalCount: Int {
        reduce(count) { $0 + $1.descendantCount }
    }
}
