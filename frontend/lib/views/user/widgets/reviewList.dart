import 'package:flutter/material.dart';
import '../../../services/user.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReviewList extends StatefulWidget {
  const ReviewList({super.key});
  @override
  State<ReviewList> createState() => _ReviewListState();
}

class _ReviewListState extends State<ReviewList> {
  List<dynamic> reviews = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchReviews();
  }

  Future<void> fetchReviews() async {
    final token = await getJwtToken();
    final response = await http.get(
      Uri.parse('http://localhost:3000/api/user/reviews'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      setState(() {
        reviews = json.decode(response.body);
        isLoading = false;
      });
    }
  }

 void _showReviewDialog(Map<String, dynamic> review) {
  final reviewId = review['_id'];

  void _openEditDialog() {
    final reviewTextController = TextEditingController(text: review['reviewText']);
    final ratingController = TextEditingController(text: review['rating']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Review'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: reviewTextController,
                decoration: const InputDecoration(labelText: 'Review'),
                maxLines: 5,
              ),
              TextField(
                controller: ratingController,
                decoration: const InputDecoration(labelText: 'Rating'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await updateReview(reviewId, {
                  'reviewText': reviewTextController.text,
                  'rating': int.tryParse(ratingController.text),
                });
                Navigator.pop(context); // close edit dialog
                Navigator.pop(context); // close view dialog
                fetchReviews(); // refresh data
              } catch (err) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to update review')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            review['teaName'] ?? 'Unnamed',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            review['teaVendor'] ?? 'Unknown Vendor',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: _openEditDialog,
                        ),
                        if (review['rating'] != null)
                          Text(
                            '${review['rating']}/10',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    review['reviewText'] ?? 'No review provided.',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Your Reviews",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (isLoading)
              const CircularProgressIndicator()
            else
             SizedBox( height: MediaQuery.of(context).size.height * 0.5,child: ListView.builder(

                itemCount: reviews.length,
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(review['teaName'] ?? 'Unnamed'),
                      subtitle: Text(review['teaVendor'] ?? 'Unknown'),
                      trailing:
                          review['rating'] != null
                              ? Text(
                                '${review['rating']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                              : null,
                      onTap: () => _showReviewDialog(review),
                    ),
                  );
                },
              ),),
              
          ],
        ),
      ),
    );
  }
}
