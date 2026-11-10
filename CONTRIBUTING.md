# Contributing

immich-crosslink grows by proposals from the apps that use it. Changes are made as pull requests to this repository.

## Adding your app

Implement [the protocol](docs/spec.md), then open a pull request adding a row to
[the participants](docs/participants.md): the app and a link to it, its platforms, what it sends and receives, the
draft it follows, and its status (planned, or released in a version).

## Changing the protocol

1. **Open an issue first** for anything beyond a wording fix: what you need, for which app, and an example link.
2. **Then a pull request** changing [docs/spec.md](docs/spec.md), the [test links](tests/links.json) that show the
   change, the [implementation guide](docs/implementing.md) where it shows it, and the
   [changelog](docs/changelog.md).

What a change should keep:

- **Links only show.** A receiver never changes, shares or deletes anything because of a link.
- **Immich's own paths.** A new kind of item uses the path Immich's web app uses for it. Where Immich has none, say so
  in the issue.
- **Additions, not changes.** From 1.0, a change within a major version only adds: a path, an optional parameter, a
  platform. Until then, drafts may change anything, but a change that breaks existing links names the participants
  it affects.
- **Every platform.** A rule that applies to one platform says how the others meet it, or why they cannot.

## Writing

- Plain words, short sentences. The protocol's normative words (MUST, SHOULD, MAY) are in capitals and used only
  where meant.
- Describe the protocol as it is, not its history; history goes in the changelog and the commit message.
- No em-dashes: use a comma, a colon, parentheses or a new sentence.

## Building the site

The site is built from `docs/` with [pandoc](https://pandoc.org) (3.1 or later):

```sh
./build.sh          # writes _site/
```

The site's GitHub Actions workflow builds and publishes it on every push to `main`.

## License

By contributing you agree that your contributions to the protocol and its documentation are licensed under CC BY 4.0,
and code under the MIT License, as the rest of the repository ([README](README.md#license)).
