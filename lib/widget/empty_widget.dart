import 'package:flutter/material.dart';

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '暂无数据',
        style: TextStyle(fontSize: 20.0),
      ),
    );
  }
}
