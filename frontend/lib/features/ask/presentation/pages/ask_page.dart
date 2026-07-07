import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';

import '../../../../core/mock/mock_data.dart';
import '../../../../core/models/app_models.dart';
import '../../../../core/services/speech_service.dart';
import '../../../../core/services/tts_service.dart';
import '../../../../core/state/app_store.dart';

class AskPage extends StatefulWidget {
  const AskPage({super.key});

  @override
  State<AskPage> createState() => _AskPageState();
}

class _AskPageState extends State<AskPage> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _tts = TtsService();
  final _speech = SpeechService();
  bool _isGenerating = false;
  String? _speakingMessageId;
  String? _streamingMessageId;
  String _streamingContent = '';
  StreamSubscription<String>? _streamSub;
  StreamSubscription<String>? _speechSub;
  String? _lastQuestion;
  String? _errorMsg;
  bool _isRecording = false;
  String _recordingText = '';
  int _recordingSeconds = 0;
  Timer? _recordingTimer;

  @override
  void initState() {
    super.initState();
    _speechSub = _speech.resultStream.listen((text) {
      if (mounted && _isRecording) {
        setState(() => _recordingText = text);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _tts.dispose();
    _streamSub?.cancel();
    _speechSub?.cancel();
    _recordingTimer?.cancel();
    _speech.cancelListening();
    super.dispose();
  }

  void _toggleSpeak(String messageId, String content) {
    if (_speakingMessageId == messageId) {
      _tts.stop();
      setState(() => _speakingMessageId = null);
    } else {
      setState(() => _speakingMessageId = messageId);
      _tts.speak(content).then((_) {
        if (mounted) setState(() => _speakingMessageId = null);
      });
    }
  }

  void _sendMessage(String text) {
    final store = Provider.of<AppStore>(context, listen: false);
    if (text.trim().isEmpty) return;
    if (_isGenerating) return;

    final userMsg = ChatMessage(
      id: 'u_${DateTime.now().millisecondsSinceEpoch}',
      role: 'user',
      content: text.trim(),
      time: DateTime.now(),
    );
    store.addChatMessage(userMsg);
    _inputCtrl.clear();
    _lastQuestion = text.trim();
    _errorMsg = null;

    // 先检查是否是确认/取消关键词
    final confirmKeywords = ['好', '好的', '是的', '是', '添加', '确认', '可以', '没问题', '行'];
    final rejectKeywords = ['不', '不用', '算了', '不要', '暂不'];

    if (confirmKeywords.any((kw) => text.contains(kw)) || rejectKeywords.any((kw) => text.contains(kw))) {
      final isConfirm = confirmKeywords.any((kw) => text.contains(kw));
      final habitResult = store.confirmAddHabit(isConfirm);
      String reply;
      if (!habitResult.contains('没有待确认的习惯计划')) {
        reply = habitResult;
      } else {
        reply = store.confirmAddPlan(isConfirm);
      }
      store.addChatMessage(ChatMessage(
        id: 'a_${DateTime.now().millisecondsSinceEpoch}',
        role: 'assistant',
        content: reply,
        time: DateTime.now(),
      ));
      _scrollToBottom();
      return;
    }

    // 显示时间线摘要作为上下文提示
    final timelineSummary = store.getTimelineSummary();
    if (timelineSummary.isNotEmpty && !timelineSummary.contains('暂无')) {
      store.addChatMessage(ChatMessage(
        id: 'ctx_${DateTime.now().millisecondsSinceEpoch}',
        role: 'context',
        content: timelineSummary,
        time: DateTime.now(),
      ));
    }

    // 启动流式生成
    final msgId = 'a_${DateTime.now().millisecondsSinceEpoch}';
    setState(() {
      _isGenerating = true;
      _streamingMessageId = msgId;
      _streamingContent = '';
    });

    _scrollToBottom();

    _streamSub?.cancel();
    // 多轮对话：传入历史消息（去掉刚刚添加的当前问题和上下文）
    final history = store.chatMessages.length > 2
        ? store.chatMessages.sublist(0, store.chatMessages.length - 2)
        : <ChatMessage>[];
    _streamSub = store.answerQuestionStream(text.trim(), history: history).listen(
      (content) {
        if (!mounted) return;
        setState(() {
          _streamingContent = content;
        });
        _scrollToBottom();
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _errorMsg = error.toString();
          _isGenerating = false;
        });
        // 保存错误提示作为消息
        store.addChatMessage(ChatMessage(
          id: msgId,
          role: 'assistant',
          content: '抱歉，回答时出错了：$error\n您可以点击重试，或检查网络连接。',
          time: DateTime.now(),
        ));
        _scrollToBottom();
      },
      onDone: () {
        if (!mounted) return;
        if (_errorMsg != null) return;
        // 保存最终回复
        if (_streamingContent.isNotEmpty) {
          store.addChatMessage(ChatMessage(
            id: msgId,
            role: 'assistant',
            content: _streamingContent,
            time: DateTime.now(),
          ));
        }
        setState(() {
          _isGenerating = false;
          _streamingMessageId = null;
        });
        _scrollToBottom();
      },
    );
  }

  void _retryLast() {
    if (_lastQuestion != null) {
      _sendMessage(_lastQuestion!);
    }
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _recordingText = '';
      _recordingSeconds = 0;
    });
    _speech.startListening();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isRecording) {
        timer.cancel();
        return;
      }
      setState(() => _recordingSeconds++);
      if (_recordingSeconds >= 60) {
        _stopRecording();
      }
    });
  }

  void _stopRecording() async {
    _recordingTimer?.cancel();
    setState(() => _isRecording = false);
    await _speech.stopListening();

    final text = _speech.lastResult.trim().isNotEmpty
        ? _speech.lastResult.trim()
        : _recordingText.trim();

    if (text.isNotEmpty) {
      _sendMessage(text);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final messages = store.chatMessages;
    final hasLlm = store.llmEnabled;

    return Container(
      color: AppColors.bgPrimary,
      child: Column(
        children: [
          _buildTopBar(hasLlm),
          _buildAIHeader(),
          _buildQuickQuestions(),
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: messages.length + (_isGenerating ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (i == messages.length && _isGenerating) {
                  return _buildStreamingBubble();
                }
                return _buildMessageBubble(messages[i]);
              },
            ),
          ),
          if (_errorMsg != null) _buildErrorBar(),
          _buildInputBar(hasLlm),
        ],
      ),
    );
  }

  Widget _buildTopBar(bool hasLlm) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          // 返回按钮
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.chevron_left,
              size: 24,
              color: AppColors.textPrimary,
            ),
          ),
          // 居中标题
          Expanded(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('问一问', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  if (hasLlm) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accentLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('AI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.accent)),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // 历史记录按钮
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/chat-history'),
            child: const Text('历史记录', style: TextStyle(fontSize: 14, color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  Widget _buildAIHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: AppColors.bgPrimary,
      child: Column(
        children: [
          // AI头像 - 64px圆形
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy,
              size: 32,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 12),
          // 欢迎语
          const Text(
            '我是你的日常助手，有什么可以帮你的吗？',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickQuestions() {
    final store = Provider.of<AppStore>(context, listen: false);
    final frequent = store.frequentQuestions;
    
    List<String> questionsToShow;
    if (frequent.isNotEmpty) {
      questionsToShow = frequent;
    } else {
      questionsToShow = MockData.mockQuickQuestions.map((q) => q.text).toList();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.bgPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            frequent.isNotEmpty ? '常用问题' : '快捷问题',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: questionsToShow.map((q) {
              return GestureDetector(
                onTap: () => _sendMessage(q),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.bgSecondary,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getQuickQuestionIcon(q),
                        size: 16,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        q,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  IconData _getQuickQuestionIcon(String text) {
    if (text.contains('药') || text.contains('服药')) return Icons.medication;
    if (text.contains('事程') || text.contains('计划')) return Icons.calendar_today;
    if (text.contains('运动')) return Icons.directions_run;
    if (text.contains('饮食') || text.contains('饭')) return Icons.restaurant;
    if (text.contains('睡眠') || text.contains('睡觉')) return Icons.bedtime;
    if (text.contains('报告') || text.contains('周报')) return Icons.bar_chart;
    return Icons.help_outline;
  }

  Widget _buildInputBar(bool hasLlm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.bgSecondary,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            if (_isRecording) _buildRecordingIndicator(),
            Row(
              children: [
                GestureDetector(
                  onTapDown: (_) => _startRecording(),
                  onTapUp: (_) => _stopRecording(),
                  onTapCancel: () {
                    if (_isRecording) {
                      setState(() => _isRecording = false);
                      _recordingTimer?.cancel();
                      _speech.cancelListening();
                    }
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _isRecording ? AppColors.dangerLight : AppColors.bgTertiary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isRecording ? Icons.fiber_manual_record : Icons.mic,
                      size: 16,
                      color: _isRecording ? AppColors.danger : AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.bgTertiary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      controller: _inputCtrl,
                      onSubmitted: _sendMessage,
                      enabled: !_isGenerating && !_isRecording,
                      decoration: InputDecoration(
                        hintText: '输入您的问题...',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: (_isGenerating || _isRecording) ? null : () => _sendMessage(_inputCtrl.text),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: (_isGenerating || _isRecording) ? AppColors.textTertiary : AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isGenerating ? Icons.stop : Icons.send,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.dangerLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fiber_manual_record, color: AppColors.danger, size: 14),
          const SizedBox(width: 8),
          Text(
            '录音中 ${_recordingSeconds}秒',
            style: const TextStyle(fontSize: 13, color: AppColors.danger),
          ),
          const SizedBox(width: 8),
          if (_recordingText.isNotEmpty)
            Expanded(
              child: Text(
                _recordingText,
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: AppColors.dangerLight,
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 16, color: AppColors.danger),
          const SizedBox(width: 6),
          const Expanded(
            child: Text('回答出错，点击重试', style: TextStyle(fontSize: 12, color: AppColors.danger)),
          ),
          GestureDetector(
            onTap: _retryLast,
            child: const Text('重试', style: TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.role == 'user';
    final isContext = msg.role == 'context';
    final timeStr = '${msg.time.hour.toString().padLeft(2, '0')}:${msg.time.minute.toString().padLeft(2, '0')}';

    if (isContext) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.accentLight.withOpacity(0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.accentLight, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, size: 14, color: AppColors.accent),
                const SizedBox(width: 6),
                Text('时间线参考', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              msg.content.replaceAll('今天的时间线记录：\n', ''),
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.accentLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy, color: AppColors.accent, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.accent : AppColors.bgSecondary,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        msg.content,
                        style: TextStyle(
                          fontSize: 15,
                          color: isUser ? Colors.white : AppColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                      if (!isUser) ...[
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _toggleSpeak(msg.id, msg.content),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _speakingMessageId == msg.id
                                  ? AppColors.dangerLight
                                  : AppColors.accentLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _speakingMessageId == msg.id ? Icons.stop : Icons.volume_up,
                                  size: 12,
                                  color: _speakingMessageId == msg.id ? AppColors.danger : AppColors.accent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _speakingMessageId == msg.id ? '停止' : '朗读',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _speakingMessageId == msg.id ? AppColors.danger : AppColors.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(timeStr, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.bgTertiary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: AppColors.textSecondary, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStreamingBubble() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI头像 - 32px圆形
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.accentLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy, color: AppColors.accent, size: 16),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(4),
                ),
                boxShadow: AppColors.cardShadow,
              ),
              child: _streamingContent.isEmpty
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (i) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(color: AppColors.textTertiary, shape: BoxShape.circle),
                        child: AnimatedOpacity(
                          opacity: _isGenerating ? 1.0 : 0.3,
                          duration: Duration(milliseconds: 400 + i * 200),
                        ),
                      )),
                    )
                  : Text(
                      _streamingContent,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
