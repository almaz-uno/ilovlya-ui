# macOS release: signing, notarization and packaging

Groundwork for #197 «Build and release a notarized macOS app». It records what
the macOS build contains, what it has to be signed with, and the steps a
Codemagic workflow has to run. The signing identity, the notarization key and
the Codemagic configuration belong to the owner and are not part of the
repository.

Findings are from `flutter build macos --release` of develop 643069b with
Flutter 3.47.7 and Xcode 26.6 on an M4 Mac, macOS 26.5.

## Entitlements

`Release.entitlements` is the set the release is signed with:

| Key | Why |
| --- | --- |
| `com.apple.security.app-sandbox` | Kept: everything the app reads or writes is inside its container (see below). |
| `com.apple.security.network.client` | The API, downloads, thumbnails and Google Fonts. Without it every connection fails with `EPERM` (`Operation not permitted`), loopback included. |
| `com.apple.security.network.server` | Playback while downloading: `PartialSource` registers the arriving file with `LocalMediaEndpoint`, which listens on `127.0.0.1` on a port the system chooses, and libmpv reads the download from it with `Range` requests. A sandboxed app may not listen, loopback included, without this key: `bind()` to `127.0.0.1` fails with `EPERM`. |

`DebugProfile.entitlements` has the same keys plus `com.apple.security.cs.allow-jit`,
which the Dart VM needs in debug.

Not needed, and left out:

- `com.apple.security.files.user-selected.*`, `com.apple.security.files.downloads.*`:
  the app has no file picker, and data and media default to
  `~/Library/Containers/uno.almaz.ilovlya/Data/Documents/ilovlya/{data,media}`
  (`getApplicationDocumentsDirectory()` inside the sandbox). macOS offers no
  other media directory.
- `com.apple.security.device.camera`: the QR scanner for TV pairing is offered
  on Android and iOS only (`TvPairingView._canScan`).
- `com.apple.security.cs.allow-jit`, `com.apple.security.cs.allow-unsigned-executable-memory`:
  the release is AOT-compiled Dart, and libmpv is built with
  `-Dlua=disabled -Djavascript=disabled`. A harness linked against the app's own `Mpv.framework`, signed
  with the hardened runtime and none of these keys, played an H.264/AAC file
  to the end with software decoding and with `videotoolbox-copy`, on arm64 and
  on x86_64 under Rosetta.
- `com.apple.security.cs.disable-library-validation`: every framework is signed
  with the app's Developer ID, so the Team IDs match. It is needed only for a
  local test of an ad-hoc build with the hardened runtime: an ad-hoc signature
  has no Team ID, and dyld refuses the first framework with "mapping process
  and mapped file (non-platform) have different Team IDs".
- `com.apple.security.get-task-allow`: Xcode injects it into ad-hoc builds.
  Notarization rejects it. Signing with an explicit entitlements file (below)
  drops it.

### Sandbox outside the Mac App Store

A Developer ID app does not have to be sandboxed; only the hardened runtime is
required for notarization. The sandbox is kept because:

- nothing the app does needs access outside the container;
- the data location stays the same for debug and release builds, and for a
  later Mac App Store build;
- dropping it would move the data to `~/Documents/ilovlya`, which is in the
  user's own Documents folder.

Still to check by hand: «Show in folder» runs `open -R <file>` through
`Process.run`, and the child inherits the sandbox.

### Hardened runtime

The project does not set `ENABLE_HARDENED_RUNTIME`, on purpose: a local
`flutter build macos` is signed ad-hoc, and with the hardened runtime such a
build does not start (the Team ID check above). The release script turns it
on with `--options runtime`.

## Embedded code

`find ilovlya.app -type f` and `file` find 23 Mach-O files, all universal
(`x86_64 arm64`). Swift Package Manager plugins are linked into the main
executable; their `Resources/*.bundle` hold resources only.

| Path in `Contents/` | Origin | `minos` |
| --- | --- | --- |
| `MacOS/ilovlya` | Runner and SwiftPM plugins | 12.0 |
| `Frameworks/App.framework` | Dart AOT code | 12.0 |
| `Frameworks/FlutterMacOS.framework` | Flutter engine | 12.0 |
| `Frameworks/media_kit_video.framework` | media_kit_video (CocoaPods) | 12.0 |
| `Frameworks/media_kit_libs_macos_video.framework` | media_kit_libs_macos_video (CocoaPods) | 12.0 |
| `Frameworks/Mpv.framework` | libmpv-darwin-build v0.6.0 | 11.0 |
| `Frameworks/{Avcodec,Avfilter,Avformat,Avutil,Swresample,Swscale}.framework` | FFmpeg, same archive | 11.0 |
| `Frameworks/{Ass,Dav1d,Freetype,Fribidi,Harfbuzz,Mbedcrypto,Mbedtls,Mbedx509,Png16,Uchardet,Xml2}.framework` | mpv dependencies, same archive | 11.0 |

The mpv frameworks come as unsigned xcframeworks. The archive is fetched from
`github.com/media-kit/libmpv-darwin-build` by the package's Makefile, which
checks its SHA-256. None of them links outside `/System`, `/usr/lib` or
`@rpath`.

All of them have to be signed with the Developer ID, a secure timestamp and the
hardened runtime. The build does not do it:

