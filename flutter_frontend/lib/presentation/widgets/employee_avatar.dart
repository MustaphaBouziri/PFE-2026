import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class EmployeeAvatar extends StatelessWidget {
  final String? imageBase64;
  final double radius;

  const EmployeeAvatar({
    super.key,
    required this.imageBase64,
    this.radius = 20,
  });

  static final Map<String, Uint8List> _cache = {};

  Uint8List? _getImage() {
    if (imageBase64 == null || imageBase64!.isEmpty) return null;

    if (_cache.containsKey(imageBase64)) {
      return _cache[imageBase64];
    }

    try {
      final decoded = base64Decode(imageBase64!);
      _cache[imageBase64!] = decoded;
      return decoded;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageData = _getImage();

    return RepaintBoundary(
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade200,
        backgroundImage:
            imageData != null ? MemoryImage(imageData) : null,
        child: imageData == null
            ? Icon(Icons.person, size: radius, color: Colors.grey.shade400)
            : null,
      ),
    );
  }
}