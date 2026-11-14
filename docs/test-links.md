---
title: Test links
subtitle: For version 1.0
---

The test links are the protocol's examples with their answers, for implementations to test against. They live in
[`tests/links.json`](https://github.com/jakobhviid/immich-crosslink/blob/main/tests/links.json), a file meant to be
read by tests. Fetch it at the commit or tag of the version you implement.

# What the file holds

- **`make`:** items, each with a server address (and sometimes a user), and the Immich path and link a sender must
  make for it, byte for byte. Searches are encoded exactly as Immich's web app encodes them.
- **`read`:** links, each with the result a receiver must reach:
  - `show`, with the `kind`, the Immich `path` (ids in lower case), the `server` address as it compares (host in
    lower case, no default port, no trailing slash) and the `user`, if any;
  - `cannot-show`: a valid link this version has no path for;
  - `invalid`: not a valid link.

  The results assume a receiver that announces every kind. One that announces fewer reaches `cannot-show` for the
  others.

Some `read` links carry parameters this version does not define. A receiver MUST ignore them and still reach `show`:
they are there so every implementation ignores unknown parameters from the start, rather than only in theory.

# Using it

```sh
curl -LO https://raw.githubusercontent.com/jakobhviid/immich-crosslink/main/tests/links.json
```

For each `make` entry, build the link from `item`, `server` and `user` and compare it with `link`. For each `read`
entry, read `link` and compare the result, and for `show` the kind, path, server and user.

# Adding test links

A change to the protocol adds the test links that show it, in the same pull request. A bug found in an
implementation, where the protocol was unclear, adds the link that would have caught it.
