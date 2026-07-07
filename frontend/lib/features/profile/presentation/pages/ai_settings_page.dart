import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/llm_service.dart';
import '../../../../core/state/app_store.dart';

/// AI 设置页面
class AiSettingsPage extends StatefulWidget {
  const AiSettingsPage({super.key});

  @override
  State<AiSettingsPage> createState() => _AiSettingsPageState();
}

class _AiSettingsPageState extends State<AiSettingsPage> {
  final _apiKeyCtrl = TextEditingController();
  final _baseUrlCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _temperatureCtrl = TextEditingController();
  final _maxTokensCtrl = TextEditingController();
  final _contextLengthCtrl = TextEditingController();
  bool _enabled = false;
  bool _obscureKey = true;
  bool _isTesting = false;
  String? _testResult;
  bool _streamOutput = true;
  bool _autoTts = false;
  bool _fallbackToRules = true;

  final List<Map<String, String>> _presets = [
    {'name': '智谱 GLM-4-Flash', 'baseUrl': 'https://open.bigmodel.cn/api/paas/v4', 'model': 'glm-4-flash'},
    {'name': 'DeepSeek V3', 'baseUrl': 'https://api.deepseek.com/v1', 'model': 'deepseek-chat'},
    {'name': '通义千问 Qwen', 'baseUrl': 'https://dashscope.aliyuncs.com/compatible-mode/v1', 'model': 'qwen-plus'},
    {'name': 'OpenAI GPT', 'baseUrl': 'https://api.openai.com/v1', 'model': 'gpt-4o-mini'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final store = context.read<AppStore>();
      final config = store.llmConfig;
      setState(() {
        _enabled = config.enabled;
        _apiKeyCtrl.text = config.apiKey;
        _baseUrlCtrl.text = config.baseUrl;
        _modelCtrl.text = config.model;
        _temperatureCtrl.text = config.temperature.toString();
        _maxTokensCtrl.text = config.maxTokens.toString();
        _contextLengthCtrl.text = store.llmContextLength.toString();
        _streamOutput = store.llmStreamOutput;
        _autoTts = store.llmAutoTts;
        _fallbackToRules = store.llmFallbackToRules;
      });
    });
  }

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    _baseUrlCtrl.dispose();
    _modelCtrl.dispose();
    _temperatureCtrl.dispose();
    _maxTokensCtrl.dispose();
    _contextLengthCtrl.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final store = context.read<AppStore>();
    final config = LlmConfig(
      enabled: _enabled,
      apiKey: _apiKeyCtrl.text.trim(),
      baseUrl: _baseUrlCtrl.text.trim(),
      model: _modelCtrl.text.trim(),
      temperature: double.tryParse(_temperatureCtrl.text) ?? 0.7,
      maxTokens: int.tryParse(_maxTokensCtrl.text) ?? 1000,
    );
    store.saveLlmConfig(config);
    store.saveLlmEnhancedSettings(
      contextLength: int.tryParse(_contextLengthCtrl.text) ?? 6,
      streamOutput: _streamOutput,
      autoTts: _autoTts,
      fallbackToRules: _fallbackToRules,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('设置已保存'), duration: Duration(seconds: 2)),
    );
  }

  void _testConnection() async {
    if (_apiKeyCtrl.text.trim().isEmpty) {
      setState(() => _testResult = '✗ 请先输入 API Key');
      return;
    }
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final testConfig = LlmConfig(
      enabled: true,
      apiKey: _apiKeyCtrl.text.trim(),
      baseUrl: _baseUrlCtrl.text.trim(),
      model: _modelCtrl.text.trim(),
      temperature: 0.7,
      maxTokens: 100,
    );

    final testService = LlmService();

    try {
      final result = await testService.testWithConfig(testConfig, const [ChatMsg('user', '你好，请用一句话打招呼')]);
      setState(() {
        _testResult = '✓ 连接成功！\n回复：${result.length > 60 ? "${result.substring(0, 60)}..." : result}';
      });
    } catch (e) {
      setState(() {
        final err = e.toString();
        _testResult = '✗ 连接失败\n${err.length > 100 ? err.substring(0, 100) : err}';
      });
    } finally {
      setState(() => _isTesting = false);
    }
  }

  void _applyPreset(int index) {
    final preset = _presets[index];
    setState(() {
      _baseUrlCtrl.text = preset['baseUrl']!;
      _modelCtrl.text = preset['model']!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSecondary,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 22),
        ),
        title: const Text('AI 设置', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.accent, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('启用 AI 问答', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                        SizedBox(height: 2),
                        Text('开启后将使用大模型回答问题', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _enabled,
                    onChanged: (v) => setState(() => _enabled = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const Text('快速选择模型', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            ...List.generate(_presets.length, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => _applyPreset(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.bgSecondary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _baseUrlCtrl.text == _presets[i]['baseUrl'] && _modelCtrl.text == _presets[i]['model']
                          ? AppColors.accent
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(_presets[i]['name']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.textTertiary),
                    ],
                  ),
                ),
              ),
            )),
            const SizedBox(height: 16),

            const Text('API Key', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _apiKeyCtrl,
                      obscureText: _obscureKey,
                      decoration: const InputDecoration(
                        hintText: '请输入 API Key',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _obscureKey = !_obscureKey),
                    child: Icon(
                      _obscureKey ? Icons.visibility_off : Icons.visibility,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            const Text('接口地址 (Base URL)', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _baseUrlCtrl,
                decoration: const InputDecoration(
                  hintText: 'https://api.openai.com/v1',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                style: const TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),

            const Text('模型名称', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _modelCtrl,
                decoration: const InputDecoration(
                  hintText: 'gpt-4o-mini',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                style: const TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),

            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 16),

            const Text('高级设置', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 12),

            const Text('温度 (Temperature)', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _temperatureCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        hintText: '0.7',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Text('(0-2，越高越随机)', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            const Text('最大回复长度 (Max Tokens)', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _maxTokensCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: '1000',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Text('(100-4096)', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            const Text('对话历史长度', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.bgTertiary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _contextLengthCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: '6',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Text('(最近N条对话)', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 16),

            const Text('功能开关', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('流式输出', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        SizedBox(height: 2),
                        Text('打字机效果，边生成边显示', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _streamOutput,
                    onChanged: (v) => setState(() => _streamOutput = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('自动朗读', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        SizedBox(height: 2),
                        Text('回答完成后自动语音播报', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _autoTts,
                    onChanged: (v) => setState(() => _autoTts = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('规则降级', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        SizedBox(height: 2),
                        Text('网络失败时使用内置规则回答', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _fallbackToRules,
                    onChanged: (v) => setState(() => _fallbackToRules = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bgTertiary,
                  foregroundColor: AppColors.textSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _isTesting ? null : _testConnection,
                child: Text(_isTesting ? '测试中...' : '测试连接'),
              ),
            ),
            if (_testResult != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _testResult!.startsWith('✓')
                      ? AppColors.successLight
                      : AppColors.dangerLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _testResult!,
                  style: TextStyle(
                    fontSize: 12,
                    color: _testResult!.startsWith('✓')
                        ? AppColors.success
                        : AppColors.danger,
                    height: 1.4,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _saveSettings,
                child: const Text('保存设置', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentLight.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('💡 温馨提示', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent)),
                  SizedBox(height: 6),
                  Text(
                    '• API Key 仅保存在本地，不会上传\n'
                    '• 支持所有 OpenAI 兼容接口的大模型\n'
                    '• 网络不佳时自动使用内置规则回答\n'
                    '• 涉及医疗建议请咨询专业医生',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
