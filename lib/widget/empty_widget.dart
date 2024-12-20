import 'package:flutter/material.dart';

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.paste, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            '暂无剪贴板内容',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
