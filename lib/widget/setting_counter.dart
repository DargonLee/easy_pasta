import 'package:flutter/material.dart';

class ModernCounter extends StatefulWidget {
  final ValueChanged<int>? onChanged;
  final int minValue;
  final int maxValue;
  final int defaultValue;

  const ModernCounter({
    Key? key,
    this.onChanged,
    this.minValue = 10,
    this.maxValue = 2000,
    this.defaultValue = 500,
  }) : super(key: key);

  @override
  State<ModernCounter> createState() => _ModernCounterState();
}

class _ModernCounterState extends State<ModernCounter> {
  late int _count;
  bool _isLoading = true;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    _count = widget.defaultValue;
    _loadStoredValue();
  }

  Future<void> _loadStoredValue() async {
    if (!_mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _updateValue(int newValue) async {
    if (!_mounted) return;
    if (newValue < widget.minValue || newValue > widget.maxValue) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(newValue < widget.minValue
            ? '最小不能低于 ${widget.minValue}'
            : '最大不能超过 ${widget.maxValue}'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      return;
    }

    setState(() => _count = newValue);
    widget.onChanged?.call(newValue);
  }

  Widget _buildButton(bool isIncrement, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final isDisabled =
        isIncrement ? _count >= widget.maxValue : _count <= widget.minValue;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDisabled
            ? (isDark ? Colors.grey[800] : Colors.grey[200])
            : theme.colorScheme.primary.withOpacity(isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: isDisabled
            ? null
            : () => _updateValue(_count + (isIncrement ? 10 : -10)),
        icon: Icon(
          isIncrement ? Icons.add : Icons.remove,
          size: 20,
          color: isDisabled
              ? (isDark ? Colors.grey[600] : Colors.grey[400])
              : theme.colorScheme.primary,
        ),
        splashRadius: 20,
        tooltip: isIncrement ? '增加' : '减少',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 150,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildButton(false, theme),
          Container(
            width: 40,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              _count.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          _buildButton(true, theme),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }
}
