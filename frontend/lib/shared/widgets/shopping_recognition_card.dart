import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/models/app_models.dart';

/// 智能识别结果卡片 - 购物记录专用
/// 展示意图识别后的结构化信息：购买地点、购买清单（物品+数量+单位）
class ShoppingRecognitionCard extends StatelessWidget {
  final ShoppingRecord shoppingRecord;
  final int? tagCount;

  const ShoppingRecognitionCard({
    super.key,
    required this.shoppingRecord,
    this.tagCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Row(
            children: [
              const Icon(AppIcons.brain, size: 18, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(
                '智能识别结果${tagCount != null ? '（${tagCount}个标签）' : ''}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 识别结果内容
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgPrimary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标签
                _buildTypeBadge(),
                const SizedBox(height: 14),
                // 购买地点
                _buildKeyValueRow('购买地点', shoppingRecord.store),
                const SizedBox(height: 12),
                // 购买清单
                const Text(
                  '购买清单',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                ...shoppingRecord.items.map((item) => _buildItemRow(item)),
                const SizedBox(height: 12),
                // 分割线
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 10),
                // 自动保存提示
                Row(
                  children: const [
                    Icon(AppIcons.checkCircle, size: 14, color: AppColors.success),
                    SizedBox(width: 6),
                    Text(
                      '已自动保存到购物记录',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(AppIcons.shoppingCart, size: 14, color: AppColors.warning),
          SizedBox(width: 4),
          Text(
            '购物记录',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.warning,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyValueRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildItemRow(ShoppingItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.name,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '${_formatQuantity(item.quantity)}${item.unit}',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatQuantity(int quantity) {
    return quantity.toString();
  }
}
