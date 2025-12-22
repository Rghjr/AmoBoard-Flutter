
import 'package:just_audio/just_audio.dart';

/// Simple audio engine built on `just_audio` to play sounds with adjustable loudness.
/// Supports "earrape" mode by multiplying the requested volume and simulating
/// loudness beyond 1.0 using multiple players in parallel.
class SoundEngine {
  static final SoundEngine _instance = SoundEngine._internal();
  factory SoundEngine() => _instance;
  SoundEngine._internal();

  /// Active audio players managed by the engine (used to stop/dispose later).
  final List<AudioPlayer> _players = [];

  /// Global toggle that amplifies output when enabled.
  bool earrapeEnabled = false;

  /// Play a sound from [path] at a requested [volume].
  /// - `volume` is clamped to [0.0, 2.0]; with earrape enabled it can reach up to 4.0.
  /// - If `finalVolume <= 1.0`, a single player is used.
  /// - If `finalVolume > 1.0`, multiple players are spawned to simulate higher loudness.
  Future<void> play({
    required String path,
    required double volume,
  }) async {
    double finalVolume = volume.clamp(0.0, 2.0);
    
    // Optional global amplification (up to 4.0 total when enabled)
    if (earrapeEnabled) {
      finalVolume = (finalVolume * 2.0).clamp(0.0, 4.0);
    }

    // Simple case: at most 1.0 loudness -> single player path
    if (finalVolume <= 1.0) {
      await _playSingle(path, finalVolume);
      return;
    }

    // Split loudness into full players (volume = 1.0) + remainder (0.0–1.0)
    int fullPlayers = finalVolume.floor();
    double remainderVolume = finalVolume - fullPlayers;

    final players = <AudioPlayer>[];
    
    try {
      // Prepare all full-volume players
      for (int i = 0; i < fullPlayers; i++) {
        final player = AudioPlayer();
        players.add(player);
        _players.add(player);
        
        // Use asset or file source depending on path prefix
        if (path.startsWith('assets/')) {
          await player.setAsset(path);
        } else {
          await player.setFilePath(path);
        }
        await player.setVolume(1.0);
      }

      // Prepare remainder player if needed (partial volume)
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

      // Start each prepared player, staggering by ~1ms to avoid burst glitches
      for (int i = 0; i < players.length; i++) {
        final player = players[i];
        
        // Minimal delay for subsequent players to smooth out start spikes
        if (i > 0) {
          await Future.delayed(Duration(milliseconds: 1));
        }
        
        player.play();
        
        // Auto-dispose player once playback completes
        player.playerStateStream.listen((state) {
          if (state.processingState == ProcessingState.completed) {
            player.dispose();
            _players.remove(player);
          }
        });
      }
    } catch (e) {
      // Ensure we clean up any players created in this call if something fails
      for (final player in players) {
        player.dispose();
        _players.remove(player);
      }
      rethrow;
    }
  }

  /// Internal helper to play a single player at a given [volume] (0.0–1.0).
  /// Chooses asset vs file path depending on the prefix of [path].
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

      // Dispose automatically after finishing playback
      player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          player.dispose();
          _players.remove(player);
        }
      });
    } catch (e) {
      // Clean up if setup/playback fails
      player.dispose();
      _players.remove(player);
      rethrow;
    }
  }

  /// Stop and dispose all active players immediately.
  void stopAll() {
    for (final p in _players) {
      p.stop();
      p.dispose();
    }
    _players.clear();
  }

  /// Enable/disable global amplification mode.
  void setEarrape(bool value) {
    earrapeEnabled = value;
  }

  /// Dispose the engine by stopping all players.
  void dispose() {
    stopAll();
  }
}
