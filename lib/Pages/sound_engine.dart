import 'package:just_audio/just_audio.dart';

/// =======================================================
/// SoundEngine singleton
/// =======================================================
/// Manages sound playback across the app.
/// Supports multiple simultaneous AudioPlayers
/// and an "earrape" mode to boost volume beyond normal.
class SoundEngine {
  // ================================
  // Singleton pattern
  // ================================
  static final SoundEngine _instance = SoundEngine._internal();
  factory SoundEngine() => _instance;
  SoundEngine._internal();

  /// List of all active AudioPlayers
  final List<AudioPlayer> _players = [];

  /// Flag to enable "earrape" mode (maximum volume)
  bool earrapeEnabled = false;

  /// =======================================================
  /// Plays a sound file
  ///
  /// [path] – file path (assets or local file)
  /// [volume] – 0.0 to 2.0, can reach up to 4.0 if earrape enabled
  /// =======================================================
  Future<void> play({
    required String path,
    required double volume,
  }) async {
    double finalVolume = volume.clamp(0.0, 2.0);

    // Apply earrape mode: double the volume
    if (earrapeEnabled) {
      finalVolume = (finalVolume * 2.0).clamp(0.0, 4.0);
    }

    // Single player if volume <= 1.0
    if (finalVolume <= 1.0) {
      await _playSingle(path, finalVolume);
      return;
    }

    // For volume > 1.0, use multiple players to simulate louder playback
    int fullPlayers = finalVolume.floor();
    double remainderVolume = finalVolume - fullPlayers;

    final players = <AudioPlayer>[];

    try {
      // Create full-volume players
      for (int i = 0; i < fullPlayers; i++) {
        final player = AudioPlayer();
        players.add(player);
        _players.add(player);

        if (path.startsWith('assets/')) {
          await player.setAsset(path);
        } else {
          await player.setFilePath(path);
        }

        await player.setVolume(1.0);
      }

      // Add a player for the remaining fractional volume
      if (remainderVolume > 0.01) {
        final player = AudioPlayer();
        players.add(player);
        _players.add(player);

        if (path.startsWith('assets/')) {
          await player.setAsset(path);
        } else {
          await player.setFilePath(path);
        }

        await player.setVolume(remainderVolume);
      }

      // Play all players with a minimal 1ms offset for sync
      for (int i = 0; i < players.length; i++) {
        final player = players[i];

        if (i > 0) {
          await Future.delayed(const Duration(milliseconds: 1));
        }

        player.play();

        // Auto-dispose when playback completes
        player.playerStateStream.listen((state) {
          if (state.processingState == ProcessingState.completed) {
            player.dispose();
            _players.remove(player);
          }
        });
      }
    } catch (e) {
      // On error, dispose all players
      for (final player in players) {
        player.dispose();
        _players.remove(player);
      }
      rethrow;
    }
  }

  /// =======================================================
  /// Single player playback for low volume (<1.0)
  /// =======================================================
  Future<void> _playSingle(String path, double volume) async {
    final player = AudioPlayer();
    _players.add(player);

    try {
      if (path.startsWith('assets/')) {
        await player.setAsset(path);
      } else {
        await player.setFilePath(path);
      }

      await player.setVolume(volume.clamp(0.0, 1.0));
      player.play();

      // Auto-dispose after completion
      player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          player.dispose();
          _players.remove(player);
        }
      });
    } catch (e) {
      player.dispose();
      _players.remove(player);
      rethrow;
    }
  }

  /// =======================================================
  /// Stops all active players and disposes them
  /// =======================================================
  void stopAll() {
    for (final p in _players) {
      p.stop();
      p.dispose();
    }
    _players.clear();
  }

  /// =======================================================
  /// Enable or disable "earrape" mode (max volume)
  /// =======================================================
  void setEarrape(bool value) {
    earrapeEnabled = value;
  }

  /// =======================================================
  /// Dispose engine and all active players
  /// =======================================================
  void dispose() {
    stopAll();
  }
}
