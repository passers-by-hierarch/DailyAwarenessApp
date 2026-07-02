import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/qa_models.dart';
import '../../domain/models/qa_source_record.dart';
import '../widgets/answer_sources_widget.dart';
import '../providers/qa_provider.dart';

class QaPage extends ConsumerStatefulWidget {
  const QaPage({super.key});

  @override
  ConsumerState<QaPage> createState() => _QaPageState();
}

class _QaPageState extends ConsumerState<QaPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _submitQuestion(String text) async {
    if (text.trim().isEmpty) return;

    final question = text.trim();
    _textController.clear();

    // 添加用户消息
    final userMessage = QaMessage.user(content: question);
    ref.read(qaMessagesProvider.notifier).addMessage(userMessage);

    // 设置处理中状态
    ref.read(qaProcessingProvider.notifier).state = true;

    // 添加处理中消息
    final processingMessage = QaMessage.assistant(
      content: '正在思考...',
      isProcessing: true,
    );
    ref.read(qaMessagesProvider.notifier).addMessage(processingMessage);
    _scrollToBottom();

    // 模拟API调用（实际应替换为真实API请求）
    await Future.delayed(const Duration(seconds: 2));

    // 模拟回答和检索记录
    final mockSources = [
      QaSourceRecord(
        id: 'record-001',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        content: '钥匙放在玄关鞋柜的抽屉里，用绿色钥匙扣挂着',
        recordType: 'item',
        relevanceScore: 0.96,
        sourceName: '物品位置',
        behaviorTag: '收纳',
      ),
      QaSourceRecord(
        id: 'record-002',
        timestamp: DateTime.now().subtract(const Duration(days: 5)),
        content: '上次使用钥匙是周三晚上回家开门',
        recordType: 'timeline',
        relevanceScore: 0.78,
        sourceName: '时间线记录',
      ),
    ];

    final answerMessage = QaMessage.assistant(
      content: '根据您的记录，钥匙放在玄关鞋柜的抽屉里（2024年6月20日记录）。上次使用是周三晚上回家开门。',
      sourceRecords: mockSources,
      confidence: 0.92,
      sessionId: ref.read(qaSessionIdProvider),
    );

    ref.read(qaMessagesProvider.notifier).updateLastMessage(answerMessage);
    ref.read(qaProcessingProvider.notifier).state = false;
    _scrollToBottom();
  }

  void _startVoiceInput(LongPressStartDetails details) {
    // TODO: 实现语音输入开始
  }

  void _endVoiceInput(LongPressEndDetails details) {
    // TODO: 实现语音输入结束
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(qaMessagesProvider);
    final isProcessing = ref.watch(qaProcessingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('问一问助理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // TODO: 打开历史记录
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 消息列表
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),

          // 输入区域
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(color: Theme.of(context).dividerTheme.color!),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // 语音按钮
                  GestureDetector(
                    onLongPressStart: _startVoiceInput,
                    onLongPressEnd: _endVoiceInput,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mic, color: Colors.white),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // 文字输入框
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: '输入问题，例如"我的钥匙在哪"...',
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: isProcessing ? null : _submitQuestion,
                      enabled: !isProcessing,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // 发送按钮
                  IconButton(
                    icon: const Icon(Icons.send),
                    color: AppColors.primary,
                    onPressed: isProcessing
                        ? null
                        : () => _submitQuestion(_textController.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(QaMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: message.isUser ? const Color(0xFFE8F0ED) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border:
                    message.isUser ? null : Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 消息内容
                  Text(
                    message.content,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),

                  // 处理中指示器
                  if (message.isProcessing)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                    ),

                  // 语音播放按钮（AI回答且有语音URL）
                  if (!message.isUser &&
                      message.answerVoiceUrl != null &&
                      message.answerVoiceUrl!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: InkWell(
                        onTap: () {
                          // TODO: 播放语音
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.volume_up,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '播放语音',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // 置信度显示
                  if (!message.isUser && message.confidence > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified,
                            size: 14,
                            color: message.confidence >= 0.8
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '置信度 ${(message.confidence * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 11,
                              color: message.confidence >= 0.8
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // 检索记录展示区域（仅AI回答显示）
                  if (!message.isUser &&
                      message.sourceRecords != null &&
                      message.sourceRecords!.isNotEmpty)
                    AnswerSourcesWidget(
                      sources: message.sourceRecords!,
                      onCopyAll: () {
                        // 可选：记录用户复制行为
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
