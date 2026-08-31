//
//  SupportTests.swift
//  BlueskyMetadataTests
//
//  Created by David Sherlock on 2026.
//
//  The URI parser pinned directly — no model constructed.
//

import XCTest
@testable import BlueskyMetadata

final class SupportTests: XCTestCase {

    func testParserEdges() throws {
        XCTAssertEqual(
            try BlueskyURI.parse("https://bsky.app/profile/bsky.app/post/3l6oveex3ii2l?ref=x"),
            .webPost(actor: "bsky.app", rkey: "3l6oveex3ii2l")
        )
        XCTAssertEqual(
            try BlueskyURI.parse("at://did:plc:abc/app.bsky.feed.post/xyz"),
            .atURI("at://did:plc:abc/app.bsky.feed.post/xyz")
        )
        XCTAssertThrowsError(try BlueskyURI.parse("https://bsky.app/profile/bsky.app"))
        XCTAssertTrue(BlueskyURI.isDID("did:plc:abc"))
        XCTAssertFalse(BlueskyURI.isDID("bsky.app"))
        XCTAssertEqual(BlueskyURI.postURI(did: "did:plc:abc", rkey: "xyz"), "at://did:plc:abc/app.bsky.feed.post/xyz")
    }
}
