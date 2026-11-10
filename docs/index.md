---
title: immich-crosslink
subtitle: Links between Immich apps, on the same computer
---

**immich-crosslink** is a small, open protocol that lets apps working with an [Immich](https://immich.app) server
point to each other. Right-click a photo in one app, choose **Show in *another app***, and that app opens the same
photo, album, person or place. No app needs to know the others in advance: each registers one URL scheme, and the
operating system tells them who else is there.

It is a draft (0.1), open for changes. Anyone may implement it, and proposals are welcome.

# How it works

1. Every participating app registers the URL scheme `immich-crosslink` with the operating system (macOS, GNOME, KDE).
2. An app asks the system which other apps registered it, and offers **Show in *app*** for each, by the name and icon
   the system knows.
3. Choosing one sends that app a link naming the item the way Immich's own web app does, with the server's address:

   ```
   immich-crosslink:///albums/<album>/photos/<asset>?server=https%3A%2F%2Fphotos.example.com
   ```

4. The receiving app checks it is signed in to that server, and shows the item. A link only ever shows something: it
   never changes, shares or deletes anything.

Every app's settings carry the same switch, **Immich crosslink**, on by default, with a link to this page, and a
switch for each app found.

# Read more

- [The protocol](spec.md): links, Immich paths, sending, receiving, finding participants, settings, security,
  versioning.
- [Implementing it](implementing.md): registering the scheme and finding the others on macOS, GNOME and KDE, with
  code.
- [Participants](participants.md): the apps that take part, and the draft each follows.
- [Changelog](changelog.md).
- [Contributing](https://github.com/jakobhviid/immich-crosslink/blob/main/CONTRIBUTING.md): how to propose a change
  or add your app.

# Why a protocol

Apps that hard-code each other couple tightly: each must know the other's links and follow its changes. With one
shared scheme and Immich's own item paths, an app supports every other participant at once, and a new app joins by
registering the scheme. The paths are Immich's, so a crosslink, an Immich web address and an Immich mobile deep link
name an item the same way.
