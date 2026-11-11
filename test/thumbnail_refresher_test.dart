import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ilovlya/src/media/thumbnail_refresher.dart';

/// The refresher with a capture that records the position it starts at. The tests run in the fake time of
/// `testWidgets`, which `tester.pump` advances.
class _Rig {
  _Rig({bool Function()? canCapture}) {
    refresher = ThumbnailRefresher(
      canCapture: canCapture ?? () => true,
      capture: () async {
        taken.add(position);
        final gate = this.gate;
        if (gate != null) await gate.future;
        return true;
      },
    );
  }

  late final ThumbnailRefresher refresher;
  final taken = <Duration>[];
  Duration position = Duration.zero;
  Completer<void>? gate;

  void at(int seconds) {
    position = Duration(seconds: seconds);
    refresher.onPosition(position);
  }
}

void main() {
  testWidgets('a pause is captured once the player has stayed paused for a second', (tester) async {
    final rig = _Rig()..at(10);
    rig.refresher.onPlaying(true);
    rig.refresher.onPlaying(false);
    await tester.pump(const Duration(milliseconds: 900));
    expect(rig.taken, isEmpty);
    await tester.pump(const Duration(milliseconds: 200));
    expect(rig.taken, [const Duration(seconds: 10)]);
    await tester.pump(const Duration(seconds: 60));
    expect(rig.taken, hasLength(1), reason: 'a paused player is captured once');
  });

  testWidgets('pause, seek, pause gives one capture, of the position the seek went to', (tester) async {
    final rig = _Rig()..at(10);
    rig.refresher.onPlaying(true);
    rig.refresher.onPlaying(false);
    await tester.pump(const Duration(milliseconds: 500));
    rig.at(70); // a seek while paused
    await tester.pump(const Duration(milliseconds: 700));
    expect(rig.taken, isEmpty, reason: 'the seek starts the wait again');
    rig.refresher.onPlaying(true);
    rig.at(71);
    rig.refresher.onPlaying(false);
    await tester.pump(const Duration(milliseconds: 1100));
    expect(rig.taken, [const Duration(seconds: 71)]);
  });

  testWidgets('a seek while paused after a capture is captured as well', (tester) async {
    final rig = _Rig()..at(10);
    rig.refresher.onPlaying(true);
    rig.refresher.onPlaying(false);
    await tester.pump(const Duration(milliseconds: 1100));
    rig.at(40);
    await tester.pump(const Duration(milliseconds: 1100));
    expect(rig.taken, [const Duration(seconds: 10), const Duration(seconds: 40)]);
  });

  testWidgets('while playing, a capture every 30 s, skipped while the position has barely moved', (tester) async {
    final rig = _Rig()..at(0);
    rig.refresher.onPlaying(true);
    rig.at(29);
    await tester.pump(const Duration(seconds: 30));
    expect(rig.taken, [const Duration(seconds: 29)]);
    // Stalled: buffering keeps the position where it was.
    await tester.pump(const Duration(seconds: 30));
    expect(rig.taken, hasLength(1));
    rig.at(31); // 2 s on: enough
    await tester.pump(const Duration(seconds: 30));
    expect(rig.taken, [const Duration(seconds: 29), const Duration(seconds: 31)]);
    rig.position = const Duration(milliseconds: 31500);
    rig.refresher.onPosition(rig.position);
    await tester.pump(const Duration(seconds: 30));
    expect(rig.taken, hasLength(2), reason: 'half a second is too little to take it again');
    rig.refresher.stop();
  });

  testWidgets('a pause right after a periodic capture at the same position takes nothing more', (tester) async {
    final rig = _Rig()..at(0);
    rig.refresher.onPlaying(true);
    rig.at(30);
    await tester.pump(const Duration(seconds: 30));
    rig.refresher.onPlaying(false);
    await tester.pump(const Duration(seconds: 2));
    expect(rig.taken, [const Duration(seconds: 30)]);
  });

  testWidgets('nothing is captured while capturing is not possible: the option off, or no frame', (tester) async {
    var can = false;
    final rig = _Rig(canCapture: () => can)..at(5);
    rig.refresher.onPlaying(true);
    rig.at(40);
    await tester.pump(const Duration(seconds: 30));
    rig.refresher.onPlaying(false);
    await tester.pump(const Duration(seconds: 2));
    await rig.refresher.captureLast();
    expect(rig.taken, isEmpty);

    can = true;
    final on = _Rig(canCapture: () => can)..at(5);
    on.refresher.onPlaying(true);
    on.refresher.onPlaying(false);
    await tester.pump(const Duration(seconds: 2));
    expect(on.taken, hasLength(1), reason: 'the same rig with the option on does capture');
  });

  testWidgets('leaving the player takes one more capture, whatever the position, and no more after it', (tester) async {
    final rig = _Rig()..at(10);
    rig.refresher.onPlaying(true);
    rig.refresher.onPlaying(false);
    await tester.pump(const Duration(milliseconds: 1100));
    expect(rig.taken, hasLength(1));
    await rig.refresher.captureLast();
    expect(rig.taken, [const Duration(seconds: 10), const Duration(seconds: 10)]);
    rig.refresher.onPlaying(true);
    rig.at(100);
    await tester.pump(const Duration(seconds: 60));
    expect(rig.taken, hasLength(2), reason: 'stopped');
  });

  testWidgets('captures do not overlap: one due while another runs is skipped, and the last one waits for it', (tester) async {
    final rig = _Rig()..at(0);
    rig.gate = Completer<void>();
    rig.refresher.onPlaying(true);
    rig.at(30);
    await tester.pump(const Duration(seconds: 30)); // starts, held at the gate
    rig.at(60);
    await tester.pump(const Duration(seconds: 30)); // due while the first runs
    var lastDone = false;
    unawaited(rig.refresher.captureLast().then((_) => lastDone = true));
    await tester.pump();
    expect(lastDone, isFalse);
    final gate = rig.gate!;
    rig.gate = null;
    gate.complete();
    await tester.pump();
    await tester.pump();
    expect(lastDone, isTrue);
    expect(rig.taken, [const Duration(seconds: 30), const Duration(seconds: 60)],
        reason: 'the capture held at 30 s ends, the one due at 60 s is not taken, the last one follows');
  });
}
