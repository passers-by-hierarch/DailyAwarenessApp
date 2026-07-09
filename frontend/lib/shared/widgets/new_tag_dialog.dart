import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';

class NewTagDialog extends StatefulWidget {
  final String? initialName;
  final String? initialColor;
  final String? initialIcon;
  final bool isEdit;

  const NewTagDialog({
    super.key,
    this.initialName,
    this.initialColor,
    this.initialIcon,
    this.isEdit = false,
  });

  @override
  State<NewTagDialog> createState() => _NewTagDialogState();
}

class _NewTagDialogState extends State<NewTagDialog> {
  final TextEditingController _nameController = TextEditingController();
  late String _selectedColor;
  late String _selectedIcon;

  static const List<String> _availableColors = [
    'accent',
    'info',
    'warning',
    'success',
    'danger',
    'purple',
    'gray',
  ];

  static const List<Map<String, dynamic>> _availableIcons = [
    {'name': 'hash', 'icon': LucideIcons.hash},
    {'name': 'tag', 'icon': LucideIcons.tag},
    {'name': 'activity', 'icon': LucideIcons.activity},
    {'name': 'package', 'icon': LucideIcons.package},
    {'name': 'shopping_cart', 'icon': LucideIcons.shopping_cart},
    {'name': 'map_pin', 'icon': LucideIcons.map_pin},
    {'name': 'heart', 'icon': LucideIcons.heart},
    {'name': 'star', 'icon': LucideIcons.star},
    {'name': 'clock', 'icon': LucideIcons.clock},
    {'name': 'book', 'icon': LucideIcons.book_open},
    {'name': 'music', 'icon': LucideIcons.music},
    {'name': 'camera', 'icon': LucideIcons.camera},
    {'name': 'lightbulb', 'icon': LucideIcons.lightbulb},
    {'name': 'target', 'icon': LucideIcons.target},
    {'name': 'award', 'icon': LucideIcons.award},
    {'name': 'user', 'icon': LucideIcons.user},
    {'name': 'home', 'icon': LucideIcons.house},
    {'name': 'settings', 'icon': LucideIcons.settings},
    {'name': 'smile', 'icon': LucideIcons.smile},
    {'name': 'coffee', 'icon': LucideIcons.coffee},
    {'name': 'utensils', 'icon': LucideIcons.utensils},
    {'name': 'dumbbell', 'icon': LucideIcons.dumbbell},
    {'name': 'pill', 'icon': LucideIcons.pill},
    {'name': 'droplet', 'icon': LucideIcons.droplet},
  ];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialName ?? '';
    _selectedColor = widget.initialColor ?? 'accent';
    _selectedIcon = widget.initialIcon ?? 'hash';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入标签名称'), duration: Duration(seconds: 1)),
      );
      return;
    }
    Navigator.of(context).pop({
      'name': name,
      'color': _selectedColor,
      'icon': _selectedIcon,
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorSet = AppColors.tagColors[_selectedColor] ?? AppColors.tagColors['gray']!;

    return Dialog(
      backgroundColor: AppColors.bgSecondary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
              child: Row(
                children: [
                  Icon(AppIcons.tag, size: 20, color: colorSet.color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.isEdit ? '编辑标签' : '新建标签',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.bgTertiary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(AppIcons.x, size: 18, color: AppColors.textTertiary),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      '标签名称',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: '请输入标签名称',
                        hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
                        filled: true,
                        fillColor: AppColors.bgTertiary,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '标签颜色',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _availableColors.map((colorKey) {
                        final cs = AppColors.tagColors[colorKey]!;
                        final isSelected = _selectedColor == colorKey;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = colorKey),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: cs.color,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: AppColors.textPrimary, width: 2.5)
                                  : Border.all(color: Colors.transparent, width: 2.5),
                              boxShadow: isSelected
                                  ? [BoxShadow(color: cs.color.withOpacity(0.4), blurRadius: 6, spreadRadius: 1)]
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 18)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '标签图标',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _availableIcons.map((iconData) {
                        final iconName = iconData['name'] as String;
                        final icon = iconData['icon'] as IconData;
                        final isSelected = _selectedIcon == iconName;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedIcon = iconName),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isSelected ? colorSet.color.withOpacity(0.15) : AppColors.bgTertiary,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? colorSet.color : AppColors.border,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                icon,
                                size: 20,
                                color: isSelected ? colorSet.color : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('取消', style: TextStyle(color: AppColors.textTertiary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: colorSet.color,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        widget.isEdit ? '保存' : '创建',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
