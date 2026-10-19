import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SafeNetworkImage extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;

  const SafeNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
  });

  @override
  State<SafeNetworkImage> createState() => _SafeNetworkImageState();
}

class _SafeNetworkImageState extends State<SafeNetworkImage> {
  Uint8List? _imageBytes;
  bool _hasError = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant SafeNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (widget.imageUrl.isEmpty) {
      if (mounted) setState(() { _hasError = true; _isLoading = false; });
      return;
    }

    // Standard Image.network works fine on non-web platforms
    if (!kIsWeb) {
      if (mounted) setState(() { _isLoading = false; });
      return;
    }

    // Web Platform Fix: Fetch bytes directly to bypass Chrome ImageDecoder API
    try {
      final response = await http.get(Uri.parse(widget.imageUrl));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _imageBytes = response.bodyBytes;
            _isLoading = false;
            _hasError = false;
          });
        }
      } else {
        if (mounted) setState(() { _hasError = true; _isLoading = false; });
      }
    } catch (e) {
      debugPrint('🚨 Failed byte fetch for ${widget.imageUrl}: $e');
      if (mounted) setState(() { _hasError = true; _isLoading = false; });
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFF1E293B),
      child: const Center(
        child: Icon(Icons.home_work_rounded, size: 36, color: Colors.white54),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: const Color(0xFF0F172A),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_hasError) {
      return _buildPlaceholder();
    }

    // On Web, render from raw bytes
    if (kIsWeb && _imageBytes != null) {
      return Image.memory(
        _imageBytes!,
        fit: widget.fit,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    }

    // On Android/iOS/Desktop, standard Image.network works
    return Image.network(
      widget.imageUrl,
      fit: widget.fit,
      errorBuilder: (_, __, ___) => _buildPlaceholder(),
    );
  }
}