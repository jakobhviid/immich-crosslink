# immich-crosslink

**Links between [Immich](https://immich.app) apps on the same computer.** A small, open protocol: every participating
app registers the URL scheme `immich-crosslink`, finds the others through the operating system, and offers
**Show in *app*** for a photo, album, person or place, named the way Immich's own web app names it.

```
immich-crosslink:///albums/<album>/photos/<asset>?server=https%3A%2F%2Fphotos.example.com
```

Read it at **<https://jakob.hviid.phd/immich-crosslink/>**:

- [The protocol](docs/spec.md) (draft 0.1)
- [Implementing it](docs/implementing.md) on macOS, GNOME and KDE, with code
- [Participants](docs/participants.md)
- [Changelog](docs/changelog.md)

## Status

Draft 0.1, being designed. Anything may change before 1.0; from 1.0, changes within a major version only add. See
[Versioning](docs/spec.md#versioning).

## Taking part

Implement the protocol, then add your app to [the participants](docs/participants.md). To change the protocol, open
an issue or a pull request: [CONTRIBUTING.md](CONTRIBUTING.md).

## Not affiliated with Immich

immich-crosslink is an independent, unofficial project. It is not affiliated with, endorsed by, or sponsored by the
Immich project or FUTO. "Immich" is used only to describe the server the apps work with, and remains the mark of its
owner.

## AI disclosure

Parts of this project were written with the assistance of AI coding agents (Claude Code and others). All changes are
reviewed by the maintainer. This is the single place that fact is disclosed; it is deliberately kept out of the commit
history.

## License

The protocol and its documentation are licensed under
[Creative Commons Attribution 4.0 International](LICENSE) (CC BY 4.0). The code, the examples in the documentation
and the site's build files are licensed under the [MIT License](LICENSE-CODE).
