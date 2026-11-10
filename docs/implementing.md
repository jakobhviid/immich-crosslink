---
title: Implementing immich-crosslink
subtitle: For draft 0.2
---

This page shows the platform parts: announcing the app, registering the scheme, finding the other participants and
what they show, sending a link to one, and receiving one. What a link means, and what a receiver may and may not do with it, is in
[the protocol](spec.md). The code is MIT-licensed; copy it freely.

# Making links

A link is `immich-crosslink://`, the Immich path, and the server's address. Values are encoded as JavaScript's
`encodeURIComponent` does, and a search is the JSON Immich's web app writes (see [Immich paths](spec.md#immich-paths)):

```swift
import Foundation

/// The characters `encodeURIComponent` leaves as they are.
private let unreserved = CharacterSet(charactersIn:
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.!~*'()")

func encodeComponent(_ value: String) -> String {
    value.addingPercentEncoding(withAllowedCharacters: unreserved) ?? value
}

/// `path` is an Immich path; a search's `query` in it is already encoded.
func crosslink(path: String, server: String, user: String? = nil) -> URL? {
    var link = "immich-crosslink://" + path + (path.contains("?") ? "&" : "?") + "server=" + encodeComponent(server)
    if let user { link += "&user=" + encodeComponent(user) }
    return URL(string: link)
}

/// A place's Immich path: `{"city":…,"country":…}` as `JSON.stringify` writes it.
func placePath(city: String?, country: String) -> String {
    struct Search: Encodable { let city: String?; let country: String }  // nil keys are left out
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]  // "city" sorts before "country"
    let json = (try? encoder.encode(Search(city: city, country: country))).flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
    return "/search?query=" + encodeComponent(json)
}
```

`placePath(city: "Aarhus", country: "Denmark")` gives
`/search?query=%7B%22city%22%3A%22Aarhus%22%2C%22country%22%3A%22Denmark%22%7D`, byte for byte what Immich's web app
writes for the same search. Receivers decode values whichever way they were encoded.

# macOS

**Announcing and registering.** In the app's Info.plist, the announcement and the scheme that delivers links:

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
        <string>place</string>
        <string>page</string>
    </array>
</dict>
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>immich-crosslink</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>immich-crosslink</string>
        </array>
    </dict>
</array>
```

**Finding the others and sending to one:**

```swift
import AppKit

struct Participant {
    let name: String
    let url: URL
    let shows: Set<String>
}

/// The other apps that announce themselves and take crosslinks, by the system's name for them. Cheap enough to call
/// each time a menu is built: macOS gives no signal when apps are installed or removed.
func participants(draft: String = "0.2") -> [Participant] {
    guard let probe = URL(string: "immich-crosslink:///photos") else { return [] }
    let ownID = Bundle.main.bundleIdentifier
    return NSWorkspace.shared.urlsForApplications(toOpen: probe).compactMap { url in
        guard let bundle = Bundle(url: url), bundle.bundleIdentifier != ownID,
              let announcement = bundle.infoDictionary?["ImmichCrosslink"] as? [String: Any],
              announcement["Version"] as? String == draft,
              let shows = announcement["Shows"] as? [String] else { return nil }  // no announcement: not a participant
        return Participant(name: FileManager.default.displayName(atPath: url.path), url: url, shows: Set(shows))
    }
}

/// Sends the link to that app alone, never to the scheme's default handler.
func send(_ link: URL, to app: URL) {
    NSWorkspace.shared.open([link], withApplicationAt: app, configuration: NSWorkspace.OpenConfiguration())
}
```

Offer **Show in *app*** only where `shows` holds the item's kind. The menu item's icon is
`NSWorkspace.shared.icon(forFile: app.path)`. A sandboxed app may not see apps outside `/Applications`.

**Receiving,** in the app delegate:

```swift
func application(_ application: NSApplication, open urls: [URL]) {
    for url in urls where url.scheme == "immich-crosslink" {
        // Check the path and ids, match `server` (and `user`) to an account, then only show the item.
    }
}
```

# Linux: GNOME, KDE and others

**Announcing and registering.** In the app's desktop entry: the announcement, and the scheme beside its other MIME
types, with `%u` in `Exec` so the link reaches the app:

```ini
[Desktop Entry]
Name=Example Photos
Exec=example-photos %u
MimeType=x-scheme-handler/immich-crosslink;
X-Immich-Crosslink-Version=0.2
X-Immich-Crosslink-Shows=asset;album;person;place;page;
```

Packages run `update-desktop-database` after installing, as they do for any MIME type. `gio mime
x-scheme-handler/immich-crosslink` lists the apps that registered it.

**Finding the others and sending to one, with GIO** (C; the same calls exist in every GObject binding):

```c
#include <gio/gio.h>

