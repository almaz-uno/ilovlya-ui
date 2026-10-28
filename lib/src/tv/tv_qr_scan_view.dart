import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ilovlya/src/localization/app_localizations.dart';
import 'package:ilovlya/src/keyboard_shortcuts.dart';
import 'package:ilovlya/src/media/intents.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Reads the pairing code from the QR image on the television. The image
/// encodes the code verbatim, so scanning fills the same field typing does.
class TvQrScanView extends StatefulWidget {
  const TvQrScanView({super.key});

  static Future<String?> show(BuildContext context) {
    return Navigator.of(context).push<String>(MaterialPageRoute(builder: (context) => const TvQrScanView()));
  }

  @override
  State<TvQrScanView> createState() => _TvQrScanViewState();
}

class _TvQrScanViewState extends State<TvQrScanView> {
  final _controller = MobileScannerController(formats: [BarcodeFormat.qrCode]);
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) {
      return;
    }

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value != null && value.trim().isNotEmpty) {
        _handled = true;
        Navigator.of(context).pop(value.trim());
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ScreenShortcuts(
      shortcuts: isDesktopKeyboardPlatform
          ? const {
              SingleActivator(LogicalKeyboardKey.escape): BackIntent(),
              SingleActivator(LogicalKeyboardKey.backspace): BackIntent(),
            }
          : const {},
      actions: {
        BackIntent: CallbackAction<BackIntent>(onInvoke: (_) {
          Navigator.of(context).maybePop();
          return null;
        }),
      },
      help: [ShortcutHelpEntry('Esc / Backspace', AppLocalizations.of(context)!.cancel)],
      child: Scaffold(
      appBar: AppBar(title: Text(l10n.tvScanTitle)),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.tvScanHint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
