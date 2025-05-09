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


Future<Map<String, dynamic>> searchTeas({
  required String searchInput,
  required int page,
  required int pageSize,
}) async {
  final query = buildQuery(searchInput);
  query['offset'] = page * pageSize;
  query['limit'] = pageSize;

  final uri = Uri.parse('$baseURI/api/search');

  final res = await http.post(
    uri,
    headers: { 'Content-Type': 'application/json' },
    body: jsonEncode(query),
  );

  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception('Search failed with status: ${res.statusCode}');
  }
}

//build a structured query based off the query text 
//built with ChatGPT's help for parsing the query text. 
Map<String, dynamic> buildQuery(String input) {
  final filters = <String, List<String>>{};
  final searchTerms = <String>[];

  for (final part in input.split(',')) { //split query by commas
    final trimmed = part.trim(); //trim
    final colonIndex = trimmed.indexOf(':');  //split each sub query by : to split the field and the searchtext 

    
    if (colonIndex != -1) { //re-assemble the query to group values in the same fields in json form
      final key = trimmed.substring(0, colonIndex).trim().toLowerCase();
      final value = trimmed.substring(colonIndex + 1).trim();
      filters.putIfAbsent(key, () => []).add(value); //if new key, create it, then ad the new value to it.
    } else {
      searchTerms.add(trimmed);
    }
  }

  return {
    "search": searchTerms.join(' '),
    "filters": filters,
  };
}