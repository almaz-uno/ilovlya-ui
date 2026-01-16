# Agent Instructions

## Project Language

The primary language for this project is **English**.

All code, documentation, comments, commit messages, and communication should be in English.

## Project Description

Ilovlya UI is a Flutter mobile application for viewing and managing media content. The application allows users to play audio and video recordings, manage playlists, and control playback settings.

## Technical Stack

- **Framework**: Flutter (Dart)
- **State Management**: Riverpod
- **Media Playback**: media_kit
- **UI**: Material Design 3
- **Platform Support**: Android, iOS, Windows, macOS, Linux

## Project Architecture

### Folder Structure

```
lib/
├── src/
│   ├── api/           # API integration and Riverpod providers
│   ├── media/         # Media players and playback components
│   ├── model/         # Data models
│   ├── settings/      # Application settings
│   └── widgets/       # Reusable widgets
```

### Key Components

- `RecordingViewMediaKitHandler` - main media player
- `PlayerControls` - playback control elements
- `MKPlayerHandler` - media_kit player handler

## Coding Rules

### Code Style

- Use `const` constructors where possible
- Follow Dart code style guide
- Use meaningful names for variables and functions
- Add comments for complex logic
- Documentation is written in AsciiDoc, in Russian texts em dash should be used according to Russian typography (—). List, table, and other object titles should start with a period: `.Description`

### State Management

- Use Riverpod for state management
- Create separate providers for API calls
- Use `ConsumerWidget` or `ConsumerStatefulWidget`

### Media Playback

- Always handle errors when working with media_kit
- Consider platform-specific features (Platform.isAndroid, etc.)
- Use dispose() to release player resources

### Localization

- Support Russian and English languages
- Use l10n.yaml for localization configuration
- All user-facing strings must be localized

## Specific Requirements

### Media Player

- Support for Bluetooth headsets and system media buttons
- Correct operation at different playback speeds
- Saving playback position
- Support for seeking (15s, 30s, 1min, 5min)

### UI/UX

- Follow Material Design 3 guidelines
- Support dark and light themes
- Responsive design for different screen sizes
- Accessibility support

### Performance

- Lazy loading for large lists
- Image and data caching
- Optimization for low-end devices

## Code Examples

### Creating a Riverpod Provider

```dart
final exampleProvider = StateNotifierProvider<ExampleNotifier, ExampleState>((ref) {
  return ExampleNotifier(ref);
});
```

### Using media_kit

```dart
final player = Player();
await player.open(Media(url));
player.stream.position.listen((position) {
  // Handle position changes
});
```

### Platform-specific Code

```dart
if (Platform.isAndroid || Platform.isIOS) {
  // Mobile specific code
} else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
  // Desktop specific code
}
```

## Common Tasks

### Adding a New Screen

1. Create a widget in the appropriate folder
2. Add a route to the app router
3. Create necessary providers
4. Add localization

### Working with API

1. Define data models
2. Create a Riverpod provider for API call
3. Handle errors and loading states
4. Use in UI through ConsumerWidget

### Performance Optimization

- Use `const` constructors
- Avoid recreating widgets in build methods
- Use `select` in Riverpod for granular subscriptions
- Dispose resources in appropriate methods

## Testing

- Write unit tests for business logic
- Widget tests for UI components
- Integration tests for critical user scenarios
- Test on real devices across different platforms

## Guidelines for Copilot

When generating code:

- Always consider cross-platform compatibility
- Use existing project patterns
- Add error handling
- Follow Riverpod architecture
- Consider performance on mobile devices
- Don't forget to localize strings
- Use `gh` for working with GitHub
- Issues and comments are maintained in English
- When working with `gh` command, use heredoc escaping for multiline literals, e.g., descriptions
- Auto-commits are not allowed, only upon direct user request
- Automatic issue commenting after implementation is not allowed, only upon direct user request

## Logging

See [doc/logging.asciidoc](doc/logging.asciidoc) for detailed logging guidelines.

