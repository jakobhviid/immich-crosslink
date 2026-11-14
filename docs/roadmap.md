---
title: Roadmap
---

Where Immich Crosslink is going, in order. Each step is reached when it is met, not by a date.

# Drafts (done)

The protocol was designed in drafts (0.1, 0.2), which could change anything. Changes came from building it into real
apps: what they needed, and what turned out hard to implement or to read.

# Two implementations (done)

[Immich Mount](https://github.com/jakobhviid/immich-mount) (Linux and macOS) and
[Immich Gallery](https://github.com/IGOLz/ImmichGallery) (macOS) implement the protocol, written apart from each
other, and each sends to the other and back (see [Participants](participants.md)). Both pass the
[test links](test-links.md). Both have released it and have been tested together. This was what 1.0 waited for: a
protocol is only as clear as two implementations written from it agree.

# Version 1.0 (done, 14 November 2026)

With two implementations agreeing, draft 0.2 became 1.0, unchanged. From now on, changes within a major version only add
([Versioning](spec.md#versioning)), and the protocol changes by pull request.

# Reference implementations

Small libraries that other apps can use instead of writing the protocol again, extracted from the two
implementations once both work, rather than written ahead of them:

- **Rust** (a crate, `immich-crosslink`): links and Immich paths both ways, announcements, and finding participants
  on Linux through GIO. From Immich Mount's core.
- **Swift** (a Swift package): the same for macOS, with Launch Services. From Immich Gallery's and Immich Mount's Mac
  apps.

Each lives in a repository of its own (`immich-crosslink-rs`, `immich-crosslink-swift`), so each follows its
language's tools and releases on its own: a Swift package is used by its repository's address, with its manifest at
the root. Both test against the test links in this repository, at the version they implement. They are MIT-licensed,
so an app may also copy the code instead of depending on it.

# Later

- Other platforms (Windows), when an app there wants to take part.
- More kinds of item (tags, memories, folders), when an app needs them and Immich has a path for them.
- Proposing the protocol to Immich itself, should Immich want desktop deep links of its own.
