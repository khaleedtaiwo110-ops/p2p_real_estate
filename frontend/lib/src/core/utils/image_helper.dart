import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

Widget buildNetworkOrFileImage(String? imagePath, {BoxFit fit = BoxFit.cover, double? width, double? height}) {
  if (imagePath == null || imagePath.isEmpty || imagePath == '[]') {
    return _buildPlaceholder(width: width, height: height);
  }

  String resolvedPath = imagePath.trim();

  // Handle relative Django paths starting with /media/ or media/
  if (resolvedPath.startsWith('/media/') || resolvedPath.startsWith('media/') || resolvedPath.startsWith('/static/')) {
    if (!resolvedPath.startsWith('/')) {
      resolvedPath = '/$resolvedPath';
    }
    final String baseUrl = kIsWeb 
      ? 'http://127.0.0.1:8000' 
      : (Platform.isAndroid ? 'http://10.0.2.2:8000' : 'http://127.0.0.1:8000');
    resolvedPath = '$baseUrl$resolvedPath';
  }

  // Render network / web blob URLs
  if (resolvedPath.startsWith('http://') || resolvedPath.startsWith('https://') || resolvedPath.startsWith('blob:')) {
    return Image.network(
      resolvedPath,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('🚨 Image Load Error for URL: $resolvedPath');
        return _buildPlaceholder(width: width, height: height);
      },
    );
  } 
  
  // Render local assets
  else if (resolvedPath.startsWith('assets/')) {
    return Image.asset(
      resolvedPath,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(width: width, height: height),
    );
  } 
  
  // Render local files (Mobile only)
  else if (!kIsWeb) {
    return Image.file(
      File(resolvedPath),
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(width: width, height: height),
    );
  }

  return _buildPlaceholder(width: width, height: height);
}

Widget _buildPlaceholder({double? width, double? height}) {
  return Container(
    width: width,
    height: height,
    color: const Color(0xFF1E293B),
    child: const Center(
      child: Icon(Icons.image_not_supported_rounded, size: 32, color: Color(0x80FFFFFF)),
    ),
  );
}