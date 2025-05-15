import 'package:flutter/material.dart';
import 'package:frontend/pages/widgets/addToCabinet.dart';
import '../../services/teas.dart';
import 'package:frontend/pages/widgets/linktext.dart';

//framework for the tea details and user reviews.
class TeaDetails extends StatefulWidget {
  final Map<String, dynamic> tea;
  const TeaDetails({super.key, required this.tea});

  @override
  State<TeaDetails> createState() => _TeaDetailsState();
}

class _TeaDetailsState extends State<TeaDetails> {
  late Future<List<Map<String, dynamic>>> reviews;
  @override
  @override
  void initState() {
    super.initState();
    reviews = fetchReviews(widget.tea['_id'].toString());
  }

  void refreshReviews() {
    setState(() {
      reviews = fetchReviews(widget.tea['_id'].toString());
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.tea['name'] ?? 'Tea Details')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          TeaInfo(tea: widget.tea),
          const SizedBox(height: 24),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'User Reviews',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder:
                        (context) => WriteReviewDialog(
                          teaId: widget.tea['_id'].toString(),
                        ),
                  ).then((_) {
                    refreshReviews(); // <-- This runs after dialog closes
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: reviews,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Failed to load reviews'));
              } else if (snapshot.data!.isEmpty) {
                return const Text('No reviews yet.');
              }

              return Column(
                children:
                    snapshot.data!
                        .where(
                          (review) =>
                              review['reviewText'] != null &&
                              review['reviewText'].toString().isNotEmpty,
                        )
                        .map((review) => Reviews(review: review))
                        .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

//Class to hold all the information for the tea.
class TeaInfo extends StatelessWidget {
  final Map<String, dynamic> tea;
  const TeaInfo({super.key, required this.tea});

  validateLink() {
    final link = tea['link'];
    return link != null && link != 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    final images = (tea['images'] as List?)?.cast<String>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tea['name'] ?? 'Unknown Tea',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  Text(
                    tea['vendor'] ?? 'Unknown Vendor',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  LinkText(url: tea['link']),
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AddToCabinet(teaId: tea['_id']),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add to Cabinet'),
                  ),

                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Price:',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      if (tea['vendor'] == 'What-Cha')
                        Text('Price: ${tea['price']} per 25g'),
                      if (tea['vendor'] != 'What-Cha')
                        Text('Price: ${tea['price']} per 2 Oz.'),
                      if (tea['type'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Type:',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Text(tea['type']),
                      ],
                      if (tea['rating'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Rating:',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Text('${(tea['rating'] as num).toStringAsFixed(2)}/10'),
                      ],
                      if (tea['origin'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Origin:',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Text(tea['origin']),
                      ],
                      if (tea['style'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Style:',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Text(tea['style']),
                      ],
                      if (tea['harvest'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Harvest:',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        Text(tea['harvest']),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 1,
              child:
                  images.isNotEmpty
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: 4 / 3,
                          child: Image.network(images.first, fit: BoxFit.cover),
                        ),
                      )
                      : Container(
                        height: 120,
                        width: 160,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(child: Text('No Image')),
                      ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (tea['description'] != null) ...[
          const Text(
            'Description',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(tea['description'], style: const TextStyle(fontSize: 14)),
        ],
      ],
    );
  }
}

class Reviews extends StatelessWidget {
  final Map<String, dynamic> review;
  const Reviews({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    final username = review['username'] ?? 'Anonymous';
    final content = review['reviewText'] ?? '';
    final notes = review['notes'] ?? '';
    final rating = review['rating'] ?? '';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(username, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text("rating: $rating"),
            const SizedBox(height: 4),
            Text(content, maxLines: 8),
            const SizedBox(height: 4),
            Text("Tasting Notes: $notes"),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed:
                    () => showDialog(
                      context: context,
                      builder:
                          (_) => AlertDialog(
                            title: Text(username),
                            content: Text(content),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                    ),
                child: const Text('Read full review'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WriteReviewDialog extends StatefulWidget {
  final String teaId;
  WriteReviewDialog({super.key, required this.teaId});

  @override
  State<WriteReviewDialog> createState() => _WriteReviewDialogState();
}

class _WriteReviewDialogState extends State<WriteReviewDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _reviewController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _ratingController = TextEditingController();

  void submitSuccess(String message) {
    Navigator.of(context).pop();
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Submission Result'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Write a Review'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _reviewController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Review'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Flavor Notes'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _ratingController,
                decoration: const InputDecoration(labelText: 'Rating (1–10)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final rating = int.tryParse(value ?? '');
                  if (rating == null || rating < 1 || rating > 10) {
                    return 'Enter a rating between 1 and 10';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState?.validate() ?? false) {
              final message = await submitReview(
                teaId: widget.teaId,
                reviewText: _reviewController.text.trim(),
                notes: _notesController.text.trim(),
                ratingText: _ratingController.text.trim(),
              );
              submitSuccess(message);
            }
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
