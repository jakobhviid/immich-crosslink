---
title: The immich-crosslink protocol
subtitle: Draft 0.1
---

**Status:** draft 0.1, open for changes. Anything here may still change before 1.0 (see [Versioning](#versioning)).
Proposals are welcome as issues and pull requests on
[GitHub](https://github.com/jakobhviid/immich-crosslink).

The key words MUST, MUST NOT, SHOULD, SHOULD NOT and MAY are to be read as described in
[RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174) when, and
only when, they appear in capitals.

# Purpose

Many apps work with an [Immich](https://immich.app) server: galleries, file managers, editors, backup tools. When
several are installed on one computer, a user looking at a photo in one of them should be able to say "show this in
that app". immich-crosslink is the smallest agreement that makes this work between apps that know nothing about each
other:

- one way to **name an Immich item** in a link: a photo, an album, a person, a place, a page;
- one **URL scheme**, `immich-crosslink`, that every participating app registers, so apps **find each other** through the
  operating system;
- a few rules for **sending** and **receiving** links, so a link is always safe to open.

It does not define an API, a server feature or a way to sign in. Each app keeps its own account; a link only says
which item, on which server.

# Terms

- **Item:** something the user can see in an Immich app: an asset (photo or video), an album, a person, a place, or a
  page that lists items.
- **Immich path:** the path, and for searches the query, that Immich's own web app uses for an item, such as
  `/albums/<album id>/photos/<asset id>`.
- **Server address:** the address the user signed in to, as an absolute URL without a trailing slash and without
  `/api`: `https://photos.example.com`.
- **Crosslink:** a link with the scheme `immich-crosslink`, made of an Immich path and a server address.
- **Participant:** an app that registers the scheme and follows this protocol.
- **Sender:** a participant offering to show an item in another participant. **Receiver:** the participant that is
  sent the link.

# Links

## Form

```
immich-crosslink://{Immich path}?[{path query}&]server={server address}[&user={user id}]
```

The Immich path starts with `/`, so the host is empty and every link starts `immich-crosslink:///`.

For example:

```
immich-crosslink:///albums/0f8c…/photos/9a1e…?server=https%3A%2F%2Fphotos.example.com
immich-crosslink:///search?query=%7B%22city%22%3A%22Aarhus%22%2C%22country%22%3A%22Denmark%22%7D&server=https%3A%2F%2Fphotos.example.com
```

- The host MUST be empty. The Immich path follows it, as in the table below.
- `server` is REQUIRED. Its value is the server address. Senders SHOULD encode it as JavaScript's
  `encodeURIComponent` does; receivers MUST also accept it unencoded.
- `user` is OPTIONAL: the Immich id of the user whose view the sender shows. A receiver with several accounts on one
  server uses it to pick the account; senders SHOULD include it when they know it.
- Receivers MUST ignore query parameters they do not know. New parameters are added only by this protocol; names
  starting `x-` are free for experiments and never defined here.
- A link MUST NOT carry a credential, a token, a password or a shared-link key.

## Immich paths

The paths are those of Immich's web app, defined in
[`web/src/lib/route.ts`](https://github.com/immich-app/immich/blob/main/web/src/lib/route.ts) and
[`web/src/routes/(user)/`](https://github.com/immich-app/immich/tree/main/web/src/routes/(user)), which Immich's mobile
app also takes as deep links through `my.immich.app`. Draft 0.1 defines these:

| Item | Immich path |
|---|---|
| An asset | `/photos/<asset>` |
| An asset in an album | `/albums/<album>/photos/<asset>` |
| An asset in a person | `/people/<person>/photos/<asset>` |
| An asset in Favorites | `/favorites/photos/<asset>` |
| An asset in Archive | `/archive/photos/<asset>` |
| An asset in a search (such as a place) | `/search/photos/<asset>?query=<search>` |
| An album | `/albums/<album>` |
| A person | `/people/<person>` |
| A place: a city | `/search?query=<search>`, `<search>` = `{"city":"<city>","country":"<country>"}` |
| A place: a country | `/search?query=<search>`, `<search>` = `{"country":"<country>"}` |
| The timeline, albums, people, places, favorites, archive | `/photos`, `/albums`, `/people`, `/places`, `/favorites`, `/archive` |

- `<asset>`, `<album>` and `<person>` are Immich ids (UUIDs), lower case as Immich writes them.
- `<search>` is the JSON Immich's web app writes for a metadata search (`JSON.stringify`, no spaces, keys in the order
  shown), encoded as `encodeURIComponent` does: every byte except `A-Z a-z 0-9 - _ . ! ~ * ' ( )` becomes `%XX` of its
  UTF-8. City and country names are Immich's own strings (its search suggestions), never a file or folder name made
  from them. Immich's Places page links a city with `{"city":…}` alone; senders SHOULD add the country when they know
  it, so two cities of one name stay apart, and receivers MUST accept either.
- A path with context (an asset in an album, person, search, Favorites or Archive) says where the user saw the asset.
  A receiver that has no such view SHOULD show the asset alone.
- A sender MUST NOT offer a crosslink for an item that has no path here.

Because the paths are Immich's own, a crosslink also gives the item's web address: the server address followed by the
Immich path. Senders MAY offer that as **Open in Immich**.

# Sending

A sender offers **Show in *app*** for each other participant it finds, on items that have an Immich path.

- It MUST find participants through the operating system ([Finding participants](#finding-participants)) and MUST
  NOT list itself.
- It MUST show each participant by the name and icon the operating system gives for it (its bundle or desktop entry),
  never by anything in a link or chosen by the participant at run time.
- It MUST send the link to that participant alone, never by opening the link with the scheme's default handler, which
  could be any participant.
- It sends a link only when the user asks, one item at a time.

# Receiving

A receiver shows what a link names.

- **Only showing.** Opening a crosslink MUST only navigate: open a page, select an item, reveal a file. It MUST NOT
  change, upload, download for keeping, share, delete or edit anything, and MUST NOT start a sign-in. Any web page can
  open a link with a registered scheme, so a link is always treated as coming from a stranger.
- **Checking.** Ids MUST be checked to be UUIDs, and the path to be one this protocol defines, before anything is
  fetched.
- **The account.** The receiver compares `server` with the servers it is signed in to: scheme, host in lower case,
  and port, with a scheme's default port the same as none, and any path without its trailing slash. With several
  accounts on that server it picks the one matching `user`, if given. Without a match it tells the user that it is not
  signed in to that server (naming the host), and does nothing else.
- **Nothing to show.** For an item the account cannot see, or a path the receiver cannot show, it tells the user so in
  a sentence, and does nothing else.
- **Turned off.** If the user turned Immich crosslink off ([Settings](#settings)), a received link only tells the user
  so, with a way to turn it on.

# Finding participants

A participant registers the scheme `immich-crosslink` with the operating system the usual way, and finds the others
the same way.

| Platform | Registering | Finding the others | Sending to one |
|---|---|---|---|
| macOS | `CFBundleURLTypes` with the scheme `immich-crosslink` in the app's Info.plist | `NSWorkspace.urlsForApplications(toOpen:)` with an `immich-crosslink:` URL | `NSWorkspace.open(_:withApplicationAt:configuration:)` |
| Linux (GNOME, KDE and others) | `MimeType=x-scheme-handler/immich-crosslink;` in the app's desktop entry | `g_app_info_get_all_for_type("x-scheme-handler/immich-crosslink")` (GIO), `KApplicationTrader::queryByMimeType` (KDE) | `g_app_info_launch_uris`, `KIO::ApplicationLauncherJob` |

- **Flatpak.** A Flatpak app is a receiver like any other: its exported desktop entry carries the scheme. From inside
  the sandbox it cannot list the other apps; it MAY offer one **Show in Another App…** through the OpenURI portal,
  which lets the user choose.
- **Other platforms** are not defined in draft 0.1. Proposals are welcome.
- **Schemes that are not this one.** Participants MUST NOT register `immich`, the scheme of Immich's own mobile app,
  and MUST NOT use `app.immich`, Immich's sign-in redirect, for crosslinks. (Some desktop apps handle `app.immich` for
  their own sign-in, as Immich's mobile app does; that is unrelated to this protocol.)

# Settings

Every participant's settings show the protocol the same way, so a user meets one name in every app:

- a switch labelled **Immich crosslink**, on by default, with a link to
  <https://jakob.hviid.phd/immich-crosslink/> beside it;
- under it, the participants found, each with a switch, on by default.

Turning the main switch off stops the app from offering Show in *app* and from acting on received links. Turning one
participant off removes it from the app's menus. "Immich crosslink" is a name and stays in English; the words around it
are translated.

# Copying links

A participant MAY offer **Copy Immich Link**, which copies the item's web address: it opens in any browser and in
Immich's own apps. A participant MAY also offer a link of its own scheme, for opening the item in itself. Copying a
crosslink is not recommended: pasted into a browser or a note, it opens with whichever participant the system picks.

# Security and privacy

- A crosslink tells the receiver which item the user picked, on which server. It is sent only when the user asks.
- Links carry no secret; anyone can make one. Receivers act on them only as [Receiving](#receiving) allows.
- A copied web address shows the server's address, as any Immich link does.
- Another app on the computer can register the scheme. It is then listed by name and icon from the system, and
  receives only the links the user sends it.

# Versioning

- **Drafts (0.x)** may change anything. Implementations name the draft they follow.
- **From 1.0,** changes within a major version only add: new paths, new optional parameters, new platforms. A
  receiver from an earlier 1.x keeps working, because it ignores parameters it does not know and says it cannot show
  paths it does not know.
- Links carry no version.
- Changes are made as pull requests to the protocol's repository, and listed in the [changelog](changelog.md).

# Relation to Immich

immich-crosslink is an independent, unofficial project. It is not affiliated with, endorsed by, or sponsored by the
Immich project or FUTO. "Immich" is used only to describe the server the apps work with, and remains the mark of its
owner.

The protocol follows Immich's own paths on purpose, so a crosslink, an Immich web address and an Immich mobile deep
link name an item the same way. Should Immich define desktop deep links of its own, this protocol means to follow
them.
