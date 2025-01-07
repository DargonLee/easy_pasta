import 'package:flutter/material.dart';
import 'dart:async';
import 'package:easy_pasta/db/shared_preference_helper.dart';

class ModernCounter extends StatefulWidget {
  final ValueChanged<int>? onChanged;
  final int minValue;
  final int maxValue;
  final int defaultValue;
  final Color? accentColor;

  const ModernCounter({
    Key? key,
    this.onChanged,
    this.minValue = 10,
    this.maxValue = 500,
    this.defaultValue = 50,
    this.accentColor,
  }) : super(key: key);

  @override
  State<ModernCounter> createState() => _ModernCounterState();
}

class _ModernCounterState extends State<ModernCounter> with SingleTickerProviderStateMixin {
  late int _count;
  bool _isLoading = true;
  Timer? _longPressTimer;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _count = widget.defaultValue;
    _setupAnimation();
    _loadStoredValue();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadStoredValue() async {
    try {
      final prefs = await SharedPreferenceHelper.instance;
      final storedValue = prefs.getMaxItemStore();
      if (mounted) {
        setState(() {
          _count = storedValue;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load stored value: $e');
      if (mounted) {
        setState(() {
          _count = widget.defaultValue;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateValue(int newValue) async {
    if (newValue < widget.minValue || newValue > widget.maxValue) {
      _showMessage(newValue < widget.minValue 
        ? '最小不能低于 ${widget.minValue}' 
        : '最大不能超过 ${widget.maxValue}'
      );
      return;
    }

    setState(() => _count = newValue);
    widget.onChanged?.call(newValue);

    try {
      final prefs = await SharedPreferenceHelper.instance;
      await prefs.setMaxItemStore(newValue);
    } catch (e) {
      _showMessage('保存失败，请重试');
    }
  }

  void _startLongPress(bool isIncrement) {
    _longPressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      final newValue = isIncrement ? _count + 1 : _count - 1;
      if (newValue >= widget.minValue && newValue <= widget.maxValue) {
        _updateValue(newValue);
      } else {
        _longPressTimer?.cancel();
      }
    });
  }

  void _stopLongPress() {
    _longPressTimer?.cancel();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(8),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: '确定',
          onPressed: () {},
        ),
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isIncrement,
  }) {
    final color = widget.accentColor ?? Theme.of(context).primaryColor;
    final isDisabled = isIncrement 
        ? _count >= widget.maxValue 
        : _count <= widget.minValue;

    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      onLongPress: isDisabled ? null : () => _startLongPress(isIncrement),
      onLongPressEnd: (_) => _stopLongPress(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDisabled ? Colors.grey.withOpacity(0.1) : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: isDisabled ? null : onPressed,
            icon: Icon(
              icon,
              size: 20,
              color: isDisabled ? Colors.grey : color,
            ),
            splashRadius: 20,
            tooltip: isIncrement ? '增加' : '减少',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 150,
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildButton(
            icon: Icons.remove,
            onPressed: () => _updateValue(_count - 1),
            isIncrement: false,
          ),
          Container(
            width: 60,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _count.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: widget.accentColor ?? Theme.of(context).primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          _buildButton(
            icon: Icons.add,
            onPressed: () => _updateValue(_count + 1),
            isIncrement: true,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }
}