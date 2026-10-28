import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum RecordingMutation { seen, hidden }

class RecordingMutationNotifier
    extends Notifier<Map<String, Set<RecordingMutation>>> {
  @override
  Map<String, Set<RecordingMutation>> build() => const {};

  bool begin(String recordingId, RecordingMutation mutation) {
    if (state[recordingId]?.isNotEmpty ?? false) return false;
    state = {
      ...state,
      recordingId: {mutation},
    };
    return true;
  }

  void finish(String recordingId) {
    final next = {...state}..remove(recordingId);
    state = next;
  }
}

final recordingMutationProvider = NotifierProvider<RecordingMutationNotifier,
    Map<String, Set<RecordingMutation>>>(RecordingMutationNotifier.new);

Future<bool> runRecordingMutation(
  WidgetRef ref,
  String recordingId,
  RecordingMutation mutation,
  Future<void> Function() request,
) async {
  final notifier = ref.read(recordingMutationProvider.notifier);
  if (!notifier.begin(recordingId, mutation)) return false;

  try {
    await request();
    return true;
  } finally {
    notifier.finish(recordingId);
  }
}

class RecordingMutationIndicator extends ConsumerWidget {
  const RecordingMutationIndicator({
    required this.recordingId,
    super.key,
  });

  final String recordingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(recordingMutationProvider.select(
      (mutations) => mutations[recordingId]?.isNotEmpty ?? false,
    ));

    if (!pending) return const SizedBox.shrink();
    return const SizedBox.square(
      dimension: 24,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}
