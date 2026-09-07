import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ilovlya/src/localization/app_localizations.dart';
import 'package:universal_platform/universal_platform.dart';

import 'tv_api.dart';
import 'tv_models.dart';
import 'tv_qr_scan_view.dart';

/// Asks for the code shown on a television. The code is what a human reads from
/// across a room, so the field is large, case-insensitive and forgiving about
/// the dashes and spaces people add while typing.
class TvPairingView extends ConsumerStatefulWidget {
  const TvPairingView({super.key});

  static Future<TvSession?> show(BuildContext context) {
    return showDialog<TvSession>(context: context, builder: (context) => const TvPairingView());
  }

  @override
  ConsumerState<TvPairingView> createState() => _TvPairingViewState();
}

class _TvPairingViewState extends ConsumerState<TvPairingView> {
  final _controller = TextEditingController();
  bool _pairing = false;
  String? _failure;

  static const _codeLength = 8;

  /// A camera exists on phones and tablets only; elsewhere the code is typed.
  bool get _canScan => UniversalPlatform.isAndroid || UniversalPlatform.isIOS;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pair(String code) async {
    if (code.trim().isEmpty || _pairing) {
      return;
    }

    setState(() {
      _pairing = true;
      _failure = null;
    });

    try {
      final session = await ref.read(pairTvProvider(code).future);
      ref.invalidate(tvSessionsProvider);
      if (mounted) {
        Navigator.of(context).pop(session);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _pairing = false;
          _failure = AppLocalizations.of(context)!.tvPairingFailed;
        });
      }
    }
  }

  Future<void> _scan() async {
    final code = await TvQrScanView.show(context);
    if (code != null) {
      _controller.text = code;
      await _pair(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.tvPairTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.tvPairHint),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            enabled: !_pairing,
            textCapitalization: TextCapitalization.none,
            autocorrect: false,
            maxLength: _codeLength + 2, // room for a dash or a space
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 \-]'))],
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(letterSpacing: 4),
            decoration: InputDecoration(labelText: l10n.tvPairCodeLabel, errorText: _failure),
            onSubmitted: _pair,
          ),
          if (_pairing) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator()),
        ],
      ),
      actions: [
        if (_canScan) TextButton.icon(onPressed: _pairing ? null : _scan, icon: const Icon(Icons.qr_code_scanner), label: Text(l10n.tvPairScan)),
        TextButton(onPressed: _pairing ? null : () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        FilledButton(onPressed: _pairing ? null : () => _pair(_controller.text), child: Text(l10n.tvPairConnect)),
      ],
    );
  }
}
