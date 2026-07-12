import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class LongPressDeleteWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback onDelete;
  final String confirmText;

  const LongPressDeleteWrapper({
    super.key,
    required this.child,
    required this.onDelete,
    this.confirmText = '删除',
  });

  @override
  State<LongPressDeleteWrapper> createState() => _LongPressDeleteWrapperState();
}

class _LongPressDeleteWrapperState extends State<LongPressDeleteWrapper> {
  bool _showDeleteDialog = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        setState(() {
          _showDeleteDialog = true;
        });
      },
      child: Stack(
        children: [
          widget.child,
          if (_showDeleteDialog)
            _buildDeleteOverlay(),
        ],
      ),
    );
  }

  Widget _buildDeleteOverlay() {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showDeleteDialog = false;
                  });
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 18, color: Colors.white),
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () {
                  widget.onDelete();
                  setState(() {
                    _showDeleteDialog = false;
                  });
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete, size: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}