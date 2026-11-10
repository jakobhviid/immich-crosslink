---
title: Implementing immich-crosslink
subtitle: For draft 0.1
---

This page shows the platform parts: registering the scheme, finding the other participants, sending a link to one,
and receiving one. What a link means, and what a receiver may and may not do with it, is in
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

**Registering.** In the app's Info.plist:

```xml
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

/// The other apps that take crosslinks, by the system's name for them.
func participants() -> [(name: String, url: URL)] {
    guard let probe = URL(string: "immich-crosslink:///photos") else { return [] }
    let ownID = Bundle.main.bundleIdentifier
    return NSWorkspace.shared.urlsForApplications(toOpen: probe)
        .filter { Bundle(url: $0)?.bundleIdentifier != ownID }
        .map { (FileManager.default.displayName(atPath: $0.path), $0) }
}

/// Sends the link to that app alone, never to the scheme's default handler.
func send(_ link: URL, to app: URL) {
    NSWorkspace.shared.open([link], withApplicationAt: app, configuration: NSWorkspace.OpenConfiguration())
}
```

The menu item's icon is `NSWorkspace.shared.icon(forFile: app.path)`.

**Receiving,** in the app delegate:

```swift
func application(_ application: NSApplication, open urls: [URL]) {
    for url in urls where url.scheme == "immich-crosslink" {
        // Check the path and ids, match `server` (and `user`) to an account, then only show the item.
    }
}
```

# Linux: GNOME, KDE and others

**Registering.** In the app's desktop entry, beside its other MIME types, with `%u` in `Exec` so the link reaches the
app:

```ini
[Desktop Entry]
Name=Example Photos
Exec=example-photos %u
MimeType=x-scheme-handler/immich-crosslink;
```

Packages run `update-desktop-database` after installing, as they do for any MIME type. `gio mime
x-scheme-handler/immich-crosslink` lists the apps that registered it.

**Finding the others and sending to one, with GIO** (C; the same calls exist in every GObject binding):

```c
#include <gio/gio.h>

/* Show in <app> for each participant but this one, by the system's name and icon. */
GList *apps = g_app_info_get_all_for_type ("x-scheme-handler/immich-crosslink");
for (GList *l = apps; l != NULL; l = l->next) {
    GAppInfo *app = l->data;
    if (g_strcmp0 (g_app_info_get_id (app), "org.example.Photos.desktop") == 0)
        continue;
    const char *name = g_app_info_get_display_name (app);
    GIcon *icon = g_app_info_get_icon (app);
    /* ... add a menu item; on activation: */
    GList *uris = g_list_append (NULL, (gpointer) link);
    g_app_info_launch_uris (app, uris, NULL, NULL);
    g_list_free (uris);
}
g_list_free_full (apps, g_object_unref);
```

**With KDE Frameworks** (C++):

```cpp
#include <KApplicationTrader>
#include <KIO/ApplicationLauncherJob>

const KService::List apps = KApplicationTrader::queryByMimeType(
    QStringLiteral("x-scheme-handler/immich-crosslink"));
for (const KService::Ptr &app : apps) {
    if (app->desktopEntryName() == QLatin1String("org.example.photos"))
        continue;
    // app->name(), app->icon() for the menu item; on activation:
    auto *job = new KIO::ApplicationLauncherJob(app);
    job->setUrls({QUrl(link)});
    job->start();
}
```

**Receiving:** the link arrives as the `%u` argument. Check it, match the account, and only show the item.

**Flatpak.** A Flatpak app's exported desktop entry carries its `MimeType`, so it receives links. From inside the
sandbox it cannot list the other apps; offer one **Show in Another App…** that opens the link through the OpenURI
portal with `ask` set, so the user chooses.

# Trying it

With a participant installed, open a link by hand:

```sh
open 'immich-crosslink:///photos?server=https%3A%2F%2Fdemo.immich.app'       # macOS
xdg-open 'immich-crosslink:///photos?server=https%3A%2F%2Fdemo.immich.app'   # Linux
```

With several participants installed this opens whichever the system picks, which is why participants send to one app
by name. Add your app to [the participants](participants.md) once it takes part.
