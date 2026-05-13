import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

final voiceServiceProvider = Provider((ref) => VoiceService());

class VoiceService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;
  VoidCallback? _onDoneCallback;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    var status = await Permission.microphone.status;
    if (status.isDenied) {
      status = await Permission.microphone.request();
    }
    
    if (status.isPermanentlyDenied || status.isRestricted) {
      return false;
    }

    _isInitialized = await _speech.initialize(
      onStatus: (status) {
        print('Speech status: $status');
        if (status == 'done' || status == 'notListening') {
          _onDoneCallback?.call();
          _onDoneCallback = null;
        }
      },
      onError: (errorNotification) {
        print('Speech error: $errorNotification');
        _onDoneCallback?.call();
        _onDoneCallback = null;
      },
    );
    
    return _isInitialized;
  }

  Future<void> startListening({
    required Function(String) onResult,
    required VoidCallback onDone,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return;
    }

    _onDoneCallback = onDone;

    await _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3), // Reduced pause time for faster auto-submit
      partialResults: true,
      cancelOnError: true,
      listenMode: ListenMode.confirmation,
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  bool get isListening => _speech.isListening;
}
