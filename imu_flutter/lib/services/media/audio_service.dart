import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

/// Audio recording service for voice memos
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isRecording = false;
  bool _isPlaying = false;
  String? _currentRecordingPath;
  String? _currentlyPlayingPath;

  // Getters
  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  String? get currentRecordingPath => _currentRecordingPath;

  /// Check if microphone permission is granted
  Future<bool> checkPermission() async {
    return await _audioRecorder.hasPermission();
  }

  /// Request microphone permission
  Future<bool> requestPermission() async {
    final hasPermission = await _audioRecorder.hasPermission();
    return hasPermission;
  }

  /// Start recording
  Future<bool> startRecording() async {
    if (_isRecording) return false;

    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) {
        debugPrint('Microphone permission not granted');
        return false;
      }

      final directory = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory('${directory.path}/recordings');
      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${recordingsDir.path}/voice_$timestamp.m4a';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 44100,
          numChannels: 1,
          bitRate: 128000,
        ),
        path: _currentRecordingPath!,
      );

      _isRecording = true;
      debugPrint('Recording started: $_currentRecordingPath');
      return true;
    } catch (e) {
      debugPrint('Error starting recording: $e');
      return false;
    }
  }

  /// Stop recording and return the file path
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;

    try {
      final path = await _audioRecorder.stop();
      _isRecording = false;
      debugPrint('Recording stopped: $path');
      return path;
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      _isRecording = false;
      return null;
    }
  }

  /// Cancel recording
  Future<void> cancelRecording() async {
    if (!_isRecording) return;

    try {
      await _audioRecorder.stop();
      _isRecording = false;

      // Delete the file
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      _currentRecordingPath = null;
      debugPrint('Recording cancelled');
    } catch (e) {
      debugPrint('Error cancelling recording: $e');
      _isRecording = false;
    }
  }

  /// Play a recording
  Future<void> playRecording(String path) async {
    if (_isPlaying) {
      await stopPlayback();
    }

    try {
      _currentlyPlayingPath = path;
      _isPlaying = true;

      await _audioPlayer.play(DeviceFileSource(path));

      // Listen for completion
      _audioPlayer.onPlayerComplete.listen((_) {
        _isPlaying = false;
        _currentlyPlayingPath = null;
      });
    } catch (e) {
      debugPrint('Error playing recording: $e');
      _isPlaying = false;
    }
  }

  /// Stop playback
  Future<void> stopPlayback() async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
      _currentlyPlayingPath = null;
    } catch (e) {
      debugPrint('Error stopping playback: $e');
    }
  }

  /// Pause playback
  Future<void> pausePlayback() async {
    try {
      await _audioPlayer.pause();
      _isPlaying = false;
    } catch (e) {
      debugPrint('Error pausing playback: $e');
    }
  }

  /// Resume playback
  Future<void> resumePlayback() async {
    try {
      await _audioPlayer.resume();
      _isPlaying = true;
    } catch (e) {
      debugPrint('Error resuming playback: $e');
    }
  }

  /// Get recording duration
  Future<Duration?> getRecordingDuration(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return null;

      // For now, return null - would need to read audio file metadata
      return null;
    } catch (e) {
      debugPrint('Error getting recording duration: $e');
      return null;
    }
  }

  /// Delete a recording
  Future<bool> deleteRecording(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting recording: $e');
      return false;
    }
  }

  /// Get all recordings
  Future<List<File>> getAllRecordings() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory('${directory.path}/recordings');

      if (!await recordingsDir.exists()) {
        return [];
      }

      final files = await recordingsDir.list().toList();
      return files
          .whereType<File>()
          .where((f) => f.path.endsWith('.m4a'))
          .toList();
    } catch (e) {
      debugPrint('Error getting recordings: $e');
      return [];
    }
  }

  /// Dispose resources
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
  }
}

/// Voice recording widget with controls
class VoiceRecordingWidget extends StatefulWidget {
  final String? existingRecordingPath;
  final Function(String) onRecordingSaved;
  final VoidCallback? onRecordingDeleted;

  const VoiceRecordingWidget({
    super.key,
    this.existingRecordingPath,
    required this.onRecordingSaved,
    this.onRecordingDeleted,
  });

  @override
  State<VoiceRecordingWidget> createState() => _VoiceRecordingWidgetState();
}

class _VoiceRecordingWidgetState extends State<VoiceRecordingWidget> {
  final AudioService _audioService = AudioService();
  String? _recordingPath;
  bool _isRecording = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _recordingPath = widget.existingRecordingPath;
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _audioService.stopRecording();
      if (path != null) {
        setState(() {
          _recordingPath = path;
          _isRecording = false;
        });
        widget.onRecordingSaved(path);
      }
    } else {
      final started = await _audioService.startRecording();
      if (started) {
        setState(() => _isRecording = true);
      }
    }
  }

  Future<void> _togglePlayback() async {
    if (_recordingPath == null) return;

    if (_isPlaying) {
      await _audioService.stopPlayback();
      setState(() => _isPlaying = false);
    } else {
      await _audioService.playRecording(_recordingPath!);
      setState(() => _isPlaying = true);
    }
  }

  Future<void> _deleteRecording() async {
    if (_recordingPath == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recording'),
        content: const Text('Are you sure you want to delete this recording?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _audioService.deleteRecording(_recordingPath!);
      setState(() => _recordingPath = null);
      widget.onRecordingDeleted?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Recording button
              GestureDetector(
                onTap: _toggleRecording,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _isRecording ? Colors.red : Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),

              if (_recordingPath != null) ...[
                const SizedBox(width: 24),

                // Playback button
                GestureDetector(
                  onTap: _togglePlayback,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.grey[700],
                      size: 28,
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Delete button
                GestureDetector(
                  onTap: _deleteRecording,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.red,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 12),

          Text(
            _isRecording
                ? 'Recording... Tap to stop'
                : _recordingPath != null
                    ? 'Recording saved. Tap mic to re-record.'
                    : 'Tap to start recording',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
