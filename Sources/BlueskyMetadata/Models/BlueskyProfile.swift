//
//  BlueskyProfile.swift
//  BlueskyMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A Bluesky actor's public profile.
///
/// Fetched from the AT Protocol public API (`app.bsky.actor.getProfile`) without
/// authentication.
///
/// ```swift
/// let profile = try await BlueskyMetadata.profile("bsky.app")
/// print("\(profile.displayName ?? profile.handle) — \(profile.followersCount ?? 0) followers")
/// ```
public struct BlueskyProfile: Sendable, Identifiable {

    /// The actor's decentralised identifier (e.g. `did:plc:…`). Also the ``id``.
    public let did: String

    /// The actor's handle (e.g. `bsky.app`).
    public let handle: String

    /// The actor's display name, if set.
    public let displayName: String?

    /// The actor's profile description / bio, if set.
    public let description: String?

    /// A URL to the actor's avatar image, if set.
    public let avatar: String?

    /// A URL to the actor's banner image, if set.
    public let banner: String?

    /// The number of accounts following this actor.
    public let followersCount: Int?

    /// The number of accounts this actor follows.
    public let followsCount: Int?

    /// The number of posts this actor has published.
    public let postsCount: Int?

    /// When the account was created, if parseable.
    public let createdAt: Date?

    /// The stable identifier for this profile (the actor's DID).
    public var id: String { did }

    /// The canonical `bsky.app` web URL for this profile.
    public var bskyURL: String {
        "https://bsky.app/profile/\(handle)"
    }

    /// Creates a Bluesky profile.
    public init(
        did: String,
        handle: String,
        displayName: String?,
        description: String?,
        avatar: String?,
        banner: String?,
        followersCount: Int?,
        followsCount: Int?,
        postsCount: Int?,
        createdAt: Date?
    ) {
        self.did = did
        self.handle = handle
        self.displayName = displayName
        self.description = description
        self.avatar = avatar
        self.banner = banner
        self.followersCount = followersCount
        self.followsCount = followsCount
        self.postsCount = postsCount
        self.createdAt = createdAt
    }
}
