import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_riverpod.dart';
import '../localization/app_localizations.dart';
import '../model/download.dart';

class DownloadDetailsView extends ConsumerStatefulWidget {
  const DownloadDetailsView({
    super.key,
    required this.downloadId,
  });

  final String downloadId;

  @override
  ConsumerState<DownloadDetailsView> createState() => _DownloadDetailsViewState();
}

class _DownloadDetailsViewState extends ConsumerState<DownloadDetailsView> {
  static const _pullPeriod = Duration(seconds: 1);

  StreamSubscription? _pullSubs;

  @override
  void initState() {
    super.initState();

    _pullSubs = Stream.periodic(_pullPeriod).listen((event) {
      ref.invalidate(getDownloadProvider(widget.downloadId));
    });
  }

  @override
  void deactivate() {
    _pullSubs?.cancel();
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    final download = ref.watch(getDownloadProvider(widget.downloadId));
    return Scaffold(
      appBar: AppBar(title: download.hasValue ? Text("${download.requireValue.title} ${AppLocalizations.of(context)!.preparingEllipsis}") : Text(AppLocalizations.of(context)!.acquiringInfo)),
      body: _buildOutput(download),
    );
  }

  Widget _buildOutput(AsyncValue<Download> download) {
    if (download.hasError) {
      return ErrorWidget(download.error!);
    }

    if (!download.hasValue) {
      return Text(AppLocalizations.of(context)!.waitingDataFromServer);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text(
          softWrap: false,
          download.requireValue.progress,
        ),
      ),
    );
  }
}
