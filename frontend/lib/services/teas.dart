import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'user.dart';
import 'package:frontend/config/api.dart';

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
      Uri.parse('$baseURI/api/reviews'),
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
    Uri.parse('$baseURI/api/reviews?tea=$teaId'),
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

//more efficient version yay!
//as opposed to parsing our seach string and collecting it into a json/map we do it properly with filters:
Future<Map<String, dynamic>> searchTeas({
  required String searchInput,
  required Set<String> searchFields,
  required Set<String> types,
  required Set<String> vendors,
  required double? minRating,
  required double? maxRating,
  required double? minPrice,
  required double? maxPrice,
  required int page,
  required int pageSize,
}) async {
  final query = {
    "search": searchInput,
    "search_fields": searchFields.toList(),
    "filters": {
      if (types.isNotEmpty) "type": types.toList(),
      if (vendors.isNotEmpty) "vendor": vendors.toList(),
      if (minRating != null) "minRating": minRating,
      if (maxRating != null) "maxRating": maxRating,
      if (minPrice != null) "minPrice": minPrice,
      if (maxPrice != null) "maxPrice": maxPrice,
    },
    "offset": page * pageSize,
    "limit": pageSize,
  };

  final uri = Uri.parse('$baseURI/api/search');

  final res = await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(query),
  );

  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception('Search failed with status: ${res.statusCode}');
  }
}


Future<Map<String, dynamic>> getTea(String teaID) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');

  final uri = Uri.parse('$baseURI/api/teas/$teaID');

  final res = await http.get(
    uri,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );
  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception('Search failed with status: ${res.statusCode}');
  }
}
