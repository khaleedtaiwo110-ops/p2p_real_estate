import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class Property {
  final int id;
  final int ownerId;
  final String title;
  final String description;
  final double price;
  final String propertyType; // LAND, HOUSE, RENT
  final String address;
  final String city;
  final String state;
  final bool requiresAgent;
  final List<String> imageUrls;
  final int beds;
  final int baths;
  final int sqft;
  final int unitsLeft;

  Property({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.price,
    required this.propertyType,
    required this.address,
    required this.city,
    required this.state,
    required this.requiresAgent,
    this.imageUrls = const [],
    this.beds = 3,
    this.baths = 2,
    this.sqft = 1800,
    this.unitsLeft = 1,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    // Safe helper to extract clean image path string
    String extractUrl(dynamic raw) {
      if (raw == null) return '';
      
      // Handle nested arrays: if raw is a List, pull the first valid element
      if (raw is List) {
        if (raw.isEmpty) return '';
        return extractUrl(raw.first);
      }
      
      // Handle nested Map objects like {id: 1, image: "/media/..."}
      if (raw is Map) {
        return raw['image']?.toString() ?? raw['url']?.toString() ?? raw['image_url']?.toString() ?? '';
      }
      
      return raw.toString().trim();
    }

    String resolveUrl(dynamic item) {
      final String path = extractUrl(item);
      
      // Ignore empty strings, brackets, or malformed values
      if (path.isEmpty || path == '[]' || path == '{}') return '';
      
      // Return direct absolute URLs or asset paths as-is
      if (path.startsWith('http://') || path.startsWith('https://') || path.startsWith('blob:') || path.startsWith('assets/')) {
        return path;
      }

      // Resolve relative Django media paths
      final String host = kIsWeb 
          ? 'http://127.0.0.1:8000' 
          : (Platform.isAndroid ? 'http://10.0.2.2:8000' : 'http://127.0.0.1:8000');

      return '$host$path';
    }

    // Extract raw image key from Django
    final dynamic rawImages = json['images'] ?? json['image_urls'] ?? json['photos'] ?? json['image'];
    List<String> parsedImages = [];

    if (rawImages is List && rawImages.isNotEmpty) {
      parsedImages = rawImages
          .map((img) => resolveUrl(img))
          .where((url) => url.isNotEmpty)
          .toList();
    } else if (rawImages != null) {
      final String single = resolveUrl(rawImages);
      if (single.isNotEmpty) parsedImages = [single];
    }


// Safely parse ownerId across all possible Django key variations
int parsedOwnerId = 0;

if (json['owner_id'] != null) {
  parsedOwnerId = int.tryParse(json['owner_id'].toString()) ?? 0;
} else if (json['landlord_id'] != null) {
  parsedOwnerId = int.tryParse(json['landlord_id'].toString()) ?? 0;
} else if (json['landlord'] != null && json['landlord'] is Map) {
  parsedOwnerId = int.tryParse(json['landlord']['id']?.toString() ?? '0') ?? 0;
} else if (json['landlord'] != null) {
  parsedOwnerId = int.tryParse(json['landlord'].toString()) ?? 0;
} else if (json['owner'] != null && json['owner'] is Map) {
  parsedOwnerId = int.tryParse(json['owner']['id']?.toString() ?? '0') ?? 0;
} else if (json['owner'] != null) {
  parsedOwnerId = int.tryParse(json['owner'].toString()) ?? 0;
} else if (json['created_by'] != null && json['created_by'] is Map) {
  parsedOwnerId = int.tryParse(json['created_by']['id']?.toString() ?? '0') ?? 0;
} else if (json['created_by'] != null) {
  parsedOwnerId = int.tryParse(json['created_by'].toString()) ?? 0;
}

    return Property(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      ownerId: parsedOwnerId,
      title: json['title'] ?? 'Untitled',
      description: json['description'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0.0') ?? 0.0,
      propertyType: json['property_type'] ?? 'HOUSE',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      requiresAgent: json['requires_platform_agent'] ?? json['requires_agent'] ?? false,
      
      // Use fallback assets ONLY if parsedImages is genuinely empty
      imageUrls: parsedImages.isNotEmpty ? parsedImages : ['assets/images/house1.jpg'],
      
      beds: int.tryParse(json['beds']?.toString() ?? '3') ?? 3,
      baths: int.tryParse(json['baths']?.toString() ?? '2') ?? 2,
      sqft: int.tryParse(json['sqft']?.toString() ?? '1800') ?? 1800,
      unitsLeft: json['units_left'] ?? 1,
    );
  }
}