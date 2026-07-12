import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/state/app_store.dart';
import '../../shared/widgets/bottom_nav.dart';
import '../../shared/widgets/agenda_confirm_dialog.dart';
import '../../shared/widgets/late_off_work_dialog.dart';
import '../../shared/widgets/demotion_confirm_dialog.dart';
import '../../shared/widgets/smart_time_suggestion_dialog.dart';
import '../../shared/widgets/chain_reminder_dialog.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/ask/presentation/pages/ask_page.dart';
import '../../features/habits/presentation/pages/habits_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';

/// 主布局 - 对齐 MainLayout.tsx
/// 包含底部导航栏，首页额外显示记录输入按钮
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  bool _lateOffWorkDialogShown = false;
  bool _demotionDialogShown = false;
  bool _smartTimeDialogShown = false;
  bool _chainReminderDialogShown = false;
  bool _postFrameScheduled = false;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();

    // 监听策略弹窗
    if (!_postFrameScheduled) {
      _postFrameScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _postFrameScheduled = false;
        // 策略3：连续失败降级
        if (store.demotionPendingResult != null && !_demotionDialogShown) {
          _demotionDialogShown = true;
          showDemotionConfirmDialog(context: context, result: store.demotionPendingResult!).then((_) {
            _demotionDialogShown = false;
          });
        }
        // 策略4：智能时间推荐
        if (store.smartTimeSuggestion != null && !_smartTimeDialogShown) {
          _smartTimeDialogShown = true;
          showSmartTimeSuggestionDialog(context: context, suggestion: store.smartTimeSuggestion!).then((_) {
            _smartTimeDialogShown = false;
          });
        }
        // 策略5：链式事程提醒
        if (store.chainReminderResult != null && !_chainReminderDialogShown) {
          _chainReminderDialogShown = true;
          showChainReminderDialog(context: context, result: store.chainReminderResult!).then((_) {
            _chainReminderDialogShown = false;
          });
        }
        // 晚下班检测
        if (store.lateOffWorkResult != null && !_lateOffWorkDialogShown) {
          _lateOffWorkDialogShown = true;
          showLateOffWorkDialog(context: context, result: store.lateOffWorkResult!).then((_) {
            _lateOffWorkDialogShown = false;
          });
        }
      });
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildCurrentPage(store.activeTab)),
            if (store.activeTab == 'home' && !store.isHomeOverlayOpen)
              _buildHomeInputBar(context),
            const BottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeInputBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.bgSecondary,
      child: Row(
        children: [
          // 左侧文字输入按钮
          GestureDetector(
            onTap: () => _showRecordDialog(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(AppIcons.keyboard, size: 20, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 8),
          // 右侧语音输入按钮
          Expanded(
            child: _HomeVoiceButton(),
          ),
        ],
      ),
    );
  }

  void _showRecordDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => const _RecordNowDialog(),
    );
  }

  Widget _buildCurrentPage(String tab) {
    switch (tab) {
      case 'home':
        return const HomePage();
      case 'ask':
        return const AskPage();
      case 'habits':
        return const HabitsPage();
      case 'profile':
        return const ProfilePage();
      default:
        return const HomePage();
    }
  }
}

/// 首页底部语音按钮 - 按住说话，松开后直接记录到时间线
class _HomeVoiceButton extends StatefulWidget {
  @override
  State<_HomeVoiceButton> createState() => _HomeVoiceButtonState();
}

class _HomeVoiceButtonState extends State<_HomeVoiceButton> {
  bool _isRecording = false;
  int _recordSeconds = 0;

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _recordSeconds = 0;
    });
    _startTimer();
  }

  void _startTimer() async {
    while (_isRecording) {
      await Future.delayed(const Duration(seconds: 1));
      if (!_isRecording) return;
      if (!mounted) return;
      setState(() => _recordSeconds++);
      if (_recordSeconds >= 60) {
        _stopRecording();
        return;
      }
    }
  }

  void _stopRecording() async {
    if (!_isRecording) return;
    setState(() => _isRecording = false);
    // 模拟语音识别结果
    const voiceText = '起床，洗漱';
    // 使用AI意图识别
    final store = context.read<AppStore>();
    final result = await store.submitVoiceRecordWithAI(voiceText);
    final pendingAgendas = store.pendingAgendaConfirm;
    final intentResult = result['_intentResult'];

    if (!mounted) return;

    // 如果有待确认事程，弹出智能确认弹窗（即使是模拟语音，也要走完整流程）
    if (pendingAgendas.isNotEmpty && intentResult != null) {
      await showSmartAgendaConfirmDialog(
        context: context,
        originalText: voiceText,
        intentResult: intentResult,
        pendingAgendas: pendingAgendas,
        countdownSeconds: 4,
      );
    }
  }

  void _cancelRecording() {
    if (!_isRecording) return;
    setState(() => _isRecording = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _startRecording(),
      onTapUp: (_) => _stopRecording(),
      onTapCancel: () => _cancelRecording(),
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
            Icon(_isRecording ? AppIcons.square : AppIcons.mic, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              _isRecording ? '录音中 ${_recordSeconds}s' : '点击说话，记录现在在做什么',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_isRecording) ...[
              const SizedBox(width: 8),
              _buildWaveDots(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWaveDots() {
    return Row(
      children: List.generate(4, (i) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 3,
          height: (_recordSeconds + i) % 3 == 0 ? 10 : ((_recordSeconds + i) % 3 == 1 ? 6 : 14),
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(1.5),
          ),
        );
      }),
    );
  }
}

class _RecordNowDialog extends StatefulWidget {
  const _RecordNowDialog();

  @override
  State<_RecordNowDialog> createState() => _RecordNowDialogState();
}

class _RecordNowDialogState extends State<_RecordNowDialog> {
  final TextEditingController _controller = TextEditingController();

  final List<String> _quickTags = [
    '回家放钥匙',
    '买东西',
    '喝水（完成）',
    '拿快递',
    '提醒吃药',
    '多项提醒',
    '刚吃完（完成）',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    // 使用AI意图识别
    final store = context.read<AppStore>();
    final result = await store.submitVoiceRecordWithAI(text);
    final pendingAgendas = store.pendingAgendaConfirm;
    final intentResult = result['_intentResult'];

    if (!mounted) return;
    // 先获取根 navigator context，再 pop 当前弹窗，避免使用已失效的 context
    final rootContext = Navigator.of(context).context;
    Navigator.pop(context);

    // 如果有待确认事程，弹出智能确认弹窗
    if (pendingAgendas.isNotEmpty && intentResult != null) {
      await showSmartAgendaConfirmDialog(
        context: rootContext,
        originalText: text,
        intentResult: intentResult,
        pendingAgendas: pendingAgendas,
        countdownSeconds: 4,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.bgTertiary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(AppIcons.edit2, size: 20, color: AppColors.accent),
                  const SizedBox(width: 6),
                  const Text('记录现在', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(AppIcons.x, size: 20, color: AppColors.textTertiary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('输入你现在正在做什么，系统会自动识别标签', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              // 输入框
              Container(
                decoration: BoxDecoration(
                  color: AppColors.bgTertiary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.accent, width: 1),
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: '如：回家，钥匙放在门口鞋柜上了',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // 快捷标签
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickTags.map((tag) => GestureDetector(
                  onTap: () {
                    setState(() => _controller.text = tag);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.bgTertiary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(tag, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 20),
              // 按钮
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _submit,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                            Icon(AppIcons.send, size: 16),
                            SizedBox(width: 6),
                            Text('记录'),
                          ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
