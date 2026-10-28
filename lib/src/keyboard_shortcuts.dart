import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:universal_platform/universal_platform.dart';

import 'localization/app_localizations.dart';

class ShortcutHelpEntry {
  const ShortcutHelpEntry(this.keys, this.description);

  final String keys;
  final String description;
}

/// Adds screen-local shortcuts and a help dialog without intercepting text input.
class ScreenShortcuts extends StatelessWidget {
  const ScreenShortcuts({
    required this.shortcuts,
    required this.actions,
    required this.help,
    required this.child,
    this.allowedWhenTextInputFocused = const {},
    this.ignoreWhenActivateFocused = const {},
    super.key,
  });

  final Map<ShortcutActivator, Intent> shortcuts;
  final Map<Type, Action<Intent>> actions;
  final List<ShortcutHelpEntry> help;
  final Widget child;
  final Set<Type> allowedWhenTextInputFocused;
  final Set<Type> ignoreWhenActivateFocused;

  @override
  Widget build(BuildContext context) {
    final guardedActions = <Type, Action<Intent>>{
      for (final entry in actions.entries)
        entry.key: _TextInputGuardAction<Intent>(
          entry.value,
          allowWhenFocused: allowedWhenTextInputFocused.contains(entry.key),
          ignoreWhenActivateFocused: ignoreWhenActivateFocused.contains(entry.key),
        ),
    };
    return Shortcuts(
      shortcuts: {
        ...shortcuts,
        if (isDesktopKeyboardPlatform) const CharacterActivator('?'): const ShowShortcutHelpIntent(),
      },
      child: Actions(
        actions: {
          ...guardedActions,
          ShowShortcutHelpIntent: _TextInputGuardAction<ShowShortcutHelpIntent>(
            CallbackAction<ShowShortcutHelpIntent>(
            onInvoke: (_) {
              if (isTextInputFocused()) return null;
              showDialog<void>(
                context: context,
                builder: (context) => DialogShortcuts(
                  child: AlertDialog(
                    title: Text(AppLocalizations.of(context)!.keyboardShortcuts),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final entry in help)
                            ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: SizedBox(width: 88, child: Text(entry.keys, style: const TextStyle(fontWeight: FontWeight.bold))),
                              title: Text(entry.description),
                            ),
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const SizedBox(width: 88, child: Text("?", style: TextStyle(fontWeight: FontWeight.bold))),
                            title: Text(AppLocalizations.of(context)!.showShortcutHelp),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(autofocus: true, onPressed: () => Navigator.of(context).pop(), child: Text(AppLocalizations.of(context)!.cancel)),
                    ],
                  ),
                ),
              );
              return null;
            },
          ),
          allowWhenFocused: false,
          ignoreWhenActivateFocused: false,
        ),
        },
        child: isDesktopKeyboardPlatform ? Focus(autofocus: true, child: child) : child,
      ),
    );
  }
}

class ShowShortcutHelpIntent extends Intent {
  const ShowShortcutHelpIntent();
}

class _TextInputGuardAction<T extends Intent> extends Action<T> {
  _TextInputGuardAction(this.delegate, {required this.allowWhenFocused, required this.ignoreWhenActivateFocused});

  final Action<T> delegate;
  final bool allowWhenFocused;
  final bool ignoreWhenActivateFocused;

  bool get _activateTargetFocused {
    final context = FocusManager.instance.primaryFocus?.context;
    return context != null &&
        (context.widget is ButtonStyleButton ||
            context.widget is InkWell ||
            context.widget is ListTile ||
            context.findAncestorWidgetOfExactType<ButtonStyleButton>() != null ||
            context.findAncestorWidgetOfExactType<InkWell>() != null ||
            context.findAncestorWidgetOfExactType<ListTile>() != null ||
            context.findAncestorWidgetOfExactType<FocusableActionDetector>() != null);
  }

  @override
  bool isEnabled(T intent) => delegate.isEnabled(intent) && !(ignoreWhenActivateFocused && _activateTargetFocused) && (allowWhenFocused || !isTextInputFocused());

  @override
  bool consumesKey(T intent) => !isEnabled(intent) ? false : delegate.consumesKey(intent);

  @override
  Object? invoke(T intent) {
    if (!isEnabled(intent)) return null;
    return delegate.invoke(intent);
  }
}

class DialogShortcuts extends StatelessWidget {
  const DialogShortcuts({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!isDesktopKeyboardPlatform) return child;
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter, includeRepeats: false): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.numpadEnter, includeRepeats: false): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.escape, includeRepeats: false): CancelDialogIntent(),
        CharacterActivator('?'): ShowDialogShortcutHelpIntent(),
      },
      child: Actions(
        actions: {
          CancelDialogIntent: CallbackAction<CancelDialogIntent>(onInvoke: (_) {
            Navigator.of(context).maybePop();
            return null;
          }),
          ShowDialogShortcutHelpIntent: CallbackAction<ShowDialogShortcutHelpIntent>(onInvoke: (_) {
            showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(AppLocalizations.of(context)!.keyboardShortcuts),
                content: Text('${AppLocalizations.of(context)!.confirmWithEnter}\n${AppLocalizations.of(context)!.cancelWithEscape}\n${AppLocalizations.of(context)!.showDialogShortcutHelp}'),
                actions: [
                  TextButton(autofocus: true, onPressed: () => Navigator.of(context).pop(), child: Text(AppLocalizations.of(context)!.cancel)),
                ],
              ),
            );
            return null;
          }),
        },
        child: FocusTraversalGroup(child: child),
      ),
    );
  }
}

class CancelDialogIntent extends Intent {
  const CancelDialogIntent();
}

class ShowDialogShortcutHelpIntent extends Intent {
  const ShowDialogShortcutHelpIntent();
}

bool isTextInputFocused() {
  final context = FocusManager.instance.primaryFocus?.context;
  return context?.widget is EditableText || context?.findAncestorWidgetOfExactType<EditableText>() != null || context?.findAncestorWidgetOfExactType<TextField>() != null;
}

bool get isDesktopKeyboardPlatform => !UniversalPlatform.isAndroid && !UniversalPlatform.isIOS;

bool get isMacKeyboardPlatform => UniversalPlatform.isMacOS || (UniversalPlatform.isWeb && defaultTargetPlatform == TargetPlatform.macOS);
