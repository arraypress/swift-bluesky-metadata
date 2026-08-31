//
//  BlueskyProfile+Derived.swift
//  BlueskyMetadata
//
//  Created by David Sherlock on 2026.
//
//  Identity and the profile's derived URL.
//

import Foundation

extension BlueskyProfile {

    /// The stable identifier for this profile (the actor's DID).
    public var id: String { did }

    /// The canonical `bsky.app` web URL for this profile.
    public var bskyURL: String {
        "https://bsky.app/profile/\(handle)"
    }
}
