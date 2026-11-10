---
title: Changelog
---

# Draft 0.2, clarified (2026-11-10)

From the first two implementations (Immich Mount and Immich Gallery), without changing any link that was already
shown: `user` is a UUID, compared in either case; the server address has a host and no user information, query or
fragment, and its port compares as a number; searches without a query, or by nothing, cannot be shown, and a
non-string city or country is malformed; a city named alone may be shown as any place of that name, preferring the
account's library; an asset whose view no longer holds it is still shown, without the context; participants should
not make themselves the scheme's default handler. Twelve test links for these.

# Draft 0.2 (2026-11-10)

- **Announcing:** an app takes part by announcing itself in its installed metadata (Info.plist `ImmichCrosslink`,
  desktop entry `X-Immich-Crosslink-Version` and `-Shows`): the draft it follows and the kinds it shows. A
  participant both announces itself and registers the scheme, which only delivers links. Apps never ask each other
  at run time.
- **Kinds** (`asset`, `album`, `person`, `place`, `page`): senders offer an app only for the kinds it announces, and
  only to apps announcing the same draft.
- **When to read participants:** for each menu, or kept until the system says apps may have changed; never across
  launches.
- **Receiving** ends in one of three results: show, cannot show, invalid. Upper-case ids are accepted.
- **Parameters:** no more `x-` names; every name is defined here, and an app's own parameters use its reverse domain
  name. Senders must encode `server`.
- **Test links** (`tests/links.json`) for conformance, including parameters receivers must ignore; 1.0 needs two
  independent implementations passing them. A roadmap, with reference implementations in Rust and Swift to follow.

# Draft 0.1 (2026-11-10)

The first draft: the scheme `immich-crosslink`; links made of an Immich path, `server` and an optional `user`; the
Immich paths for assets (alone and in an album, person, search, Favorites or Archive), albums, people, cities,
countries and the main pages; the rules for sending and receiving; finding participants on macOS and Linux; the
Immich crosslink switch in settings; copying links; security, versioning and the relation to Immich.