- `Pods-Runner-frameworks.sh` signs the pods' frameworks with
  `codesign --force --sign … ${OTHER_CODE_SIGN_FLAGS}`, that is without
  `--timestamp`, and notarization rejects code without a secure timestamp;
- the build is signed ad-hoc anyway.

So the release script signs every framework, then the app, from the inside
out. It does not use `codesign --deep`, which signs nested code with the
outer item's options and hides the order.

### Architectures

All the code is universal, so a universal app costs only size: the `.app`
is about 100 MB, of which 95 MB is code, and the arm64 slices are 46 MB of it. macOS 12 still
runs on Intel Macs, so the release stays universal unless the owner decides
otherwise.

## Minimum macOS version

The deployment target is 12.0 since #190 «Commit the macOS project migration»,
and `LSMinimumSystemVersion` follows it. The highest `minos` in the bundle is
12.0, set by the Flutter engine, so the engine is what sets the minimum. The
plugins declare 10.9–10.15, the mpv frameworks 11.0.

## Codemagic workflow (draft)

Triggered by a release tag, on a Mac instance with Xcode 26 and the Flutter
that `.fvmrc` pins (checked first, as `flatpak-build.yml` does for the Flatpak
recipe).

1. Build:

   ```sh
   flutter pub get
   flutter build macos --release --build-name="${TAG#v}"
   APP=build/macos/Build/Products/Release/ilovlya.app
   ```

2. Put the Developer ID certificate into a temporary keychain
   (`keychain initialize`, `keychain add-certificates`), and take its name:
   `IDENTITY="Developer ID Application: … (TEAMID)"`.

3. Sign from the inside out:

   ```sh
   for fw in "$APP"/Contents/Frameworks/*.framework; do
     codesign --force --timestamp --options runtime --sign "$IDENTITY" "$fw"
   done
   codesign --force --timestamp --options runtime \
     --entitlements macos/Runner/Release.entitlements \
     --sign "$IDENTITY" "$APP"
   codesign --verify --strict --verbose=2 "$APP"
   codesign -d --entitlements - "$APP"   # no get-task-allow
   ```

4. Notarize the app and staple it, so a copy taken out of the DMG opens
   offline:

   ```sh
   ditto -c -k --keepParent "$APP" ilovlya.zip
   xcrun notarytool submit ilovlya.zip --wait \
     --key "$KEY_PATH" --key-id "$APP_STORE_CONNECT_KEY_IDENTIFIER" \
     --issuer "$APP_STORE_CONNECT_ISSUER_ID"
   xcrun stapler staple "$APP"
   ```

   On failure, `xcrun notarytool log <submission id> …` gives the reason.

5. Package, sign, notarize and staple the DMG:

   ```sh
   DMG="ilovlya-$TAG-macos.dmg"
   hdiutil create -volname ilovlya -srcfolder "$APP" -ov -format UDZO "$DMG"
   codesign --force --timestamp --sign "$IDENTITY" "$DMG"
   xcrun notarytool submit "$DMG" --wait --key … --key-id … --issuer …
   xcrun stapler staple "$DMG"
   spctl -a -t open --context context:primary-signature -vv "$DMG"
   spctl -a -t exec -vv "$APP"
   ```

6. Attach it to the release, as `flatpak.yml` does with the bundle:

   ```sh
   gh release upload "$TAG" "$DMG" --clobber --repo almaz-uno/ilovlya-ui
   ```

   A tag build can start before the release is published; the step has to
   wait for the release, or the workflow has to start on its publication.

## What the owner provides

- The Developer ID Application certificate with its private key (`.p12` and
  its password), as a Codemagic code signing identity; and the Team ID.
- An App Store Connect API key for `notarytool`: the `.p8` file, its Key ID and
  the Issuer ID (Codemagic's `APP_STORE_CONNECT_PRIVATE_KEY`,
  `APP_STORE_CONNECT_KEY_IDENTIFIER`, `APP_STORE_CONNECT_ISSUER_ID`).
- A GitHub token allowed to upload release assets to `almaz-uno/ilovlya-ui`
  (`contents: write`), for step 6.
- Decisions: DMG or zipped `.app`; universal or arm64 only; the copyright line
  (`PRODUCT_COPYRIGHT` in `Configs/AppInfo.xcconfig` still reads
  «Copyright © 2023 com.example»).

## Still open

- Gatekeeper on a Mac that never ran the app: needs the signed and notarized
  artifact.

## Checked against production

A release build with these entitlements, re-signed ad-hoc with the hardened
runtime, under a temporary bundle id:

- the owner signed in, and the list of 3221 recordings arrived;
- one recording was downloaded to the client while it played: 190 MB arrived in
  the container's `media/.partial` and was moved into `media/` in about 20 s;
- `LocalMediaEndpoint` listened on `127.0.0.1` and libmpv held two connections
  to it;
- the owner saw the video and heard the sound.

## Observations

- Without a token the app keeps polling `GET /api/recordings` and gets `401`:
  about 250 requests in two hours of waiting at the sign-in. A fresh install
  does the same against the production server until the user signs in.
- On macOS the recording screen keeps logging `MPV IPC error` for
  `/tmp/<recording id>`: it polls the socket of an external mpv that is only
  ever started through `flatpak-spawn` on Linux.
- Lists did not scroll with a trackpad or a Magic Mouse; fixed by #216
  «Lists do not scroll with a trackpad or a Magic Mouse on macOS».
