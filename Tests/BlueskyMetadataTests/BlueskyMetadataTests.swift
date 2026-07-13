//
//  BlueskyMetadataTests.swift
//  BlueskyMetadata
//
//  Created by David Sherlock on 2026.
//

import XCTest
@testable import BlueskyMetadata

final class BlueskyMetadataTests: XCTestCase {

    // MARK: - Input parsing

    func testParseWebPostURL() throws {
        let ref = try BlueskyURI.parse("https://bsky.app/profile/bsky.app/post/3l6oveex3ii2l")
        XCTAssertEqual(ref, .webPost(actor: "bsky.app", rkey: "3l6oveex3ii2l"))
    }

    func testParseWebPostURLWithDID() throws {
        let ref = try BlueskyURI.parse(
            "https://bsky.app/profile/did:plc:z72i7hdynmk6r22z27h6tvur/post/3l6oveex3ii2l"
        )
        XCTAssertEqual(
            ref,
            .webPost(actor: "did:plc:z72i7hdynmk6r22z27h6tvur", rkey: "3l6oveex3ii2l")
        )
    }

    func testParseRawATURI() throws {
        let uri = "at://did:plc:z72i7hdynmk6r22z27h6tvur/app.bsky.feed.post/3l6oveex3ii2l"
        XCTAssertEqual(try BlueskyURI.parse(uri), .atURI(uri))
    }

    func testParseInvalidThrows() {
        XCTAssertThrowsError(try BlueskyURI.parse("https://example.com/not/a/post"))
    }

    func testPostURIAndDIDDetection() {
        XCTAssertEqual(
            BlueskyURI.postURI(did: "did:plc:abc", rkey: "xyz"),
            "at://did:plc:abc/app.bsky.feed.post/xyz"
        )
        XCTAssertTrue(BlueskyURI.isDID("did:plc:abc"))
        XCTAssertFalse(BlueskyURI.isDID("bsky.app"))
    }

    // MARK: - Thread parsing

    func testParsePostAndComments() throws {
        let (post, comments) = try BlueskyParser.parseThread(data: Data(Fixture.thread.utf8))

        XCTAssertEqual(post.uri, "at://did:plc:root/app.bsky.feed.post/aaa")
        XCTAssertEqual(post.cid, "bafyroot")
        XCTAssertEqual(post.author.handle, "bsky.app")
        XCTAssertEqual(post.author.did, "did:plc:root")
        XCTAssertEqual(post.author.displayName, "Bluesky")
        XCTAssertEqual(post.text, "Hello & welcome to the network")
        XCTAssertEqual(post.likeCount, 63532)
        XCTAssertEqual(post.repostCount, 9533)
        XCTAssertEqual(post.replyCount, 3)
        XCTAssertEqual(post.quoteCount, 704)
        XCTAssertEqual(post.rkey, "aaa")
        XCTAssertEqual(post.bskyURL, "https://bsky.app/profile/did:plc:root/post/aaa")
        XCTAssertNotNil(post.createdAt)          // fractional-seconds ISO-8601
        XCTAssertNotNil(post.indexedAt)

        // Two visible top-level replies (the blocked node is skipped).
        XCTAssertEqual(comments.count, 2)

        let top = comments[0]
        XCTAssertEqual(top.uri, "at://did:plc:alice/app.bsky.feed.post/bbb")
        XCTAssertEqual(top.author.handle, "alice.bsky.social")
        XCTAssertEqual(top.text, "First reply")
        XCTAssertEqual(top.depth, 0)
        XCTAssertEqual(top.likeCount, 12)
        XCTAssertEqual(top.replyCount, 1)
        XCTAssertTrue(top.hasReplies)
        XCTAssertEqual(top.replies.count, 1)

        let nested = top.replies[0]
        XCTAssertEqual(nested.author.handle, "bob.bsky.social")
        XCTAssertEqual(nested.depth, 1)
        XCTAssertNotNil(nested.createdAt)        // plain ISO-8601 (no fractional)
        XCTAssertFalse(nested.hasReplies)

        let second = comments[1]
        XCTAssertEqual(second.author.handle, "carol.bsky.social")
        XCTAssertEqual(second.depth, 0)
    }

    func testBlockedReplyIsSkipped() throws {
        let (_, comments) = try BlueskyParser.parseThread(data: Data(Fixture.thread.utf8))
        XCTAssertFalse(comments.contains { $0.uri.contains("blocked") })
    }

