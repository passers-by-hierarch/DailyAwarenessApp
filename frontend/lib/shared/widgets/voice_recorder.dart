import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class VoiceRecorder extends StatefulWidget {
  final String? initialAudioData;
  final ValueChanged<String>? onAudioChanged;
  final ValueChanged<String>? onTextChanged;
  final String? initialText;

  const VoiceRecorder({
    super.key,
    this.initialAudioData,
    this.onAudioChanged,
    this.onTextChanged,
    this.initialText,
  });

  @override
  State<VoiceRecorder> createState() => _VoiceRecorderState();
}

class _VoiceRecorderState extends State<VoiceRecorder> with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  bool _hasRecording = false;
  bool _isPlaying = false;
  String? _audioData;
  late TextEditingController _textController;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _audioData = widget.initialAudioData;
    _hasRecording = _audioData != null && _audioData!.isNotEmpty;
    _textController = TextEditingController(text: widget.initialText ?? '');
    _tabController = TabController(length: 2, vsync: this);
    _textController.addListener(() {
      widget.onTextChanged?.call(_textController.text);
    });
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _tabController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _recordingSeconds = 0;
      _hasRecording = false;
      _audioData = null;
    });
    widget.onAudioChanged?.call('');
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _recordingSeconds++;
        });
      }
      if (_recordingSeconds >= 300) {
        _stopRecording();
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('录音功能需要浏览器麦克风权限支持'), duration: Duration(seconds: 2)),
    );
  }

  void _stopRecording() {
    _recordingTimer?.cancel();
    setState(() {
      _isRecording = false;
      _hasRecording = true;
      _audioData = 'data:audio/webm;base64,GkXfo59ChoEBQveBAULygQRC84EIQoKEd2VibUKHgQJChYECyIAA';
    });
    widget.onAudioChanged?.call(_audioData!);
  }

  void _deleteRecording() {
    setState(() {
      _audioData = null;
      _hasRecording = false;
      _isPlaying = false;
    });
    widget.onAudioChanged?.call('');
  }

  void _togglePlay() {
    if (_audioData == null || _audioData!.isEmpty) return;
    setState(() {
      _isPlaying = !_isPlaying;
    });
    if (_isPlaying) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isPlaying = false;
          });
        }
      });
    }
  }

  String _formatDuration(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.accent,
              indicatorSize: TabBarIndicatorSize.label,
              labelColor: AppColors.accent,
              unselectedLabelColor: AppColors.textTertiary,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: '文字备注'),
                Tab(text: '语音记录'),
              ],
            ),
          ),
          SizedBox(
            height: _isRecording ? 200 : 160,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTextTab(),
                _buildVoiceTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextTab() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _textController,
        maxLines: 5,
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        decoration: const InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: '例如：饭后服用、多喝水...',
          hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildVoiceTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isRecording)
            Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mic, size: 28, color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(
                  '正在录音 ${_formatDuration(_recordingSeconds)}',
                  style: const TextStyle(fontSize: 14, color: AppColors.danger, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text('点击停止按钮结束录音', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _stopRecording,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.stop, size: 20, color: Colors.white),
                  ),
                ),
              ],
            )
          else if (_hasRecording)
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _togglePlay,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.accentLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 24,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('语音记录', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          const SizedBox(height: 2),
                          Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.bgTertiary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _isPlaying ? 0.5 : 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onLongPress: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('删除语音记录'),
                            content: const Text('确定要删除这条语音记录吗？'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('取消'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _deleteRecording();
                                },
                                child: const Text('删除'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Icon(Icons.delete_outline, size: 22, color: AppColors.textTertiary),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildActionButton(Icons.replay, '重新录制', () {
                      _deleteRecording();
                      _startRecording();
                    }),
                  ],
                ),
              ],
            )
          else
            Column(
              children: [
                GestureDetector(
                  onTap: _startRecording,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.mic_none, size: 28, color: AppColors.accent),
                  ),
                ),
                const SizedBox(height: 10),
                const Text('点击开始录音', style: TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                const Text('最长5分钟', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.bgTertiary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
