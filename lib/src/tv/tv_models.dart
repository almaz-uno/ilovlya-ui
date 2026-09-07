import 'package:json_annotation/json_annotation.dart';

part 'tv_models.g.dart';

/// Phases a cast session goes through, as defined in specs/doc/tv-protocol.adoc.
class TvPhase {
  static const created = "created";
  static const paired = "paired";
  static const loading = "loading";
  static const playing = "playing";
  static const paused = "paused";
  static const ended = "ended";
}

/// Commands a sender may issue.
class TvCommandType {
  static const play = "play";
  static const pause = "pause";
  static const resume = "resume";
  static const seek = "seek";
  static const stop = "stop";
}

/// Error codes a receiver may report.
class TvErrorCode {
  static const unsupportedMedia = "unsupported_media";
  static const network = "network";
  static const aborted = "aborted";
  static const unknown = "unknown";
}

@JsonSerializable(fieldRename: FieldRename.snake)
class TvSession {
  String id;
  String phase;
  bool connected;
  DateTime? pairedAt;
  DateTime? expiresAt;
  DateTime? lastSeenAt;
  String recordingId;
  String downloadId;
  int position;
  int duration;
  TvError? error;

  TvSession({
    this.id = "",
    this.phase = TvPhase.created,
    this.connected = false,
    this.pairedAt,
    this.expiresAt,
    this.lastSeenAt,
    this.recordingId = "",
    this.downloadId = "",
    this.position = 0,
    this.duration = 0,
    this.error,
  });

  /// A session that can be commanded right now: paired, not ended, and with a
  /// receiver on the other end.
  bool get isLive => connected && phase != TvPhase.created && phase != TvPhase.ended;

  bool get isPlaying => phase == TvPhase.playing;

  bool get isIdle => phase == TvPhase.paired;

  factory TvSession.fromJson(Map<String, dynamic> json) => _$TvSessionFromJson(json);

  Map<String, dynamic> toJson() => _$TvSessionToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class TvError {
  String code;
  String message;

  TvError({this.code = "", this.message = ""});

  factory TvError.fromJson(Map<String, dynamic> json) => _$TvErrorFromJson(json);

  Map<String, dynamic> toJson() => _$TvErrorToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class TvCommand {
  String type;
  String? downloadId;
  int? position;

  TvCommand({required this.type, this.downloadId, this.position});

  TvCommand.play(this.downloadId, {this.position}) : type = TvCommandType.play;

  TvCommand.seek(this.position)
    : type = TvCommandType.seek,
      downloadId = null;

  factory TvCommand.fromJson(Map<String, dynamic> json) => _$TvCommandFromJson(json);

  Map<String, dynamic> toJson() => _$TvCommandToJson(this);
}
