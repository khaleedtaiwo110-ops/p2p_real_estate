import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

Future<bool> submitPropertyReview({
  required BuildContext context,
  required String baseUrl,
  required int propertyId,
  required String token,
  required int rating,
  required String comment,
}) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/properties/$propertyId/reviews/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'rating': rating,
        'comment': comment,
      }),
    );

    if (response.statusCode == 201) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review posted successfully!')),
      );
      return true;
    } else {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit review: ${response.statusCode}')),
      );
      return false;
    }
  } catch (e) {
    debugPrint('Review submission error: $e');
    return false;
  }
}