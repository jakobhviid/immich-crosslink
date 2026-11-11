---
title: Immich Crosslink
subtitle: Links between Immich apps, on the same computer
hero: true
---

**Immich Crosslink** is a small, open protocol that lets apps working with an [Immich](https://immich.app) server
point to each other. Right-click a photo in one app, choose **Show in *another app***, and that app opens the same
photo, album, person or place. No app needs to know the others in advance: each announces itself when it is installed,
and the operating system tells the others who is there.

It is a draft (0.2), open for changes. Anyone may implement it, and proposals are welcome.

# How it works

1. Every participating app **announces** itself in the metadata it installs (its Info.plist on macOS, its desktop
   entry on Linux): the draft it follows, and what it can show. It also registers the URL scheme `immich-crosslink`,
   which delivers links to it.
2. An app asks the system which other apps registered the scheme, reads their announcements without starting them,
   and offers **Show in *app*** for each that shows the item, by the name and icon the system knows.
3. Choosing one sends that app a link naming the item the way Immich's own web app does, with the server's address:

   ```
   immich-crosslink:///albums/<album>/photos/<asset>?server=https%3A%2F%2Fphotos.example.com
   ```

4. The receiving app checks it is signed in to that server, and shows the item. A link only ever shows something: it
   never changes, shares or deletes anything.

Every app's settings carry the same switch, **Immich Crosslink**, on by default, with a **Learn more…** link to this
page, and a switch and a Forget button for each app found.

# Read more

- [The protocol](spec.md): announcing, links, Immich paths, sending, receiving, finding participants, settings,
  security, versioning, conformance.
- [Implementing it](implementing.md): announcing the app, registering the scheme, and finding the others on macOS,
  GNOME and KDE, with code.
- [Test links](test-links.md): links with their expected results, for testing an implementation.
- [Participants](participants.md): the apps that take part, and the draft each follows.
- [Roadmap](roadmap.md): two implementations, then 1.0, then reference implementations in Rust and Swift.
- [Changelog](changelog.md).
- [Contributing](https://github.com/jakobhviid/immich-crosslink/blob/main/CONTRIBUTING.md): how to propose a change
  or add your app.

# Why a protocol

Apps that hard-code each other couple tightly: each must know the other's links and follow its changes. With one
shared scheme and Immich's own item paths, an app supports every other participant at once, and a new app joins by
registering the scheme. The paths are Immich's, so a crosslink, an Immich web address and an Immich mobile deep link
name an item the same way.
