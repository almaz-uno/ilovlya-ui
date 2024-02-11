import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api.dart';
import '../api/api_riverpod.dart';
import '../api/media_list_riverpod.dart';
import '../model/url_info.dart';
import 'format.dart';

class MediaAddView extends ConsumerStatefulWidget {
  const MediaAddView({
    super.key,
    this.forcePaste = false,
  });

  final bool forcePaste;

  static routeName(bool forcePaste) {
    return forcePaste ? "/$pathRecordings?add&paste" : "/$pathRecordings?add";
  }

  @override
  ConsumerState<MediaAddView> createState() => _MediaAddViewState();
}

class _MediaAddViewState extends ConsumerState<MediaAddView> {
  final TextEditingController _urlController = TextEditingController();

  Future<URLInfo>? _futurePropositions;
  bool _isLoading = false;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    if (widget.forcePaste) {
      fromClipboard();
    }
  }

  void fromClipboard() async {
    try {
      var data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text != null) {
        _urlController.text = data!.text!;
      }

      setState(() {
        _futurePropositions = _getURLInfo(_urlController.text);
      });
    } on Exception catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<URLInfo> _getURLInfo(String url) async {
    try {
      setState(() {
        _isLoading = true;
      });
      return await ref.read(getUrlInfoProvider(url).future);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add new media'),
        actions: [
          IconButton(
            icon: const Icon(Icons.paste),
            tooltip: 'Paste from clipboard',
            onPressed: fromClipboard,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'Enter media URL',
                prefixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    IconButton(
                      onPressed: fromClipboard,
                      icon: const Icon(Icons.paste),
                      tooltip: 'Paste from clipboard',
                    ),
                    IconButton(
                      icon: const Icon(Icons.youtube_searched_for),
                      tooltip: 'Lookup media info',
                      onPressed: () {
                        setState(() {
                          _futurePropositions = _getURLInfo(_urlController.text);
                        });
                      },
                    ),
                  ],
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _urlController.clear,
                ),
              ),
            ),
            (_futurePropositions == null) ? const Text('To view info press lookup button above') : buildPropositionList(),
            Visibility(
                visible: _isLoading || _isAdding,
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                )),
          ],
        ),
      ),
    );
  }

  void _addMedia(BuildContext context, String url, bool doBack) async {
    if (!widget.forcePaste) {
      setState(() {
        _isAdding = true;
      });
    }
    // _futureMediaAdd = ; // the full information about media should be acquired anew
    ref.read(addRecordingProvider(url).future).then((value) {
      ref.invalidate(mediaListNotifierProvider);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${value.title} successfully added'),
      ));
    }).catchError((err) {
      showDialog(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext context) => Dialog(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(err.toString()),
                ),
              ));
    }).whenComplete(() => setState(() {
          _isAdding = false;
          if (doBack) {
            Navigator.pop(context);
          }
        }));
  }

  FutureBuilder<URLInfo> buildPropositionList() {
    return FutureBuilder<URLInfo>(
      future: _futurePropositions,
      builder: (BuildContext context, AsyncSnapshot<URLInfo> snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data!.infos != null && widget.forcePaste && snapshot.data!.infos!.length == 1) {
            var u = snapshot.data!.infos![0].webpageUrl;
            _addMedia(context, u, true);
            return Column(
              children: [
                Text("Adding url $u..."),
                const CircularProgressIndicator(),
              ],
            );
          }

          return snapshot.data!.infos == null
              ? const Text("There is no recordings in the url")
              : ListView.builder(
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  itemCount: snapshot.data!.infos!.length,
                  itemBuilder: (BuildContext context, int index) {
                    var item = snapshot.data!.infos![index];
                    var dur = Duration(seconds: item.duration);
                    return ListTile(
                      leading: SizedBox(
                        width: 100, // alignment
                        child: Image.network(
                          item.thumbnailDataUrl!,
                          isAntiAlias: true,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                      title: Text("${item.title} ∙ ${formatDuration(dur)}"),
                      subtitle: Text("${item.uploader} ∙ ${item.webpageUrl}"),
                      onTap: () {
                        _addMedia(context, item.webpageUrl, false);
                      },
                      onLongPress: () async {
                        _addMedia(context, item.webpageUrl, true);
                      },
                    );
                  },
                );
        } else if (snapshot.hasError) {
          return ErrorWidget(snapshot.error!);
        }

        return const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text('Media info acquiring in progress...'),
        );
      },
    );
  }
}
