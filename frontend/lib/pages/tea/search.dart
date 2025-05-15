import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'details.dart';
import '../../services/teas.dart';
import 'package:frontend/config/api.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController searchController = TextEditingController();
  String? selectedType;
  String? selectedVendor;
  Set<String> selectedSearchFields = {'name'};
  Set<String> selectedTypes = {};
  Set<String> selectedVendors = {};
  double? minRating, maxRating, minPrice, maxPrice;

  bool isLoading = false;
  bool hasMore =
      false; //if there's more (for nextpage) teas given search results. manages if nextpage is available
  int currentPage = 0;
  final int pageSize = 20;
  List<dynamic> results = [];
  String? error;
  //search for teas, update interface.  used for pagination as well
  Future<void> searchAndUpdate({int page = 0}) async {
    setState(() {
      error = null;
      isLoading = true;
    });

    try {
      final result = await searchTeas(
        searchInput: searchController.text.trim(),
        searchFields: selectedSearchFields,
        types: selectedTypes,
        vendors: selectedVendors,
        minRating: minRating,
        maxRating: maxRating,
        minPrice: minPrice,
        maxPrice: maxPrice,
        page: page,
        pageSize: pageSize,
      );

      setState(() {
        results = List.from(result['results'] ?? []);
        hasMore = result['hasMore'] ?? false;
        currentPage = page;
      });
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget searchBar() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.filter_list),
                tooltip: 'Set filters',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder:
                        (_) => FilterDialog(
                          selectedSearchFields: selectedSearchFields,
                          selectedTypes: selectedTypes,
                          selectedVendors: selectedVendors,
                          minRating: minRating,
                          maxRating: maxRating,
                          minPrice: minPrice,
                          maxPrice: maxPrice,
                          onApply: ({
                            required searchFields,
                            required types,
                            required vendors,
                            required minRating,
                            required maxRating,
                            required minPrice,
                            required maxPrice,
                          }) {
                            setState(() {
                              selectedSearchFields = searchFields;
                              selectedTypes = types;
                              selectedVendors = vendors;
                              this.minRating = minRating;
                              this.maxRating = maxRating;
                              this.minPrice = minPrice;
                              this.maxPrice = maxPrice;
                            });
                          },
                        ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.clear),
                tooltip: 'Clear filters',
                onPressed: () {
                  setState(() {
                    selectedSearchFields = {'name'};
                    selectedTypes = {};
                    selectedVendors = {};
                    minRating = null;
                    maxRating = null;
                    minPrice = null;
                    maxPrice = null;
                  });
                },
              ),
              ElevatedButton(
                onPressed: () => searchAndUpdate(page: 0),
                child: const Text('Search'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget searchResultsList() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final item = results[index];
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(item['vendor'] ?? 'no vendor'),
                            if (item['type'] != null)
                              Text('Type: ${item['type']}'),
                            if (item['rating'] != null)
                              Text(
                                'Rating: ${(item['rating'] as num).toStringAsFixed(2)}',
                              ),
                            if (item['vendor'] == 'What-Cha')
                              Text('Price: ${item['price']} per 25g'),
                            if (item['vendor'] != 'What-Cha')
                              Text('Price: ${item['price']} per 2 Oz.'),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TeaDetails(tea: item),
                            ),
                          );
                        },
                        child: const Text('Details'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed:
                    currentPage > 0 && !isLoading
                        ? () => searchAndUpdate(page: currentPage - 1)
                        : null,
                child: const Text('Previous'),
              ),
              const SizedBox(width: 16),
              Text('Page ${currentPage + 1}'),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed:
                    hasMore && !isLoading
                        ? () => searchAndUpdate(page: currentPage + 1)
                        : null,
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget searchResults() {
    if (isLoading) {
      return Stack(
        children: [
          if (results.isNotEmpty)
            searchResultsList()
          else
            const Center(child: Text('Loading...')),

          const Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      );
    }

    if (error != null) {
      return Center(child: Text(error!));
    }

    if (results.isEmpty) {
      return const Center(child: Text('No results'));
    }

    return searchResultsList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [searchBar(), Expanded(child: searchResults())]);
  }
}

