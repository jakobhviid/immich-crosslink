---
title: Changelog
---

# Version 1.1 (2026-11-14)

Additions, no link changes: an app may write its announcement itself, a desktop entry in the user's applications
folder that it adds and removes as the user lets it take part; entries kept out of the app grid (`NoDisplay=true`) are
found; one app may announce several participants, one per place it shows items in, which reach each other as any
participants do. Every 1.0 participant keeps working as it is, and the announcement still reads `0.2`.

# Version 1.0 (2026-11-14)

Draft 0.2 becomes 1.0, with no change to links or rules. Immich Mount (2.33.0) and Immich Gallery (0.6.0) implement
it apart from each other, have both released it, and have been tested together, each sending to the other and back.
The announcement keeps the value `0.2`, which in version 1 names the major version, so the released apps take part as
they are. From now on, changes within version 1 only add.

# Draft 0.2, settings and Show in (2026-11-11)

No link changes. **Show in:** two known ways, one menu item per participant (preferred) or one **Show in Another
App…** where a menu cannot name apps, which sends straight to the one participant or lets the user choose among
several; the guide shows both. A participant is named by its bundle's display name. **Settings:** the switch's link
reads **Learn more…** (Learn More on GNOME and KDE); a participant is found only when it can be listed, read and
started, and each platform's ways to look present when it is not are named; one not found is listed as **Not found**
and keeps **Forget**, which a participant that is found does not have (Forget on every participant was tried the
same day: a found one came back at once, switched on, so the button seemed to do nothing); an optional, recommended
description says what the switches and Forget do; with none seen, the settings may link to the participants. No
participant is set apart.

# Draft 0.2, clarified (2026-11-10)

From the first two implementations (Immich Mount and Immich Gallery), without changing any link that was already
shown: `user` is a UUID, compared in either case; the server address has a host and no user information, query or
fragment, and its port compares as a number; searches without a query, or by nothing, cannot be shown, and a
non-string city or country is malformed; a city named alone may be shown as any place of that name, preferring the
account's library; an asset whose view no longer holds it is still shown, without the context; participants should
not make themselves the scheme's default handler; on macOS, a sandboxed app reads announcements only from
`/Applications`. The protocol is named Immich Crosslink in prose, and its settings switch reads **Immich Crosslink**
with a **Read more** link, the address not shown. Settings remember the participants seen: one away is listed as
Not installed with a Forget button, and forgotten, switch and all, after 30 days unseen. Open in Immich and Copy
Immich Link share one switch of their own. Senders leave out apps that cannot start, and say so when sending fails. Twelve test links for these.

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
Immich Crosslink switch in settings; copying links; security, versioning and the relation to Immich.
