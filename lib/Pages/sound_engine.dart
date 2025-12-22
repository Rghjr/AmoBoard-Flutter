import 'package:just_audio/just_audio.dart';

class SoundEngine {
  static final SoundEngine _instance = SoundEngine._internal();
  factory SoundEngine() => _instance;
  SoundEngine._internal();

  final List<AudioPlayer> _players = [];

  bool earrapeEnabled = false;

  Future<void> play({
    required String path,
    required double volume,
  }) async {
    double finalVolume = volume.clamp(0.0, 2.0);
    
    if (earrapeEnabled) {
      finalVolume = (finalVolume * 2.0).clamp(0.0, 4.0);
    }

    if (finalVolume <= 1.0) {
      await _playSingle(path, finalVolume);
      return;
    }

    int fullPlayers = finalVolume.floor();
    double remainderVolume = finalVolume - fullPlayers;

    final players = <AudioPlayer>[];
    
    try {
      // Przygotuj wszystkie playery
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

      // Odpal z 1ms opóźnieniem między każdym
      for (int i = 0; i < players.length; i++) {
        final player = players[i];
        
        // 1ms opóźnienie dla każdego kolejnego playera (oprócz pierwszego)
        if (i > 0) {
          await Future.delayed(Duration(milliseconds: 1));
        }
        
        player.play();
        
        player.playerStateStream.listen((state) {
          if (state.processingState == ProcessingState.completed) {
            player.dispose();
            _players.remove(player);
          }
        });
      }
    } catch (e) {
      for (final player in players) {
        player.dispose();
        _players.remove(player);
      }
      rethrow;
    }
  }

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

  void stopAll() {
    for (final p in _players) {
      p.stop();
      p.dispose();
    }
    _players.clear();
  }

  void setEarrape(bool value) {
    earrapeEnabled = value;
  }

  void dispose() {
    stopAll();
  }
}