import 'dart:typed_data';
import 'package:flutter/material.dart';

class ImageContent extends StatelessWidget {
  final Uint8List imageBytes;
  final double borderRadius;
  final BoxFit fit;

  const ImageContent({
    Key? key,
    required this.imageBytes,
    this.borderRadius = 8.0,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.memory(
        imageBytes,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: Colors.grey[400],
              size: 32,
            ),
          );
        },
      ),
    );
  }
}
