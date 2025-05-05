import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import './details.dart'; 
import '../../services/teas.dart'; 
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController searchController = TextEditingController();
  String? selectedType;
  String? selectedVendor;

  final List<String> types = ['', 'White', 'Green', 'Oolong', 'Black', 'Puerh', 'Other'];
  final List<String> vendors = ['', 'Red Blossom Tea Company', 'Eco-Cha', 'What-Cha', 'Old Ways Tea', 'Yunnan Sourcing'];

  bool isLoading = false;
  bool hasMore = false;  //if there's more (for nextpage) teas given search results. manages if nextpage is available
  int currentPage = 0;
  final int pageSize = 20;
  List<dynamic> results = [];
  String? error;

  Future<void> searchTeas({int page = 0}) async {
    final query = searchController.text.trim();

    setState(() {
      error = null;
      isLoading = true;
    });

    try {
      final uri = Uri.parse('http://localhost:3000/api/search').replace(
        queryParameters: {
          if (query.isNotEmpty) 'query': query,
          if (selectedType != null && selectedType!.isNotEmpty) 'type': selectedType!,
          if (selectedVendor != null && selectedVendor!.isNotEmpty) 'vendor': selectedVendor!,
          'offset': (page * pageSize).toString(),
          'limit': pageSize.toString(),
        },
      );

      final res = await http.get(uri);

      if (res.statusCode == 200) {
        final decoded = json.decode(res.body);
        final List data = decoded['results'];
        final bool more = decoded['hasMore'];

        setState(() {
          results = data;
          hasMore = more;
          currentPage = page;
        });
      } else {
        setState(() => error = 'Server error: ${res.statusCode}');
      }
    } catch (e) {
      setState(() => error = 'Failed to connect');
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
              ElevatedButton(
                onPressed: () => searchTeas(page: 0),
                child: const Text('Search'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedType,
                  hint: const Text('Select Type'),
                  items: types.map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type.isEmpty ? 'All Types' : type),
                  )).toList(),
                  onChanged: (value) => setState(() => selectedType = value),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedVendor,
                  hint: const Text('Select Vendor'),
                  items: vendors.map((vendor) => DropdownMenuItem(
                    value: vendor,
                    child: Text(vendor.isEmpty ? 'All Vendors' : vendor),
                  )).toList(),
                  onChanged: (value) => setState(() => selectedVendor = value),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget searchResults() {
    if (isLoading && results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(child: Text(error!));
    }

    if (results.isEmpty) {
      return const Center(child: Text('No results'));
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final item = results[index];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                            Text(item['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(item['vendor'] ?? 'no vendor, please report this bug!!'),
                            if (item['type'] != null) Text('Type: ${item['type']}'),
                            if (item['rating'] != null) Text('rating: ${item['rating']}'), 
                            Text('Price: ${item['price']}')                      
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
                onPressed: currentPage > 0 && !isLoading ? () => searchTeas(page: currentPage - 1) : null,
                child: const Text('Previous'),
              ),
              const SizedBox(width: 16),
              Text('Page ${currentPage + 1}'),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: hasMore && !isLoading ? () => searchTeas(page: currentPage + 1) : null,
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        searchBar(),
        Expanded(child: searchResults()),
      ],
    );
  }
}

