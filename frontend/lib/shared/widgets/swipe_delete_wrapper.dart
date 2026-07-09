import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';

/// 通用左滑删除包装组件 - 标准 iOS 风格
/// 左滑显示删除按钮，点击删除；右滑或点击其他区域收起
class SwipeDeleteWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback onDelete;
  final String confirmText;

  const SwipeDeleteWrapper({
    super.key,
    required this.child,
    required this.onDelete,
    this.confirmText = '删除',
  });

  @override
  State<SwipeDeleteWrapper> createState() => _SwipeDeleteWrapperState();
}

class _SwipeDeleteWrapperState extends State<SwipeDeleteWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  double _dragExtent = 0;

  static const double _maxDrag = 80;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = Tween<double>(begin: 0, end: 0).animate(_controller)
      ..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _open() {
    _animation = Tween<double>(begin: _animation.value, end: -_maxDrag).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller
      ..reset()
      ..forward();
  }

  void _close() {
    _animation = Tween<double>(begin: _animation.value, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        _dragExtent += details.delta.dx;
        _dragExtent = _dragExtent.clamp(-_maxDrag, 0.0);
        setState(() {});
      },
      onHorizontalDragEnd: (_) {
        if (_dragExtent <= -_maxDrag * 0.5) {
          _open();
        } else {
          _close();
        }
        _dragExtent = 0;
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 删除背景按钮
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  widget.onDelete();
                  _close();
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  width: _maxDrag,
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(AppIcons.delete, color: Colors.white, size: 20),
                      const SizedBox(height: 2),
                      Text(
                        widget.confirmText,
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // 前景内容
          Transform.translate(
            offset: Offset(_dragExtent != 0 ? _dragExtent : _animation.value, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
