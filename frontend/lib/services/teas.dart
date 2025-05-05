import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'user.dart'; 
//place holder for tea search functionality
Future<String> submitReview({
  required String teaId,
  required String reviewText,
  required String notes,
  required String ratingText,
}) async {
  final token = await getJwtToken();
  if (token == null) {
    return 'Error: not authenticated';
  }

  final rating = int.tryParse(ratingText);
  if (rating == null || rating < 1 || rating > 10) {
    return 'Invalid rating';
  }

  final reviewData = {
    'reviewText': reviewText,
    'notes': notes,
    'rating': rating,
    'tea': teaId,
  };

  try {
    final res = await http.post(
      Uri.parse('http://localhost:3000/api/reviews'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(reviewData),
    );

    if (res.statusCode == 201) {
      return 'Review submitted!';
    } else {
      return 'Submission failed: ${res.statusCode}';
    }
  } catch (e) {
    return 'Submission error: $e';
  }
}

Future<List<Map<String, dynamic>>> fetchReviews(String teaId) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');

  final res = await http.get(
    Uri.parse('http://localhost:3000/api/reviews?tea=$teaId'),
    headers: {if (token != null) 'Authorization': 'Bearer $token'},
  );

  if (res.statusCode == 200) {
    final List data = json.decode(res.body);

    // Print each key-value pair for debugging
    for (var review in data) {
      print('--- Review ---');
      review.forEach((key, value) => print('$key: $value'));
    }

    return data.cast<Map<String, dynamic>>();
  } else {
    throw Exception('Failed to load reviews');
  }
}
