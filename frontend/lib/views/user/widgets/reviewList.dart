import 'package:flutter/material.dart';
import '../../../services/user.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';

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
    showDialog(
      context: context,
      builder: (_) => ViewReviewDialog(review: review, onRefresh: fetchReviews),
    );
  }

  void updateReviewInList(Map<String, dynamic> updatedReview) {
    setState(() {
      final index = reviews.indexWhere((r) => r['_id'] == updatedReview['_id']);
      if (index != -1) {
        reviews[index] = updatedReview;
      }
    });
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
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: ListView.builder(
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
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ViewReviewDialog extends StatefulWidget {
  final Map<String, dynamic> review;
  final VoidCallback onRefresh;

  const ViewReviewDialog({
    super.key,
    required this.review,
    required this.onRefresh,
  });

  @override
  State<ViewReviewDialog> createState() => _ViewReviewDialogState();
}

class _ViewReviewDialogState extends State<ViewReviewDialog> {
  late Map<String, dynamic> review;
  bool isEditing = false;
  String? errorMessage;
  late TextEditingController reviewTextController;
  late TextEditingController flavorNotesController;
  late TextEditingController ratingController;

  @override
  void initState() {
    super.initState();
    review = Map<String, dynamic>.from(widget.review);
    reviewTextController = TextEditingController(text: review['reviewText']);
    flavorNotesController = TextEditingController(text: review['flavorNotes']);
    ratingController = TextEditingController(
      text: review['rating']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    reviewTextController.dispose();
    flavorNotesController.dispose();
    ratingController.dispose();
    super.dispose();
  }

  void _saveChanges() async {
    final rating = int.tryParse(ratingController.text);
    if (rating == null || rating < 0 || rating > 10) {
      setState(() {
        errorMessage = 'Rating must be between 0 and 10';
      });
      return;
    }

    try {
      final updated = await updateReview(review['_id'], {
        'reviewText': reviewTextController.text,
        'flavorNotes': flavorNotesController.text,
        'rating': rating,
      });

      setState(() {
        review = updated;
        isEditing = false;
        errorMessage = null;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to update review. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review['teaName'] ?? 'Unnamed',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          review['teaVendor'] ?? 'Unknown Vendor',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(isEditing ? Icons.close : Icons.edit),
                    onPressed: () {
                      setState(() => isEditing = !isEditing);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Review Text
              isEditing
                  ? TextField(
                    controller: reviewTextController,
                    decoration: const InputDecoration(labelText: 'Review'),
                    maxLines: 4,
                  )
                  : Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      review['reviewText'] ?? 'No review provided.',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
              const SizedBox(height: 12),

              // Flavor Notes
              isEditing
                  ? TextField(
                    controller: flavorNotesController,
                    decoration: const InputDecoration(
                      labelText: 'Flavor Notes',
                    ),
                  )
                  : Text(
                    'Flavor Notes: ${review['flavorNotes'] ?? 'None'}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              const SizedBox(height: 12),

              // Rating
              isEditing
                  ? TextField(
                    controller: ratingController,
                    decoration: const InputDecoration(
                      labelText: 'Rating (0–10)',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                  )
                  : Text(
                    'Rating: ${review['rating'] ?? '?'} / 10',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              const SizedBox(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isEditing)
                    ElevatedButton(
                      onPressed: _saveChanges,
                      child: const Text('Save'),
                    ),
                  if (!isEditing)
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
