import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:watchiot/features/monitoring/domain/repositories/alarm_controller.dart';

class AudioAlarmController implements AlarmController {
  final AudioPlayer _player = AudioPlayer();
  Timer? _hapticTimer;
  bool _active = false;

  @override
  Future<void> start() async {
    if (_active) return;
    _active = true;
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(BytesSource(_buildSirenWave(), mimeType: 'audio/wav'));
      _hapticTimer = Timer.periodic(const Duration(milliseconds: 950), (_) {
        HapticFeedback.vibrate();
      });
      HapticFeedback.vibrate();
    } catch (_) {
      _active = false;
      _hapticTimer?.cancel();
      await _player.stop();
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    _active = false;
    _hapticTimer?.cancel();
    _hapticTimer = null;
    await _player.stop();
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _player.dispose();
  }

  Uint8List _buildSirenWave() {
    const sampleRate = 22050;
    const seconds = 2;
    const sampleCount = sampleRate * seconds;
    final bytes = Uint8List(44 + sampleCount * 2);
    final data = ByteData.sublistView(bytes);

    void writeAscii(int offset, String value) {
      for (var i = 0; i < value.length; i++) {
        bytes[offset + i] = value.codeUnitAt(i);
      }
    }

    writeAscii(0, 'RIFF');
    data.setUint32(4, bytes.length - 8, Endian.little);
    writeAscii(8, 'WAVE');
    writeAscii(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, sampleRate, Endian.little);
    data.setUint32(28, sampleRate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    writeAscii(36, 'data');
    data.setUint32(40, sampleCount * 2, Endian.little);

    for (var i = 0; i < sampleCount; i++) {
      final progress = i / sampleRate;
      final sweep = (math.sin(progress * math.pi) + 1) / 2;
      final frequency = 620 + sweep * 600;
      final envelope = 0.16 + 0.08 * math.sin(progress * math.pi * 2);
      final value =
          (math.sin(2 * math.pi * frequency * progress) * envelope * 32767)
              .round()
              .clamp(-32768, 32767);
      data.setInt16(44 + i * 2, value, Endian.little);
    }
    return bytes;
  }
}
