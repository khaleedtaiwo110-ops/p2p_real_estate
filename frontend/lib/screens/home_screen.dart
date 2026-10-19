import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> properties = [];
  bool isLoading = true;

  // Change to http://10.0.2.2:8000/api/properties/ if using Android Emulator
  final String apiUrl = 'http://127.0.0.1:8000/api/properties/';

  @override
  void initState() {
    super.initState();
    fetchProperties();
  }

  Future<void> fetchProperties([String query = '']) async {
    setState(() => isLoading = true);
    try {
      final url = Uri.parse(query.isEmpty ? apiUrl : '$apiUrl?search=$query');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          properties = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Direct P2P Real Estate'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: (value) => fetchProperties(value),
              decoration: InputDecoration(
                hintText: 'Search city or state...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : properties.isEmpty
                    ? const Center(child: Text('No properties listed yet.'))
                    : ListView.builder(
                        itemCount: properties.length,
                        itemBuilder: (context, index) {
                          final item = properties[index];
                          final bool hasAgent = item['requires_platform_agent'] ?? false;
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              title: Text(item['title'] ?? 'Listing'),
                              subtitle: Text('${item['city']}, ${item['state']}'),
                              trailing: Chip(
                                label: Text(
                                  hasAgent ? 'Agent Assigned' : 'Direct Owner',
                                  style: const TextStyle(color: Colors.white, fontSize: 10),
                                ),
                                backgroundColor: hasAgent ? Colors.orange : Colors.green,
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}