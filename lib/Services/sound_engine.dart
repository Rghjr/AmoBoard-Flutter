import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';

/// Audio engine for playing sounds with volume amplification support.
/// 
/// Built on just_audio package with the following features:
/// - Singleton pattern ensures single engine instance
/// - Prevents memory leaks through proper player lifecycle management
/// - Supports "earrape" mode by multiplying volume beyond normal limits
/// - Simulates loudness >1.0 using multiple concurrent players
/// - Comprehensive error handling for all audio operations
class SoundEngine {
  static final SoundEngine _instance = SoundEngine._internal();
  factory SoundEngine() => _instance;
  SoundEngine._internal();

  /// Active audio players managed by the engine (used to stop/dispose later).
  final List<AudioPlayer> _players = [];

  /// Global toggle that amplifies output when enabled.
  bool earrapeEnabled = false;

  /// Maximum number of concurrent players to prevent memory issues
  static const int _maxConcurrentPlayers = 50;

  /// Plays a sound from [path] at a requested [volume].
  /// 
  /// Volume handling:
  /// - Clamped to [0.0, 2.0] normally; with earrape enabled can reach 4.0
  /// - If finalVolume <= 1.0, uses a single player
  /// - If finalVolume > 1.0, spawns multiple players to simulate higher loudness
  /// 
  /// Optional [startTime] and [endTime] allow playing only a fragment of the audio.
  /// 
  /// Returns: true if playback started successfully, false if it failed
  Future<bool> play({
    required String path,
    required double volume,
    Duration? startTime,
    Duration? endTime,
  }) async {
    try {
      // Clean up completed players before starting new ones
      _cleanupCompletedPlayers();

      // Prevent memory issues by limiting concurrent players
      if (_players.length >= _maxConcurrentPlayers) {
        debugPrint('⚠️ Too many concurrent players (${_players.length}), stopping oldest ones');
        _stopOldestPlayers(10);
      }

      double finalVolume = volume.clamp(0.0, 2.0);
      
      // Optional global amplification (up to 4.0 total when enabled)
      if (earrapeEnabled) {
        finalVolume = (finalVolume * 2.0).clamp(0.0, 4.0);
      }

      // Simple case: at most 1.0 loudness -> single player path
      if (finalVolume <= 1.0) {
        return await _playSingle(path, finalVolume, startTime: startTime, endTime: endTime);
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
          
          // Set clip position if time range is specified
          if (startTime != null && endTime != null) {
            await player.setClip(start: startTime, end: endTime);
          }
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
          
          // Set clip position if time range is specified
          if (startTime != null && endTime != null) {
            await player.setClip(start: startTime, end: endTime);
          }
        }

        // Start each prepared player, staggering by ~1ms to avoid burst glitches
        for (int i = 0; i < players.length; i++) {
          final player = players[i];
          
          // Minimal delay for subsequent players to smooth out start spikes
          if (i > 0) {
            await Future.delayed(const Duration(milliseconds: 1));
          }
          
          player.play();
          
          // Auto-dispose player once playback completes
          player.playerStateStream.listen(
            (state) {
              if (state.processingState == ProcessingState.completed) {
                _safeDisposePlayer(player);
              }
            },
            onError: (error) {
              debugPrint('⚠️ Player stream error: $error');
              _safeDisposePlayer(player);
            },
            cancelOnError: true,
          );
        }
        
        return true;
      } catch (e) {
        debugPrint('❌ Error during multi-player setup: $e');
        // Ensure we clean up any players created in this call if something fails
        for (final player in players) {
          _safeDisposePlayer(player);
        }
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error in play(): $e');
      return false;
    }
  }

  /// Plays sound using a single audio player.
  /// 
  /// Used when requested volume is <= 1.0 and can be achieved
  /// with a single player. Chooses asset vs file path based on
  /// the path prefix. Optional [startTime] and [endTime] allow
  /// playing only a fragment.
  /// 
  /// Returns: true if playback started successfully, false if it failed
  Future<bool> _playSingle(String path, double volume, {Duration? startTime, Duration? endTime}) async {
    final player = AudioPlayer();
    _players.add(player);

    try {
      if (path.startsWith('assets/')) {
        await player.setAsset(path);
      } else {
        await player.setFilePath(path);
      }

      await player.setVolume(volume.clamp(0.0, 1.0));
      
      // Set clip position if time range is specified
      if (startTime != null && endTime != null) {
        await player.setClip(start: startTime, end: endTime);
      }
      
      player.play();

      // Dispose automatically after finishing playback
      player.playerStateStream.listen(
        (state) {
          if (state.processingState == ProcessingState.completed) {
            _safeDisposePlayer(player);
          }
        },
        onError: (error) {
          debugPrint('⚠️ Player stream error: $error');
          _safeDisposePlayer(player);
        },
        cancelOnError: true,
      );
      
      return true;
    } catch (e) {
      debugPrint('❌ Error in _playSingle(): $e');
      // Clean up if setup/playback fails
      _safeDisposePlayer(player);
      return false;
    }
  }

  /// Safely disposes a player and removes it from the active players list.
  /// 
  /// Ensures proper cleanup even if disposal fails, preventing memory leaks.
  void _safeDisposePlayer(AudioPlayer player) {
    try {
      _players.remove(player);
      player.dispose();
    } catch (e) {
      debugPrint('⚠️ Error disposing player: $e');
    }
  }

  /// Removes completed players from the active players list.
  /// 
  /// Called before starting new playback to ensure accurate player count
  /// and prevent memory leaks from accumulated dead players.
  void _cleanupCompletedPlayers() {
    try {
      _players.removeWhere((player) {
        final state = player.playerState;
        if (state.processingState == ProcessingState.completed) {
          player.dispose();
          return true;
        }
        return false;
      });
    } catch (e) {
      debugPrint('⚠️ Error cleaning up players: $e');
    }
  }

  /// Stops and disposes the oldest N players in the list.
  /// 
  /// Called when approaching the concurrent player limit to make
  /// room for new players. Oldest players are chosen as they're
  /// most likely to be finished or unwanted.
  void _stopOldestPlayers(int count) {
    try {
      final toRemove = _players.take(count).toList();
      for (final player in toRemove) {
        _safeDisposePlayer(player);
      }
    } catch (e) {
      debugPrint('⚠️ Error stopping oldest players: $e');
    }
  }

  /// Stops and disposes all currently playing sounds immediately.
  void stopAll() {
    try {
      final playersCopy = List<AudioPlayer>.from(_players);
      for (final p in playersCopy) {
        try {
          p.stop();
          p.dispose();
        } catch (e) {
          debugPrint('⚠️ Error stopping player: $e');
        }
      }
      _players.clear();
    } catch (e) {
      debugPrint('❌ Error in stopAll(): $e');
    }
  }

  /// Enables or disables global volume amplification mode.
  void setEarrape(bool value) {
    earrapeEnabled = value;
  }

  /// Gets the current number of active players (useful for debugging).
  int get activePlayerCount => _players.length;

  /// Disposes the engine by stopping all players.
  void dispose() {
    stopAll();
  }
}