    func testFlattenAndCounts() throws {
        let (_, comments) = try BlueskyParser.parseThread(data: Data(Fixture.thread.utf8))
        XCTAssertEqual(
            comments.flattened.map(\.author.handle),
            ["alice.bsky.social", "bob.bsky.social", "carol.bsky.social"]
        )
        XCTAssertEqual(comments.totalCount, 3)
        XCTAssertEqual(comments[0].descendantCount, 1)
        XCTAssertEqual(comments[0].flattened.count, 2)
    }

    func testNotFoundThreadThrows() {
        let json = #"{ "thread": { "$type": "app.bsky.feed.defs#notFoundPost", "notFound": true } }"#
        XCTAssertThrowsError(try BlueskyParser.parseThread(data: Data(json.utf8))) { error in
            XCTAssertEqual(error as? BlueskyMetadataError, .notFound)
        }
    }

    // MARK: - Profile parsing

    func testParseProfile() throws {
        let profile = try BlueskyParser.parseProfile(data: Data(Fixture.profile.utf8))
        XCTAssertEqual(profile.did, "did:plc:z72i7hdynmk6r22z27h6tvur")
        XCTAssertEqual(profile.handle, "bsky.app")
        XCTAssertEqual(profile.displayName, "Bluesky")
        XCTAssertEqual(profile.description, "official Bluesky account")
        XCTAssertEqual(profile.followersCount, 34071610)
        XCTAssertEqual(profile.followsCount, 11)
        XCTAssertEqual(profile.postsCount, 802)
        XCTAssertNotNil(profile.avatar)
        XCTAssertNotNil(profile.createdAt)
        XCTAssertEqual(profile.bskyURL, "https://bsky.app/profile/bsky.app")
    }

    func testParseProfileMissingRequiredThrows() {
        let json = #"{ "handle": "no-did.bsky.social" }"#
        XCTAssertThrowsError(try BlueskyParser.parseProfile(data: Data(json.utf8)))
    }

    // MARK: - Error descriptions

    func testErrorDescriptions() {
        XCTAssertNotNil(BlueskyMetadataError.invalidInput.errorDescription)
        XCTAssertNotNil(BlueskyMetadataError.notFound.errorDescription)
        XCTAssertNotNil(BlueskyMetadataError.rateLimited.errorDescription)
        XCTAssertEqual(
            BlueskyMetadataError.networkError("boom").errorDescription,
            "Network error: boom"
        )
    }

    // MARK: - Live network tests (opt-in)

    func testLiveThread() async throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["BLUESKY_LIVE_TESTS"] == "1",
            "Set BLUESKY_LIVE_TESTS=1 to run live network tests."
        )
        // Bluesky's pinned "welcome" post — stable, thousands of replies.
        let (post, comments) = try await BlueskyMetadata.thread(
            "https://bsky.app/profile/bsky.app/post/3l6oveex3ii2l"
        )
        XCTAssertEqual(post.author.handle, "bsky.app")
        XCTAssertFalse(post.text.isEmpty)
        XCTAssertFalse(comments.isEmpty)
        XCTAssertTrue(comments.flattened.contains { !$0.text.isEmpty })

        if ProcessInfo.processInfo.environment["BLUESKY_PRINT"] == "1" {
            print("=== \(post.author.handle): \(post.text.prefix(80)) ===")
            print("\(post.likeCount) likes · \(comments.totalCount) fetched replies")
            for c in comments.flattened.prefix(6) {
                let indent = String(repeating: "  ", count: c.depth)
                print("\(indent)\(c.author.handle): \(c.text.prefix(70))")
            }
        }
    }

    func testLiveProfile() async throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["BLUESKY_LIVE_TESTS"] == "1",
            "Set BLUESKY_LIVE_TESTS=1 to run live network tests."
        )
        let profile = try await BlueskyMetadata.profile("bsky.app")
        XCTAssertEqual(profile.handle, "bsky.app")
        XCTAssertEqual(profile.did, "did:plc:z72i7hdynmk6r22z27h6tvur")
        XCTAssertGreaterThan(profile.followersCount ?? 0, 0)

        if ProcessInfo.processInfo.environment["BLUESKY_PRINT"] == "1" {
            print("=== \(profile.displayName ?? profile.handle) (@\(profile.handle)) ===")
            print("\(profile.followersCount ?? 0) followers · \(profile.postsCount ?? 0) posts")
        }
    }

    func testLiveHandleResolution() async throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["BLUESKY_LIVE_TESTS"] == "1",
            "Set BLUESKY_LIVE_TESTS=1 to run live network tests."
        )
        let did = try await BlueskyMetadata.resolveHandle("bsky.app")
        XCTAssertEqual(did, "did:plc:z72i7hdynmk6r22z27h6tvur")
    }
}

