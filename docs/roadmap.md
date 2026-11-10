---
title: Roadmap
---

Where immich-crosslink is going, in order. Each step is reached when it is met, not by a date.

# Drafts

The protocol is designed in drafts (0.x), which may change anything. Changes come from building it into real apps:
what they need, and what turns out hard to implement or to read.

# Two implementations

[Immich Mount](https://github.com/jakobhviid/immich-mount) (Linux and macOS) and
[Immich Gallery](https://github.com/IGOLz/ImmichGallery) (macOS) implement the protocol, written apart from each
other, and each sends to the other and back (see [Participants](participants.md)). Both pass the
[test links](test-links.md). This is what 1.0 waits for: a protocol is only as clear as two implementations
written from it agree.

# Version 1.0

Once two implementations agree, the draft becomes 1.0. From then on, changes within a major version only add
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
