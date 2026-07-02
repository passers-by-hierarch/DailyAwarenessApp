import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/models/qa_source_record.dart';

/// 回答检索记录展示组件
/// 在AI回答下方以清晰、结构化的方式呈现所有相关记忆记录
class AnswerSourcesWidget extends StatefulWidget {
  const AnswerSourcesWidget({
    super.key,
    required this.sources,
    this.onCopyAll,
  });
  final List<QaSourceRecord> sources;
  final VoidCallback? onCopyAll;

  @override
  State<AnswerSourcesWidget> createState() => _AnswerSourcesWidgetState();
}

class _AnswerSourcesWidgetState extends State<AnswerSourcesWidget>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 0.5,
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  /// 复制单条记录到剪贴板
  Future<void> _copySingleRecord(QaSourceRecord record) async {
    final text = '${record.recordTypeLabel} | ${record.formattedTimestamp}\n'
        '内容：${record.content}\n'
        '相关性：${(record.relevanceScore * 100).toStringAsFixed(1)}%';

    await Clipboard.setData(ClipboardData(text: text));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已复制到剪贴板'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      );
    }
  }

  /// 复制所有记录到剪贴板
  Future<void> _copyAllRecords() async {
    final buffer = StringBuffer();
    buffer.writeln('=== 相关记忆记录 (${widget.sources.length}条) ===');
    buffer.writeln();

    for (int i = 0; i < widget.sources.length; i++) {
      final record = widget.sources[i];
      buffer.writeln('[$i] ${record.recordTypeLabel}');
      buffer.writeln('时间：${record.formattedTimestamp}');
      buffer.writeln('内容：${record.content}');
      buffer
          .writeln('相关性：${(record.relevanceScore * 100).toStringAsFixed(1)}%');
      if (record.behaviorTag != null) {
        buffer.writeln('标签：${record.behaviorTag}');
      }
      buffer.writeln();
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已复制全部 ${widget.sources.length} 条记录'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      );
    }

    widget.onCopyAll?.call();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 头部：标题 + 操作按钮
          _buildHeader(isSmallScreen),

          // 展开时显示记录列表
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isExpanded ? _buildRecordsList() : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  /// 构建头部区域
  Widget _buildHeader(bool isSmallScreen) {
    return InkWell(
      onTap: _toggleExpanded,
      borderRadius: BorderRadius.vertical(
        top: const Radius.circular(12),
        bottom: _isExpanded ? Radius.zero : const Radius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // 展开/折叠图标
            RotationTransition(
              turns: _rotationAnimation,
              child: const Icon(
                Icons.keyboard_arrow_down,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(width: 6),

            // 标题
            Expanded(
              child: Text(
                '相关记忆记录 (${widget.sources.length})',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),

            // 复制全部按钮
            _buildCopyAllButton(isSmallScreen),
          ],
        ),
      ),
    );
  }

  /// 复制全部按钮
  Widget _buildCopyAllButton(bool isSmallScreen) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _copyAllRecords,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.copy,
                size: 14,
                color: AppColors.primary,
              ),
              if (!isSmallScreen) ...[
                const SizedBox(width: 4),
                const Text(
                  '复制全部',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 构建记录列表
  Widget _buildRecordsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 分隔线
        const Divider(
          height: 1,
          color: AppColors.divider,
          indent: 12,
          endIndent: 12,
        ),

        // 记录列表
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.sources.length,
          separatorBuilder: (context, index) => const Divider(
            height: 1,
            color: AppColors.divider,
            indent: 12,
            endIndent: 12,
          ),
          itemBuilder: (context, index) {
            return _SourceRecordItem(
              record: widget.sources[index],
              index: index,
              onCopy: _copySingleRecord,
            );
          },
        ),

        // 底部操作栏
        _buildFooter(),
      ],
    );
  }

  /// 构建底部操作栏
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF0EEEB),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 收起按钮
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.circular(6),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.keyboard_arrow_up,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '收起',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 复制全部按钮
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _copyAllRecords,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.copy_all,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '复制全部记录',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 单条检索记录项组件
class _SourceRecordItem extends StatefulWidget {
  const _SourceRecordItem({
    required this.record,
    required this.index,
    required this.onCopy,
  });
  final QaSourceRecord record;
  final int index;
  final Future<void> Function(QaSourceRecord) onCopy;

  @override
  State<_SourceRecordItem> createState() => _SourceRecordItemState();
}

class _SourceRecordItemState extends State<_SourceRecordItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return InkWell(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 第一行：序号 + 类型标签 + 相关性评分 + 复制按钮
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 序号
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${widget.index + 1}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // 类型标签 + 时间 + 内容
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // 类型标签
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getTypeColor(record.recordType)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              record.recordTypeLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _getTypeColor(record.recordType),
                              ),
                            ),
                          ),

                          const SizedBox(width: 6),

                          // 时间戳
                          Text(
                            record.formattedTimestamp,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),

                      // 内容摘要（始终显示）
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          record.content,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            height: 1.4,
                          ),
                          maxLines: _isExpanded ? null : 2,
                          overflow: _isExpanded ? null : TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // 右侧：相关性评分 + 复制按钮
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // 相关性评分
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: record.relevanceColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${(record.relevanceScore * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: record.relevanceColor,
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // 复制按钮
                    if (!isSmallScreen)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => widget.onCopy(record),
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.copy_outlined,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),

            // 展开状态：显示额外信息
            if (_isExpanded) ...[
              const SizedBox(height: 8),

              // 行为标签（如果有）
              if (record.behaviorTag != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.label_outline,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '行为标签：${record.behaviorTag}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

              // 元数据（如果有）
              if (record.metadata != null && record.metadata!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: record.metadata!.entries.map((entry) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F0ED),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${entry.key}: ${entry.value}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

              // 收起提示
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.keyboard_arrow_up,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '点击收起',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // 折叠状态：提示可展开
              if (record.content.length > 40)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 14,
                        color: Color(0xFFBDBDBD),
                      ),
                      SizedBox(width: 4),
                      Text(
                        '点击展开完整内容',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFFBDBDBD),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  /// 根据记录类型获取颜色
  Color _getTypeColor(String recordType) {
    switch (recordType) {
      case 'timeline':
        return AppColors.timelineType;
      case 'item':
        return AppColors.itemType;
      case 'knowledge':
        return AppColors.knowledgeType;
      case 'agenda':
        return AppColors.agendaType;
      default:
        return AppColors.textSecondary;
    }
  }
}
