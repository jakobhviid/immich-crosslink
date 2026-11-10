---
title: Participants
subtitle: Apps that take part in immich-crosslink
---

Apps that implement, or plan to implement, the protocol. To add yours, open a pull request changing this page
([Contributing](https://github.com/jakobhviid/immich-crosslink/blob/main/CONTRIBUTING.md)).

| App | Platforms | Sends | Shows | Draft | Status |
|---|---|---|---|---|---|
| [Immich Mount](https://github.com/jakobhviid/immich-mount): an Immich library as a drive in Files, Dolphin and Finder | Linux (GNOME, KDE), macOS | Show in *app* on files and folders in the drive | `asset`, `album`, `person`, `place`, `page`: the item's file or folder, in the file manager | 0.2 | Planned ([roadmap](https://github.com/jakobhviid/immich-mount/blob/main/ROADMAP.md)) |
| [Immich Gallery](https://github.com/IGOLz/ImmichGallery): a native Immich client | macOS | Show in *app* on photos, albums, people and places | `asset`, `album`, `person`, `place`, `page`: opens the item | 0.2 | Implemented by a contributor, to be proposed |

**Planned** means the app's own plans name this protocol. **To be proposed** means a contributor means to suggest
support to the app's maintainers, who decide; **implemented by a contributor** means that support is written and
passes the test links, but is not part of the app until its maintainers take it.
