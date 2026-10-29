# Recording cache refresh benchmark

Use Flutter **3.47.7** from `.fvmrc`. The same runner is used by the host test and
by the simulator app. It overrides the API and storage providers: no network,
application settings, tokens, or existing saved media are read. Each invocation
creates and removes its own directory, seeds 3000 recordings, warms up, then
runs three trials each with 0, 30 and 3000 changed recordings. The timer covers
`MediaListNotifier.refreshFromServer`, cache comparison/replacement, the disk
reload and sorting. Seeding and verification are outside the timer.

`CACHE_BENCH` JSON lines contain every duration in milliseconds, the median and
mtime-based rewrite counts. This is a client cache benchmark, not a server,
network, UI frame-time or production release-build benchmark.

## Prepare before and after checkouts

Start in an isolated checkout of the draft PR branch. These commands create a
separate clone for the baseline, copying only the benchmark harness from the PR.
The baseline application sources remain at develop `c290216` (version 3.9.1).

```sh
flutter --version
CACHE_BENCH_AFTER="$PWD"
CACHE_BENCH_WORK=$(mktemp -d "${TMPDIR:-/tmp}/ilovlya-cache-bench.XXXXXX")
CACHE_BENCH_BEFORE="$CACHE_BENCH_WORK/before"
git clone git@github.com:almaz-uno/ilovlya-ui.git "$CACHE_BENCH_BEFORE"
git -C "$CACHE_BENCH_BEFORE" switch --detach c290216
git archive HEAD tool | tar -x -C "$CACHE_BENCH_BEFORE"
(cd "$CACHE_BENCH_BEFORE" && flutter pub get)
(cd "$CACHE_BENCH_AFTER" && flutter pub get)
```

## Linux or macOS host

Choose an existing parent directory on the filesystem to measure; the runner
creates and deletes a unique child there. Use the same filesystem for both runs.
A macOS host test is **not** an iOS simulator result.

```sh
CACHE_BENCH_DISK="$CACHE_BENCH_WORK"
(cd "$CACHE_BENCH_BEFORE" && ILOVLYA_CACHE_BENCHMARK_ROOT="$CACHE_BENCH_DISK" flutter test --no-pub tool/benchmark_cache_refresh.dart) | tee "$CACHE_BENCH_WORK/before-host.log"
(cd "$CACHE_BENCH_AFTER" && ILOVLYA_CACHE_BENCHMARK_ROOT="$CACHE_BENCH_DISK" flutter test --no-pub tool/benchmark_cache_refresh.dart) | tee "$CACHE_BENCH_WORK/after-host.log"
grep CACHE_BENCH "$CACHE_BENCH_WORK/"*-host.log
```

On Linux, prefix each `flutter test` with `memcap -m 6G --`. On macOS run the two
heavy steps sequentially. Retain logs with the PR measurements before removing
the temporary baseline clone.

## Inside an iOS simulator on macOS

Use a dedicated test simulator; launching the harness installs the app with the
project's bundle identifier on that simulator. No physical iPhone is needed.
Get the chosen simulator's UDID from `flutter devices` or
`xcrun simctl list devices booted`, then set it explicitly:

```sh
SIMULATOR_UDID='<dedicated simulator UDID>'
(cd "$CACHE_BENCH_BEFORE" && flutter run --debug -d "$SIMULATOR_UDID" --target tool/benchmark_cache_refresh_app.dart) | tee "$CACHE_BENCH_WORK/before-ios.log"
```

Wait for three result JSON lines and `CACHE_BENCH complete`, then press `q` to
stop the first app, or Ctrl-C when `flutter run` has no terminal on stdin and `q`
does nothing. Next run:

```sh
(cd "$CACHE_BENCH_AFTER" && flutter run --debug -d "$SIMULATOR_UDID" --target tool/benchmark_cache_refresh_app.dart) | tee "$CACHE_BENCH_WORK/after-ios.log"
```

Again wait for `CACHE_BENCH complete` and press `q` (or Ctrl-C). Extract the result lines:

```sh
grep CACHE_BENCH "$CACHE_BENCH_WORK/"*-ios.log
```

The app uses its private simulator temporary directory, and displays success or
failure on screen. It executes the actual native Dart cache code, rather than a
host `flutter test`. Report simulator model, simulated iOS, macOS, Flutter,
before/after commits, all three medians and rewrite counts. Keep build mode and
simulator the same for before and after. The iOS run requires Xcode and has not
been executed on the Linux development machine.
