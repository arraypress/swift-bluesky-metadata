# Swift Bluesky Metadata

A Swift library for fetching Bluesky post threads (comments) and profiles. No API key, app password, or login required — uses the **keyless AT Protocol public API** (`public.api.bsky.app`), which returns a post and its entire nested reply tree in a single request.

## Features

- 💬 **Full reply trees in one request** — root post plus every nested reply via `thread(_:)`
- 🌳 **Nested + flat** — each `BlueskyComment` carries its `replies`; use `flattened` for a depth-first list with `depth` preserved
- 👤 **Profiles** — `profile(_:)` by handle or DID (display name, bio, follower/following/post counts, avatar)
- 🔗 **Flexible input** — `bsky.app` post URLs or raw `at://` URIs; handles are resolved to DIDs automatically
- 🛡️ **Graceful degradation** — blocked / not-found reply nodes are skipped, not fatal
- 🔒 **No API key required** — public `public.api.bsky.app/xrpc` endpoints
- 🍎 **Cross-platform** — macOS, iOS, tvOS, watchOS
- ⚡ **Async/await** native
- 🛡️ **Typed error handling**

## Requirements

- macOS 13.0+ / iOS 16.0+ / tvOS 16.0+ / watchOS 9.0+
- Swift 6.0+

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/arraypress/swift-bluesky-metadata.git", from: "1.0.0")
]
```

## Usage

### Post + comments

```swift
import BlueskyMetadata

let (post, comments) = try await BlueskyMetadata.thread(
    "https://bsky.app/profile/bsky.app/post/3l6oveex3ii2l"
)

print("\(post.author.handle): \(post.text)")
print("\(post.likeCount) likes · \(comments.totalCount) replies")

for c in comments.flattened {
    let indent = String(repeating: "  ", count: c.depth)
    print("\(indent)\(c.author.handle): \(c.text)")
}
```

### Comments only

```swift
let comments = try await BlueskyMetadata.comments("at://did:plc:…/app.bsky.feed.post/3l6oveex3ii2l")
let topLevel = comments.count
let everything = comments.totalCount
```

Control how deep the reply tree is fetched with the `depth:` parameter (the API caps it):

```swift
let (_, comments) = try await BlueskyMetadata.thread(url, depth: 10)
```

### Profile

```swift
let profile = try await BlueskyMetadata.profile("bsky.app")   // handle or DID
print("\(profile.displayName ?? profile.handle) — \(profile.followersCount ?? 0) followers")
```

### Resolve a handle

```swift
let did = try await BlueskyMetadata.resolveHandle("bsky.app")   // did:plc:z72i7hdynmk6r22z27h6tvur
```

### Error handling

```swift
do {
    let (post, comments) = try await BlueskyMetadata.thread(input)
} catch BlueskyMetadataError.notFound {
    print("No such post")
} catch {
    print(error.localizedDescription)
}
```

## Supported Inputs

- `https://bsky.app/profile/<handle-or-did>/post/<rkey>` — a handle is resolved to a DID via `com.atproto.identity.resolveHandle`
- A raw `at://<did-or-handle>/app.bsky.feed.post/<rkey>` URI

## Models

| Type | Kind | Description |
|------|------|-------------|
| `BlueskyPost` | struct | `uri`, `cid`, `author`, `text`, `createdAt`, `indexedAt`, `replyCount`, `repostCount`, `likeCount`, `quoteCount`, plus `rkey`, `bskyURL` |
| `BlueskyComment` | struct | `uri`, `author`, `text`, `createdAt`, `likeCount`, `repostCount`, `replyCount`, `depth`, `replies`, plus `hasReplies`, `descendantCount`, `flattened` |
| `BlueskyAuthor` | struct | `did`, `handle`, `displayName`, `avatar` |
| `BlueskyProfile` | struct | `did`, `handle`, `displayName`, `description`, `avatar`, `banner`, `followersCount`, `followsCount`, `postsCount`, `createdAt`, plus `bskyURL` |
| `BlueskyMetadataError` | enum | Typed errors with `errorDescription` |

## How It Works

The AT Protocol exposes any thread at `app.bsky.feed.getPostThread`, returning the
root post and its complete nested reply tree in one response. This library parses
the input into an `at://` URI (resolving a handle to a DID when needed), requests
that JSON, and builds a typed `BlueskyComment` tree — skipping blocked or
not-found reply nodes.

> **Note:** `replyCount` on a post or comment is the server-reported count, which
> may exceed the number of replies actually fetched when `depth:` limits the tree.
> Use `comments.totalCount` for the count of replies you actually received.

## Testing

```bash
swift test                        # offline unit tests (fixtures)
BLUESKY_LIVE_TESTS=1 swift test   # also run the live network tests
```

Add `BLUESKY_PRINT=1` to print a fetched thread and profile while the live tests run.

## License

MIT

## Author

David Sherlock
