import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/services/speech_service.dart';
import '../../core/state/app_store.dart';
import 'agenda_confirm_dialog.dart';

/// 语音按钮 - 按住开始录音，松手停止
/// 三态机：idle / recording / submitted
/// 仅在首页显示
class VoiceButton extends StatefulWidget {
  final VoidCallback? onRecordComplete;
  const VoiceButton({super.key, this.onRecordComplete});

  @override
  State<VoiceButton> createState() => _VoiceButtonState();
}

class _VoiceButtonState extends State<VoiceButton>
    with SingleTickerProviderStateMixin {
  final SpeechService _speech = SpeechService();
  bool _isRecording = false;
  bool _showSubmitted = false;
  String _submittedText = '';
  String _liveText = ''; // 实时识别文本
  int _recordSeconds = 0;
  late AnimationController _pulseController;
  StreamSubscription<String>? _resultSub;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _resultSub = _speech.resultStream.listen((text) {
      if (mounted && _isRecording) {
        setState(() => _liveText = text);
      }
    });
  }

  @override
  void dispose() {
    _resultSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  /// 按下开始录音（拖拽手势）
  void _onPanDown(DragDownDetails details) {
    _startRecording();
  }

  /// 松手停止录音（拖拽手势）
  void _onPanEnd(DragEndDetails details) {
    _stopRecording();
  }

  /// 移出区域取消录音（拖拽手势）
  void _onPanCancel() {
    if (_isRecording) {
      _cancelRecording();
    }
  }

  /// 按下开始录音（点击手势，Web端兼容）
  void _onTapDown() {
    _startRecording();
  }

  /// 取消录音（点击手势，Web端兼容）
  void _onTapCancel() {
    if (_isRecording) {
      _cancelRecording();
    }
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _recordSeconds = 0;
      _liveText = '';
    });
    _pulseController.repeat(reverse: true);
    _speech.startListening();
    _startTimer();
  }

  void _startTimer() async {
    while (_isRecording) {
      await Future.delayed(const Duration(seconds: 1));
      if (!_isRecording) return;
      setState(() => _recordSeconds++);
      // 最大录音时长60秒，自动停止
      if (_recordSeconds >= 60) {
        _stopRecording();
        return;
      }
    }
  }

  void _stopRecording() async {
    if (!_isRecording) return;
    _pulseController.stop();
    setState(() => _isRecording = false);

    // 等待语音识别最终结果
    await _speech.stopListening();

    final text = _speech.lastResult.trim().isNotEmpty
        ? _speech.lastResult.trim()
        : _liveText.trim();

    if (text.isEmpty) {
      setState(() {
        _showSubmitted = true;
        _submittedText = '未识别到语音内容';
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _showSubmitted = false);
        }
      });
      return;
    }

    // 显示"识别中..."提示
    setState(() {
      _showSubmitted = true;
      _submittedText = '识别中...';
    });

    // 使用AI意图识别版
    final result = await context.read<AppStore>().submitVoiceRecordWithAI(text);
    final pendingAgendas = context.read<AppStore>().pendingAgendaConfirm;
    final intentResult = result['_intentResult'];

    setState(() {
      _showSubmitted = false;
    });

    // 如果有待确认事程，弹出智能确认弹窗
    if (pendingAgendas.isNotEmpty && intentResult != null) {
      final confirmed = await showSmartAgendaConfirmDialog(
        context: context,
        originalText: text,
        intentResult: intentResult,
        pendingAgendas: pendingAgendas,
        countdownSeconds: 4,
      );
      if (!mounted) return;
      if (confirmed > 0) {
        setState(() {
          _showSubmitted = true;
          _submittedText = '✓ 已创建 $confirmed 个事程';
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() => _showSubmitted = false);
            widget.onRecordComplete?.call();
          }
        });
      } else {
        setState(() {
          _showSubmitted = true;
          _submittedText = '已忽略';
        });
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() => _showSubmitted = false);
          }
        });
      }
    } else {
      setState(() {
        _showSubmitted = true;
        _submittedText = '已记录';
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _showSubmitted = false);
          widget.onRecordComplete?.call();
        }
      });
    }
  }

  void _cancelRecording() {
    _pulseController.stop();
    _speech.cancelListening();
    setState(() {
      _isRecording = false;
      _liveText = '';
    });
  }

  void _showManualInput() {
    showDialog(
      context: context,
      builder: (ctx) => _ManualInputDialog(
        onSubmit: (text) async {
          Navigator.pop(ctx);
          setState(() {
            _showSubmitted = true;
            _submittedText = '识别中...';
          });
          final result = await context.read<AppStore>().submitVoiceRecordWithAI(text);
          final pendingAgendas = context.read<AppStore>().pendingAgendaConfirm;
          final intentResult = result['_intentResult'];

          setState(() => _showSubmitted = false);

          if (pendingAgendas.isNotEmpty && intentResult != null) {
            final confirmed = await showSmartAgendaConfirmDialog(
              context: context,
              originalText: text,
              intentResult: intentResult,
              pendingAgendas: pendingAgendas,
              countdownSeconds: 4,
            );
            if (!mounted) return;
            if (confirmed > 0) {
              setState(() {
                _showSubmitted = true;
                _submittedText = '✓ 已创建 $confirmed 个事程';
              });
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  setState(() => _showSubmitted = false);
                  widget.onRecordComplete?.call();
                }
              });
            }
          } else {
            setState(() {
              _showSubmitted = true;
              _submittedText = '已记录';
            });
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                setState(() => _showSubmitted = false);
                widget.onRecordComplete?.call();
              }
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showSubmitted) {
      return _buildSubmitted();
    }
    if (_isRecording) {
      return _buildRecording();
    }
    return _buildIdle();
  }

  Widget _buildIdle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.bgSecondary,
      child: GestureDetector(
        onTapDown: (details) => _onTapDown(),
        onTapUp: (details) => _stopRecording(),
        onTapCancel: () => _onTapCancel(),
        onPanDown: _onPanDown,
        onPanEnd: _onPanEnd,
        onPanCancel: _onPanCancel,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            gradient: AppColors.voiceGradient,
            borderRadius: BorderRadius.circular(10),
            boxShadow: AppColors.buttonShadow,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(AppIcons.mic, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                '语音输入',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.95),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecording() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.bgSecondary,
      child: GestureDetector(
        onTapUp: (details) => _stopRecording(),
        onTapCancel: () => _cancelRecording(),
        onPanEnd: _onPanEnd,
        onPanCancel: _onPanCancel,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (ctx, child) {
            final pulse = 0.5 + _pulseController.value * 0.5;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.1 + pulse * 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.danger.withOpacity(pulse)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(AppIcons.circleStop, color: AppColors.danger, size: 18),
                      const SizedBox(width: 8),
                      ...List.generate(5, (i) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: 3,
                        height: 8 + (i % 3) * 6.0 * pulse,
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      )),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _liveText.isNotEmpty
                              ? _liveText
                              : '录音中 ${_recordSeconds}秒 · 点击停止保存',
                          style: const TextStyle(
                            color: AppColors.danger,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSubmitted() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.bgSecondary,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.successLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(AppIcons.circleCheck, color: AppColors.success, size: 18),
            const SizedBox(width: 8),
            Text(
              _submittedText,
              style: const TextStyle(
                color: AppColors.success,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManualInputDialog extends StatefulWidget {
  final Function(String) onSubmit;
  const _ManualInputDialog({required this.onSubmit});

  @override
  State<_ManualInputDialog> createState() => _ManualInputDialogState();
}

class _ManualInputDialogState extends State<_ManualInputDialog> {
  final _controller = TextEditingController();
  final _samples = [
    '我刚喝了水',
    '记得下午3点吃药',
    '把钥匙放在玄关',
    '在超市买了牛奶和面包',
    '今天散步了30分钟',
    '早上7点起床',
    '提醒我明天给女儿打电话',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.bgSecondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: const Text('手动输入', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '输入你想记录的内容...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            const Text('示例短语：', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _samples.map((s) => GestureDetector(
                onTap: () => setState(() => _controller.text = s),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.bgTertiary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(s, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.trim().isNotEmpty) {
              widget.onSubmit(_controller.text.trim());
            }
          },
          child: const Text('发送'),
        ),
      ],
    );
  }
}
