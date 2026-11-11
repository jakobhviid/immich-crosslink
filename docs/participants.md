---
title: Participants
subtitle: Apps that take part in Immich Crosslink
---

Apps that implement, or plan to implement, the protocol. To add yours, open a pull request changing this page
([Contributing](https://github.com/jakobhviid/immich-crosslink/blob/main/CONTRIBUTING.md)).

| App | Platforms | Sends | Shows | Draft | Status |
|---|---|---|---|---|---|
| [Immich Mount](https://github.com/jakobhviid/immich-mount): an Immich library as a drive in Files, Dolphin and Finder | Linux (GNOME, KDE), macOS | Show in *app* on files and folders in the drive (in Finder, Show in Another App…) | `asset`, `album`, `person`, `place`, `page`: the item's file or folder, in the file manager | 0.2 | Released in 2.33.0 |
| [Immich Gallery](https://github.com/IGOLz/ImmichGallery): a native Immich client | macOS | Show in *app* on photos, albums, people and places | `asset`, `album`, `person`, `place`, `page`: opens the item | 0.2 | Proposed: [IGOLz/ImmichGallery#47](https://github.com/IGOLz/ImmichGallery/pull/47) |

**Released** means the app's own releases take part. **Proposed** means support is written and passes the test links,
and is waiting for the app's maintainers, who decide.
