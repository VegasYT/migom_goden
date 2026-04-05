import 'package:audioplayers/audioplayers.dart';

/// Plays the incoming-order notification sound on loop.
/// Call [play] when an order arrives, [stop] on any outcome.
class OrderSoundService {
  static final _player = AudioPlayer();

  static Future<void> play() async {
    await _player.stop();
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.play(AssetSource('sounds/new_order.mp3'));
  }

  static Future<void> stop() async {
    await _player.stop();
    await _player.setReleaseMode(ReleaseMode.release);
  }
}
