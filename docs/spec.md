---
title: The Immich Crosslink protocol
subtitle: Version 1.0
---

**Status:** version 1.0. Changes within version 1 only add (see [Versioning](#versioning)). Proposals are welcome as issues and pull requests on
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
- **Announcement:** what an app installs with itself to take part: the version it follows and the kinds it can show
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
app also takes as deep links through `my.immich.app`. Version 1.0 defines these:

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

- `Version` is the version the app follows: `0.2` for version 1 ([Versioning](#versioning)).
- `Shows` lists the kinds it can show. An app that shows assets MUST list `asset`, and MUST then take an asset's
  link with any context (showing the asset alone where it has no such view).
- Readers MUST ignore kinds they do not know, and treat an announcement without a version they understand as absent.
- The `X-` in the desktop entry keys is the desktop entry specification's own rule for keys it does not define, not a
  protocol parameter.

Apps do not announce themselves at run time (over D-Bus, notifications or sockets): those see only the apps that
happen to be running, race at login and go stale after a crash, and on the Mac a sandboxed app's messages to other
apps are restricted. Asking an app what it can do by sending it a link would start every participant.

# Sending

A sender SHOULD offer **Show in *app*** for each other participant that announces the item's kind: one menu item per
app, by its name and icon. Where it cannot, because its menu's items are fixed when it is installed (Finder's File
Provider actions) or because it cannot list the other apps (a Flatpak sandbox), it MAY offer one **Show in Another
App…** instead:

- offered only while at least one participant shows the item's kind;
- with one, it sends to that app straight away;
- with several, it lets the user choose among them, by their names and icons, and sends nothing if the user cancels.
  It MAY leave the choosing to the system (the OpenURI portal with `ask`), which then decides how it looks.

A participant MAY present Show in some other way, as long as it meets the rules below. Where it uses a menu item, the
item reads **Show in *app*** or **Show in Another App…**, translated, so a user meets the same words in every app.

- It MUST find participants through the operating system ([Finding participants](#finding-participants)), and MUST
  NOT list itself.
- It MUST offer an app only for kinds its announcement lists, and only when its version is one the sender can send
  ([Versioning](#versioning)).
- It MUST show each participant by the name and icon the operating system gives for it (its bundle's display name or
  desktop entry), never by anything in a link or in the announcement.
- It MUST send the link to that participant alone, never by opening the link with the scheme's default handler, which
  could be any participant.
- It sends a link only when the user asks, one item at a time.
- It leaves out an app that cannot start (its program missing). If sending fails, because the app was removed since
  the list was read or the system cannot open it, it tells the user so, and reads the list again.

# Receiving

A receiver shows what a link names.

- **Only showing.** Opening a crosslink MUST only navigate: open a page, select an item, reveal a file. It MUST NOT
  change, upload, download for keeping, share, delete or edit anything, and MUST NOT start a sign-in. Any web page can
  open a link with a registered scheme, so a link is always treated as coming from a stranger.
- **Checking.** Before anything is fetched, the receiver checks the link and ends in one of three results, each
  listed for every [test link](test-links.md):
  - *show:* a valid link with a path this version defines, of a kind the receiver announced;
  - *cannot show:* a valid link whose path this version does not define (a search by anything but `city` and
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

A participant is **found** when the sender can list it, read its announcement, and start it: its program is there.
An app that is installed is found whether or not it was ever started, as the system's own Open With and share menus
list it; one that has no account yet says so when a link arrives ([Receiving](#receiving)). Each platform has ways for
an app to look present when it is not, and those read as not found:

- **macOS:** Launch Services keeps registrations of copies that were deleted or moved (a build folder, an old
  download); a copy whose executable is missing cannot start. A sandboxed sender reads an announcement only in
  `/Applications` (below), so a copy elsewhere cannot be read.
- **Linux:** a desktop entry may outlive its program (an app installed by hand, an AppImage); its `TryExec`, or else
  the program of its `Exec`, must exist. An entry with `Hidden=true` is not there at all.

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
  ([Sending](#sending)) through the OpenURI portal, which lets the user choose.
- **Other platforms** are not defined in version 1.0. Proposals are welcome.
- **Schemes that are not this one.** Participants MUST NOT register `immich`, the scheme of Immich's own mobile app,
  and MUST NOT use `app.immich`, Immich's sign-in redirect, for crosslinks. (Some desktop apps handle `app.immich` for
  their own sign-in, as Immich's mobile app does; that is unrelated to this protocol.)

# Settings

Every participant's settings show the protocol the same way, so a user meets one name in every app:

- a switch labelled **Immich Crosslink**, on by default, with a **Learn more…** link to
  <https://jakob.hviid.phd/immich-crosslink/>, the address itself not shown. Where the platform's settings end a
  description with such a link (macOS), it ends the switch's description; elsewhere it stands beside the switch
  (**Learn More** on GNOME and KDE, as their buttons are written);
- under it, the participants seen, each by its name and icon with a switch, on by default; one not found also reads
  **Not found** and has a **Forget** button;
- under them, a description of what the switches and Forget do. It is OPTIONAL, but worth having, since a user meets
  Forget only once an app has gone. For example: "Apps that take part are found by themselves. Turn one off to leave
  it out of Show in. One not found stays listed for 30 days, so it stays off if it comes back; Forget removes it
  now."
- with none seen, a sentence saying so, which MAY link to the [participants](participants.md).

**Participants that come and go.** It works like pairing devices, except that pairing is automatic: an app that is
found is listed, the switch is the user's lasting choice, and an app that has gone is remembered until the user, or
time, forgets it.

- A participant is *seen* whenever the app finds it ([Finding participants](#finding-participants)); the app keeps,
  per bundle id or desktop entry id, its name and when it was last seen. Where it keeps them is the app's own choice:
  they are the app's state, not a setting.
- One that is not found now ([Finding participants](#finding-participants)) is listed as **Not found**, by its
  remembered name and a generic app icon, and keeps its switch, so one switched off stays off if it comes back. Not
  found rather than not installed: an app may be installed and no longer announce itself, or be where the sender
  cannot read it.
- One not seen for 30 days is forgotten on its own.
- **Forget** is offered on a participant not found, and only there. Forgetting, by hand or after 30 days, drops what
  the app remembers of it and its switch, so one that comes back afterwards is new, and on. A participant that is
  found has no Forget: its announcement is installed with it, so it would be found again at once, and Forget would
  only turn it back on. Its switch is the control, and removing the app is the way to make it go.
- Menus offer only participants found now.

Turning the main switch off stops the app from offering Show in *app* and from acting on received links. Turning one
participant off removes it from the app's menus. No participant is set apart: a sender lists, offers and names every
participant the same way, whoever made it. "Immich Crosslink" is a name and stays in English; "Learn more…" and the
words around them are translated. Messages about a link a participant received speak of "a link from another app",
keeping the name for the protocol.

# Copying links

A participant MAY offer **Copy Immich Link**, which copies the item's web address: it opens in any browser and in
Immich's own apps, and **Open in Immich**, which opens it in the default browser. One that offers them SHOULD let the
user turn both off with one switch, **Open in Immich and Copy Immich Link**, apart from the Immich Crosslink switch. A participant MAY also offer a link of its own scheme, for opening the item in itself. Copying a
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

- **Drafts (0.1, 0.2)** could change anything. An app announced the draft it followed, and a sender sent only to apps
  announcing the same draft.
- **1.0** is draft 0.2, unchanged. Its announcement keeps the value `0.2`, as the released apps announce it: in
  version 1, `0.2` names the major version, and a sender sends to any app announcing it. A later major version
  announces its number (`2`).
- **Within version 1,** changes only add: new paths, kinds, parameters and platforms. A receiver from an earlier 1.x
  keeps working, because it ignores parameters and kinds it does not know and says it cannot show paths it does not
  know.
- Links carry no version: the announcement says what the receiver follows.
- Changes are made as pull requests to the protocol's repository, and listed in the [changelog](changelog.md).

# Conformance

- The [test links](test-links.md) (`tests/links.json` in the repository) give the result every receiver must reach
  for each link, and the links senders must make for each item. Implementations test against them.
- Version 1.0 needed two independent implementations, one sending to the other and back, passing the test links.
  Immich Mount and Immich Gallery met it ([Roadmap](roadmap.md)).

# Relation to Immich

Immich Crosslink is an independent, unofficial project. It is not affiliated with, endorsed by, or sponsored by the
Immich project or FUTO. "Immich" is used only to describe the server the apps work with, and remains the mark of its
owner.

The protocol follows Immich's own paths on purpose, so a crosslink, an Immich web address and an Immich mobile deep
link name an item the same way. Should Immich define desktop deep links of its own, this protocol means to follow
them.
