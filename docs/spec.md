---
title: The Immich Crosslink protocol
subtitle: Draft 0.2
---

**Status:** draft 0.2, open for changes. Anything here may still change before 1.0 (see [Versioning](#versioning)).
Proposals are welcome as issues and pull requests on
[GitHub](https://github.com/jakobhviid/immich-crosslink).

The key words MUST, MUST NOT, SHOULD, SHOULD NOT and MAY are to be read as described in
[RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) and [RFC 8174](https://www.rfc-editor.org/rfc/rfc8174) when, and
only when, they appear in capitals.

# Purpose

Many apps work with an [Immich](https://immich.app) server: galleries, file managers, editors, backup tools. When
several are installed on one computer, a user looking at a photo in one of them should be able to say "show this in
that app". Immich Crosslink is the smallest agreement that makes this work between apps that know nothing about each
other:

- an **announcement** each app installs with itself, saying that it takes part and what it can show, which other apps
  read without starting it;
- one way to **name an Immich item** in a link: a photo, an album, a person, a place, a page;
- one **URL scheme**, `immich-crosslink`, that delivers a link to the app the user chose;
- a few rules for **sending** and **receiving** links, so a link is always safe to open.

It does not define an API, a server feature or a way to sign in. Each app keeps its own account; a link only says
which item, on which server.

# Terms

- **Item:** something the user can see in an Immich app: an asset (photo or video), an album, a person, a place, or a
  page that lists items.
- **Kind:** what sort of item a link names: `asset`, `album`, `person`, `place` or `page` ([Immich paths](#immich-paths)).
- **Immich path:** the path, and for searches the query, that Immich's own web app uses for an item, such as
  `/albums/<album id>/photos/<asset id>`.
- **Server address:** the address the user signed in to, as an absolute URL without a trailing slash and without
  `/api`: `https://photos.example.com`.
- **Crosslink:** a link with the scheme `immich-crosslink`, made of an Immich path and a server address.
- **Announcement:** what an app installs with itself to take part: the draft it follows and the kinds it can show
  ([Announcing](#announcing)).
- **Participant:** an app that both announces itself and registers the scheme. An app that only registers the scheme
  is not a participant.
- **Sender:** a participant offering to show an item in another participant. **Receiver:** the participant that is
  sent the link.

# Links

## Form

```
immich-crosslink://{Immich path}?[{path query}&]server={server address}[&user={user id}]
```

The Immich path starts with `/`, so the host is empty and every link starts `immich-crosslink:///`. For example:

```
immich-crosslink:///albums/0f8c…/photos/9a1e…?server=https%3A%2F%2Fphotos.example.com
immich-crosslink:///search?query=%7B%22city%22%3A%22Aarhus%22%2C%22country%22%3A%22Denmark%22%7D&server=https%3A%2F%2Fphotos.example.com
```

- The host MUST be empty. The Immich path follows it, as in the table below.
- `server` is REQUIRED. Its value is the server address. Senders MUST encode it as JavaScript's `encodeURIComponent`
  does; receivers MUST also accept it unencoded. It is an absolute `http` or `https` URL with a host, and with no user
  information (`someone@`), query or fragment; a port, if given, is a number.
- `user` is OPTIONAL: the Immich id of the user whose view the sender shows, a UUID. Senders write it in lower case and
  SHOULD include it when they know it; receivers compare it in either case. A receiver with several accounts on one
  server uses it to pick the account.
- Every parameter name is defined here, and added by a change to this document. An app that needs a parameter of its
  own names it with its reverse domain name (`dev.example.photos.view`), and other apps ignore it. There is no
  `x-` prefix: names made for experiments tend to stay ([RFC 6648](https://www.rfc-editor.org/rfc/rfc6648)).
- Receivers MUST ignore parameters they do not know, and the [test links](test-links.md) include some, so every
  receiver does it from the start.
- A link MUST NOT carry a credential, a token, a password or a shared-link key.

## Immich paths

The paths are those of Immich's web app, defined in
[`web/src/lib/route.ts`](https://github.com/immich-app/immich/blob/main/web/src/lib/route.ts) and
[`web/src/routes/(user)/`](https://github.com/immich-app/immich/tree/main/web/src/routes/(user)), which Immich's mobile
app also takes as deep links through `my.immich.app`. Draft 0.2 defines these:

| Item | Kind | Immich path |
|---|---|---|
| An asset | `asset` | `/photos/<asset>` |
| An asset in an album | `asset` | `/albums/<album>/photos/<asset>` |
| An asset in a person | `asset` | `/people/<person>/photos/<asset>` |
| An asset in Favorites | `asset` | `/favorites/photos/<asset>` |
| An asset in Archive | `asset` | `/archive/photos/<asset>` |
| An asset in a search (such as a place) | `asset` | `/search/photos/<asset>?query=<search>` |
| An album | `album` | `/albums/<album>` |
| A person | `person` | `/people/<person>` |
| A city | `place` | `/search?query=<search>`, `<search>` = `{"city":"<city>","country":"<country>"}` |
| A country | `place` | `/search?query=<search>`, `<search>` = `{"country":"<country>"}` |
| The timeline, albums, people, places, favorites, archive | `page` | `/photos`, `/albums`, `/people`, `/places`, `/favorites`, `/archive` |

- `<asset>`, `<album>` and `<person>` are Immich ids (UUIDs). Senders write them in lower case, as Immich does;
  receivers accept either case, as UUIDs allow, and use lower case.
- `<search>` is the JSON Immich's web app writes for a metadata search (`JSON.stringify`, no spaces, keys in the order
  shown), encoded as `encodeURIComponent` does: every byte except `A-Z a-z 0-9 - _ . ! ~ * ' ( )` becomes `%XX` of its
  UTF-8. City and country names are Immich's own strings (its search suggestions), never a file or folder name made
  from them. Immich's Places page links a city with `{"city":…}` alone; senders SHOULD add the country when they know
  it, so two cities of one name stay apart, and receivers MUST accept either. A receiver that needs a country for a
  city named alone MAY show any place of that name, and SHOULD prefer one in the account's library.
- A search without `query`, or by nothing (`{}`), or by anything but `city` and `country`, has no path here; a search
  that is not a JSON object, or whose `city` or `country` is not a string, is malformed.
- A path with context (an asset in an album, person, search, Favorites or Archive) says where the user saw the asset.
  Its kind is `asset`: a receiver that has no such view MUST show the asset alone. A receiver whose view no longer
  holds the asset (it left the album since) SHOULD show it the same way, without the context.
- A sender MUST NOT offer a crosslink for an item that has no path here.

Because the paths are Immich's own, a crosslink also gives the item's web address: the server address followed by the
Immich path. Senders MAY offer that as **Open in Immich**.

# Announcing

A participant announces itself in the metadata it installs, which the operating system indexes and other apps read
without starting it. The announcement is the only way to take part: apps never ask each other at run time.

| Platform | Where | Announcement |
|---|---|---|
| macOS | The app's Info.plist | the key `ImmichCrosslink`, a dictionary: `Version` (string, `0.2`) and `Shows` (array of kinds) |
| Linux | The app's desktop entry | `X-Immich-Crosslink-Version=0.2` and `X-Immich-Crosslink-Shows=` (kinds, each followed by `;`) |

```xml
<key>ImmichCrosslink</key>
<dict>
    <key>Version</key>
    <string>0.2</string>
    <key>Shows</key>
    <array>
        <string>asset</string>
        <string>album</string>
        <string>person</string>
    </array>
</dict>
```

```ini
X-Immich-Crosslink-Version=0.2
X-Immich-Crosslink-Shows=asset;album;person;
```

- `Version` is the draft or major version the app follows ([Versioning](#versioning)).
- `Shows` lists the kinds it can show. An app that shows assets MUST list `asset`, and MUST then take an asset's
  link with any context (showing the asset alone where it has no such view).
- Readers MUST ignore kinds they do not know, and treat an announcement without a version they understand as absent.
- The `X-` in the desktop entry keys is the desktop entry specification's own rule for keys it does not define, not a
  protocol parameter.

Apps do not announce themselves at run time (over D-Bus, notifications or sockets): those see only the apps that
happen to be running, race at login and go stale after a crash, and on the Mac a sandboxed app's messages to other
apps are restricted. Asking an app what it can do by sending it a link would start every participant.

# Sending

A sender offers **Show in *app*** for each other participant that announces the item's kind.

- It MUST find participants through the operating system ([Finding participants](#finding-participants)), and MUST
  NOT list itself.
- It MUST offer an app only for kinds its announcement lists, and only when its version is one the sender can send
  ([Versioning](#versioning)).
- It MUST show each participant by the name and icon the operating system gives for it (its bundle or desktop entry),
  never by anything in a link or in the announcement.
- It MUST send the link to that participant alone, never by opening the link with the scheme's default handler, which
  could be any participant.
- It sends a link only when the user asks, one item at a time.

# Receiving

A receiver shows what a link names.

- **Only showing.** Opening a crosslink MUST only navigate: open a page, select an item, reveal a file. It MUST NOT
  change, upload, download for keeping, share, delete or edit anything, and MUST NOT start a sign-in. Any web page can
  open a link with a registered scheme, so a link is always treated as coming from a stranger.
- **Checking.** Before anything is fetched, the receiver checks the link and ends in one of three results, each
  listed for every [test link](test-links.md):
  - *show:* a valid link with a path this draft defines, of a kind the receiver announced;
  - *cannot show:* a valid link whose path this draft does not define (a search by anything but `city` and
    `country` included), or of a kind the receiver did not announce: it tells the user so in a sentence;
  - *invalid:* anything else (another scheme, a host, a missing or empty `server`, a `server` that is not an
    absolute `http` or `https` URL with a host and without user information, query or fragment, a port that is not a
    number, an id or a `user` that is not a UUID, a malformed search): it does nothing, or tells the user the link is
    not valid.

  There is no fourth way: a receiver MUST NOT guess at a link it cannot read.
- **The account.** The receiver compares `server` with the servers it is signed in to: scheme, host in lower case,
  and port as a number (`0443` is `443`), with a scheme's default port the same as none, and any path without its
  trailing slash. With several
  accounts on that server it picks the one matching `user`, if given. Without a match it tells the user that it is not
  signed in to that server (naming the host), and does nothing else.
- **Nothing to show.** For an item the account cannot see, it tells the user so in a sentence, and does nothing else.
  An asset the account can see is always shown, if need be without the context its link gave.
- **Turned off.** If the user turned Immich Crosslink off ([Settings](#settings)), a received link only tells the user
  so, with a way to turn it on.

# Finding participants

A participant registers the scheme `immich-crosslink`, which delivers links to it, and announces itself. A sender
lists the apps registered for the scheme and keeps those with an announcement.

| Platform | Registering | Listing | Reading the announcement | Sending to one |
|---|---|---|---|---|
| macOS | `CFBundleURLTypes` with the scheme `immich-crosslink` in Info.plist | `NSWorkspace.urlsForApplications(toOpen:)` with an `immich-crosslink:` URL | `Bundle(url:).infoDictionary["ImmichCrosslink"]` | `NSWorkspace.open(_:withApplicationAt:configuration:)` |
| Linux (GNOME, KDE and others) | `MimeType=x-scheme-handler/immich-crosslink;` in the desktop entry | `g_app_info_get_all_for_type("x-scheme-handler/immich-crosslink")` (GIO), `KApplicationTrader::queryByMimeType` (KDE) | `g_desktop_app_info_get_string`, `KService::property` | `g_app_info_launch_uris`, `KIO::ApplicationLauncherJob` |

- **When to read.** A sender reads the participants when it builds a menu that offers them, or keeps a list and drops
  it when the system says the installed apps may have changed: GIO's `GAppInfoMonitor` `changed` signal, KDE's
  `KSycoca::databaseChanged`. macOS gives no such signal; listing is cheap enough to do for each menu. A list is never
  kept across launches of the sender.
- **The default handler.** A link opened without naming an app (pasted into a browser, `open`, `xdg-open`) goes to
  whichever participant the system picks. Participants SHOULD NOT make themselves the scheme's default handler
  (`LSSetDefaultHandlerForURLScheme`, `xdg-mime default`), so that choice stays the user's.
- **macOS:** apps are found where Launch Services sees them, but a sandboxed sender reads another app's announcement
  only from a copy in `/Applications` (seen on macOS 27: copies in `~/Applications` or a build folder read as
  nothing). Participants SHOULD be installed in `/Applications`.
- **Flatpak.** A Flatpak app is a receiver like any other: its exported desktop entry carries the scheme and the
  announcement. From inside the sandbox it cannot list the other apps; it MAY offer one **Show in Another App…**
  through the OpenURI portal, which lets the user choose.
- **Other platforms** are not defined in draft 0.2. Proposals are welcome.
- **Schemes that are not this one.** Participants MUST NOT register `immich`, the scheme of Immich's own mobile app,
  and MUST NOT use `app.immich`, Immich's sign-in redirect, for crosslinks. (Some desktop apps handle `app.immich` for
  their own sign-in, as Immich's mobile app does; that is unrelated to this protocol.)

# Settings

Every participant's settings show the protocol the same way, so a user meets one name in every app:

- a switch labelled **Immich Crosslink**, on by default, with a **Read more** link beside it to
  <https://jakob.hviid.phd/immich-crosslink/>; the address itself is not shown;
- under it, the participants found, each with a switch, on by default.

Turning the main switch off stops the app from offering Show in *app* and from acting on received links. Turning one
participant off removes it from the app's menus. "Immich Crosslink" is a name and stays in English; "Read more" and
the words around them are translated. Messages about a link a participant received speak of "a link from another
app", keeping the name for the protocol.

# Copying links

A participant MAY offer **Copy Immich Link**, which copies the item's web address: it opens in any browser and in
Immich's own apps. A participant MAY also offer a link of its own scheme, for opening the item in itself. Copying a
crosslink is not recommended: pasted into a browser or a note, it opens with whichever participant the system picks.

# Security and privacy

- A crosslink tells the receiver which item the user picked, on which server. It is sent only when the user asks.
- Links carry no secret; anyone can make one. Receivers act on them only as [Receiving](#receiving) allows.
- Any app can register a custom scheme and announce itself; nothing proves who it is
  ([RFC 8252](https://www.rfc-editor.org/rfc/rfc8252)). It is listed by the name and icon the system gives, and
  receives only the links the user sends it.
- Senders find participants only through the system's own lists, never by probing, since platforms treat which apps
  are installed as private and may restrict it further.
- A copied web address shows the server's address, as any Immich link does.

# Versioning

- **Drafts (0.x)** may change anything. An app announces the draft it follows, and a sender sends only to apps
  announcing the same draft.
- **From 1.0,** changes within a major version only add: new paths, kinds, parameters and platforms. An app
  announces its major version (`1`), and a sender sends to any app announcing the same major. A receiver from an
  earlier 1.x keeps working, because it ignores parameters and kinds it does not know and says it cannot show paths
  it does not know.
- Links carry no version: the announcement says what the receiver follows.
- Changes are made as pull requests to the protocol's repository, and listed in the [changelog](changelog.md).

# Conformance

- The [test links](test-links.md) (`tests/links.json` in the repository) give the result every receiver must reach
  for each link, and the links senders must make for each item. Implementations test against them.
- Version 1.0 needs two independent implementations, one sending to the other and back, passing the test links
  ([Roadmap](roadmap.md)).

# Relation to Immich

Immich Crosslink is an independent, unofficial project. It is not affiliated with, endorsed by, or sponsored by the
Immich project or FUTO. "Immich" is used only to describe the server the apps work with, and remains the mark of its
owner.

The protocol follows Immich's own paths on purpose, so a crosslink, an Immich web address and an Immich mobile deep
link name an item the same way. Should Immich define desktop deep links of its own, this protocol means to follow
them.