// MARK: - Fixture

/// Structurally faithful `getPostThread` and `getProfile` responses.
///
/// Mirrors the real AT Protocol JSON shapes (nested `replies`, a `record` with
/// `text`/`createdAt`, per-post counts) while staying compact. Includes a
/// `blockedPost` reply node to exercise graceful skipping, and mixes
/// fractional and plain ISO-8601 timestamps.
private enum Fixture {
    static let thread = """
    {
      "thread": {
        "$type": "app.bsky.feed.defs#threadViewPost",
        "post": {
          "uri": "at://did:plc:root/app.bsky.feed.post/aaa",
          "cid": "bafyroot",
          "author": {
            "did": "did:plc:root", "handle": "bsky.app",
            "displayName": "Bluesky",
            "avatar": "https://cdn.bsky.app/img/avatar/plain/did:plc:root/x@jpeg"
          },
          "record": {
            "$type": "app.bsky.feed.post",
            "text": "Hello & welcome to the network",
            "createdAt": "2024-10-17T07:06:51.491Z"
          },
          "replyCount": 3, "repostCount": 9533, "likeCount": 63532, "quoteCount": 704,
          "indexedAt": "2024-10-17T07:06:51.491Z"
        },
        "replies": [
          {
            "$type": "app.bsky.feed.defs#threadViewPost",
            "post": {
              "uri": "at://did:plc:alice/app.bsky.feed.post/bbb",
              "cid": "bafyalice",
              "author": { "did": "did:plc:alice", "handle": "alice.bsky.social", "displayName": "Alice" },
              "record": { "text": "First reply", "createdAt": "2024-10-17T08:00:00.123Z" },
              "replyCount": 1, "repostCount": 0, "likeCount": 12, "quoteCount": 0,
              "indexedAt": "2024-10-17T08:00:00.200Z"
            },
            "replies": [
              {
                "$type": "app.bsky.feed.defs#threadViewPost",
                "post": {
                  "uri": "at://did:plc:bob/app.bsky.feed.post/ccc",
                  "cid": "bafybob",
                  "author": { "did": "did:plc:bob", "handle": "bob.bsky.social", "displayName": null },
                  "record": { "text": "A nested reply", "createdAt": "2024-10-17T09:00:00Z" },
                  "replyCount": 0, "repostCount": 0, "likeCount": 3, "quoteCount": 0,
                  "indexedAt": "2024-10-17T09:00:00Z"
                },
                "replies": []
              }
            ]
          },
          {
            "$type": "app.bsky.feed.defs#blockedPost",
            "uri": "at://did:plc:blocked/app.bsky.feed.post/blocked",
            "blocked": true,
            "author": { "did": "did:plc:blocked" }
          },
          {
            "$type": "app.bsky.feed.defs#threadViewPost",
            "post": {
              "uri": "at://did:plc:carol/app.bsky.feed.post/ddd",
              "cid": "bafycarol",
              "author": { "did": "did:plc:carol", "handle": "carol.bsky.social", "displayName": "Carol" },
              "record": { "text": "Second top-level reply", "createdAt": "2024-10-17T10:00:00.000Z" },
              "replyCount": 0, "repostCount": 1, "likeCount": 5, "quoteCount": 0,
              "indexedAt": "2024-10-17T10:00:00.000Z"
            },
            "replies": []
          }
        ]
      }
    }
    """

    static let profile = """
    {
      "did": "did:plc:z72i7hdynmk6r22z27h6tvur",
      "handle": "bsky.app",
      "displayName": "Bluesky",
      "description": "official Bluesky account",
      "avatar": "https://cdn.bsky.app/img/avatar/plain/did:plc:z72i7hdynmk6r22z27h6tvur/x@jpeg",
      "banner": "https://cdn.bsky.app/img/banner/plain/did:plc:z72i7hdynmk6r22z27h6tvur/y@jpeg",
      "followersCount": 34071610,
      "followsCount": 11,
      "postsCount": 802,
      "createdAt": "2023-04-12T04:53:57.057Z",
      "indexedAt": "2025-10-27T21:05:26.152Z"
    }
    """
}