#include <gio/gdesktopappinfo.h>

/* Show in <app> for each participant but this one that shows the item's kind, by the system's name and icon. */
GList *apps = g_app_info_get_all_for_type ("x-scheme-handler/immich-crosslink");
for (GList *l = apps; l != NULL; l = l->next) {
    GAppInfo *app = l->data;
    if (!G_IS_DESKTOP_APP_INFO (app) || g_strcmp0 (g_app_info_get_id (app), "org.example.Photos.desktop") == 0)
        continue;
    GDesktopAppInfo *entry = G_DESKTOP_APP_INFO (app);
    g_autofree char *version = g_desktop_app_info_get_string (entry, "X-Immich-Crosslink-Version");
    g_auto (GStrv) shows = g_desktop_app_info_get_string_list (entry, "X-Immich-Crosslink-Shows", NULL);
    if (g_strcmp0 (version, "0.2") != 0 || shows == NULL || !g_strv_contains ((const char * const *) shows, kind))
        continue;  /* no announcement, another draft, or not this kind */
    const char *name = g_app_info_get_display_name (app);
    GIcon *icon = g_app_info_get_icon (app);
    /* ... add a menu item; on activation: */
    GList *uris = g_list_append (NULL, (gpointer) link);
    g_app_info_launch_uris (app, uris, NULL, NULL);
    g_list_free (uris);
}
g_list_free_full (apps, g_object_unref);
```

To keep the list between menus, drop it when the system says the installed apps may have changed:

```c
g_signal_connect (g_app_info_monitor_get (), "changed", G_CALLBACK (forget_participants), NULL);
```

The signal fires once until the next `g_app_info_*` call, and means "may have changed": forget the list and read it
again when it is next needed.

**With KDE Frameworks** (C++):

```cpp
#include <KApplicationTrader>
#include <KIO/ApplicationLauncherJob>

const KService::List apps = KApplicationTrader::queryByMimeType(
    QStringLiteral("x-scheme-handler/immich-crosslink"));
for (const KService::Ptr &app : apps) {
    if (app->desktopEntryName() == QLatin1String("org.example.photos"))
        continue;
    const QString version = app->property<QString>(QStringLiteral("X-Immich-Crosslink-Version"));
    const QStringList shows = app->property<QString>(QStringLiteral("X-Immich-Crosslink-Shows"))
                                  .split(QLatin1Char(';'), Qt::SkipEmptyParts);
    if (version != QLatin1String("0.2") || !shows.contains(kind))
        continue;  // no announcement, another draft, or not this kind
    // app->name(), app->icon() for the menu item; on activation:
    auto *job = new KIO::ApplicationLauncherJob(app);
    job->setUrls({QUrl(link)});
    job->start();
}
```

KDE's database of desktop entries changes behind `KSycoca::databaseChanged`, the place to forget a kept list.

**Receiving:** the link arrives as the `%u` argument. Check it, match the account, and only show the item.

**Flatpak.** A Flatpak app's exported desktop entry carries its `MimeType` and its announcement, so it receives
links. From inside the
sandbox it cannot list the other apps; offer one **Show in Another App…** that opens the link through the OpenURI
portal with `ask` set, so the user chooses.

# Testing

Test against the [test links](test-links.md): the links to make for each item, and the result to reach for each link.

With a participant installed, open a link by hand:

```sh
open 'immich-crosslink:///photos?server=https%3A%2F%2Fdemo.immich.app'       # macOS
xdg-open 'immich-crosslink:///photos?server=https%3A%2F%2Fdemo.immich.app'   # Linux
```

With several participants installed this opens whichever the system picks, which is why participants send to one app
by name. Add your app to [the participants](participants.md) once it takes part.
