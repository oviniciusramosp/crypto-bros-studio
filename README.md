# Crypto Bros Studio

A focused desktop writing tool for the Crypto Bros app, built by **embedding the
`appflowy_editor` package** (MPL-2.0 — keeps this app's code private; no Rust
backend) rather than forking the full AppFlowy monorepo (AGPL-3.0).

What it does:
- Write a post in a rich editor.
- Insert a **custom Chart block** (toolbar "Insert chart" or `/chart`) — a
  structured block with an edit form, so there's no `{{chart:...}}` text syntax
  to get wrong.
- See a **live preview** styled with the app's design tokens.
- **Publish** → serializes to the app-native format (`schema.json` in
  `crypto-bros-content`), splits at the first divider into `preview` + full
  `blocks`, and writes `index.json` + `posts/<id>.<locale>.json` to GitHub via
  the Contents API.

## Run it

> Requires the Flutter SDK (desktop enabled). This repo holds only `lib/` +
> `pubspec.yaml`; generate the platform folders on first run.

```bash
flutter create .            # generates macos/ (and other platforms)
flutter pub get
flutter run -d macos        # or -d windows / -d linux
```

On first **Publish** you'll be asked for a GitHub fine-grained PAT with
**Contents: read & write** on `oviniciusramosp/crypto-bros-content`. It's stored
in the OS keychain (`flutter_secure_storage`).

After publishing, the app (with `useStaticFeed: true`) shows the post — the full
loop: **write here → GitHub → app reads it**.

## Status / caveats

This is a v0.1 scaffold authored without a local Flutter toolchain to compile it,
so expect to run `flutter pub get` and possibly make small adjustments for the
pinned `appflowy_editor` ^6.2.0 API (the custom-block API has shifted across
versions — see `lib/chart_block.dart`). Known follow-ups:
- Slash-menu wiring for the chart item (the toolbar button is the reliable path).
- Rich title editing and image upload/re-hosting on publish (today: cover via URL).
- Inter font bundling for exact typography parity (`lib/tokens.dart`).

## Layout
- `lib/main.dart` — editor + live preview + toolbar.
- `lib/chart_block.dart` — the custom Chart block.
- `lib/lean.dart` — AppFlowy Document → app-native format serializer (divider split).
- `lib/preview.dart` — token-styled visual preview.
- `lib/publish.dart` — GitHub Contents API publish + metadata dialog.
- `lib/tokens.dart` — design tokens mirrored from the RN app.