//filter dialogue working finally!
//probably should have just kept it inside of the main class :/
class FilterDialog extends StatefulWidget {
  final Set<String> selectedSearchFields;
  final Set<String> selectedTypes;
  final Set<String> selectedVendors;
  final double? minRating;
  final double? maxRating;
  final double? minPrice;
  final double? maxPrice;
  final void Function({
    required Set<String> searchFields,
    required Set<String> types,
    required Set<String> vendors,
    required double? minRating,
    required double? maxRating,
    required double? minPrice,
    required double? maxPrice,
  })
  onApply;

  const FilterDialog({
    super.key,
    required this.selectedSearchFields,
    required this.selectedTypes,
    required this.selectedVendors,
    required this.minRating,
    required this.maxRating,
    required this.minPrice,
    required this.maxPrice,
    required this.onApply,
  });

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late Set<String> tempSearchFields;
  late Set<String> tempTypes;
  late Set<String> tempVendors;
  late TextEditingController ratingMinController;
  late TextEditingController ratingMaxController;
  late TextEditingController priceMinController;
  late TextEditingController priceMaxController;

  @override
  void initState() {
    super.initState();
    tempSearchFields = Set<String>.from(widget.selectedSearchFields);
    tempTypes = Set<String>.from(widget.selectedTypes);
    tempVendors = Set<String>.from(widget.selectedVendors);
    ratingMinController = TextEditingController(
      text: widget.minRating?.toString() ?? '',
    );
    ratingMaxController = TextEditingController(
      text: widget.maxRating?.toString() ?? '',
    );
    priceMinController = TextEditingController(
      text: widget.minPrice?.toString() ?? '',
    );
    priceMaxController = TextEditingController(
      text: widget.maxPrice?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    ratingMinController.dispose();
    ratingMaxController.dispose();
    priceMinController.dispose();
    priceMaxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filters'),
      scrollable: true,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Search Fields'),
          ...[
            'name',
            'vendor',
            'type',
            'style',
            'description',
            'flavor_notes',
            'harvest',
            'origin',
          ].map(
            (field) => CheckboxListTile(
              title: Text(field),
              value: tempSearchFields.contains(field),
              onChanged: (checked) {
                setState(() {
                  checked == true
                      ? tempSearchFields.add(field)
                      : tempSearchFields.remove(field);
                });
              },
            ),
          ),

          const Divider(),
          const Text('Tea Types'),
          ...['White', 'Green', 'Oolong', 'Black', 'Pu-erh'].map(
            (type) => CheckboxListTile(
              title: Text(type),
              value: tempTypes.contains(type),
              onChanged: (checked) {
                setState(() {
                  checked == true
                      ? tempTypes.add(type)
                      : tempTypes.remove(type);
                });
              },
            ),
          ),

          const Divider(),
          const Text('Vendors'),
          ...['Eco-Cha', 'Red Blossom Tea Company', 'What-Cha'].map(
            (vendor) => CheckboxListTile(
              title: Text(vendor),
              value: tempVendors.contains(vendor),
              onChanged: (checked) {
                setState(() {
                  checked == true
                      ? tempVendors.add(vendor)
                      : tempVendors.remove(vendor);
                });
              },
            ),
          ),

          const Divider(),
          const Text('Rating Range (0–10)'),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: ratingMinController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Min'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: ratingMaxController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Max'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Text('Price Range (\$ per 2 Oz.)'),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: priceMinController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Min'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: priceMaxController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Max'),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onApply(
              searchFields: tempSearchFields,
              types: tempTypes,
              vendors: tempVendors,
              minRating: double.tryParse(ratingMinController.text),
              maxRating: double.tryParse(ratingMaxController.text),
              minPrice: double.tryParse(priceMinController.text),
              maxPrice: double.tryParse(priceMaxController.text),
            );
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
