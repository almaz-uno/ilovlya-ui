import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ilovlya/src/api/recording_mutation_riverpod.dart';

void main() {
  testWidgets('recording mutation shows pending indicator and rejects repeats', (tester) async {
    final requestCompleter = Completer<void>();
    final results = <Future<bool>>[];
    var requestCount = 0;

    await tester.pumpWidget(ProviderScope(
      retry: (_, _) => null,
      child: MaterialApp(
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) => Column(
              children: [
                RecordingMutationIndicator(recordingId: 'recording-1'),
                ElevatedButton(
                  onPressed: () {
                    results.add(runRecordingMutation(
                      ref,
                      'recording-1',
                      RecordingMutation.seen,
                      () {
                        requestCount++;
                        return requestCompleter.future;
                      },
                    ));
                  },
                  child: const Text('Mark seen'),
                ),
              ],
            ),
          ),
        ),
      ),
    ));

    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.tap(find.text('Mark seen'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(requestCount, 1);

    await tester.tap(find.text('Mark seen'));
    await tester.pump();
    expect(requestCount, 1);
    expect(await results[1], isFalse);

    requestCompleter.complete();
    expect(await results[0], isTrue);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
