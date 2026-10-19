import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/theme/app_theme.dart';

class PostPropertyScreen extends StatefulWidget {
  const PostPropertyScreen({Key? key}) : super(key: key);

  @override
  State<PostPropertyScreen> createState() => _PostPropertyScreenState();
}

class _PostPropertyScreenState extends State<PostPropertyScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  String _propertyType = 'RENT';
  bool _requiresAgent = false;
  bool _isSubmitting = false;

  final String _apiUrl = 'http://127.0.0.1:8000/api/properties/';

  Future<void> _submitProperty() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'title': _titleController.text,
          'description': _descriptionController.text,
          'price': double.parse(_priceController.text),
          'property_type': _propertyType,
          'address': _addressController.text,
          'city': _cityController.text,
          'state': _stateController.text,
          'requires_platform_agent': _requiresAgent,
        }),
      );

      setState(() => _isSubmitting = false);

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Property posted successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        _formKey.currentState!.reset();
        setState(() {
          _requiresAgent = false;
          _propertyType = 'RENT';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post property: ${response.body}')),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error connecting to server: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('List New Property')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Property Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 16),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Listing Title (e.g., 3-Bedroom Flat)',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),

              // Property Type Dropdown
              DropdownButtonFormField<String>(
                value: _propertyType,
                decoration: const InputDecoration(
                  labelText: 'Property Category',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'RENT', child: Text('Rent')),
                  DropdownMenuItem(value: 'HOUSE', child: Text('House / Apartment')),
                  DropdownMenuItem(value: 'LAND', child: Text('Land')),
                ],
                onChanged: (val) => setState(() => _propertyType = val!),
              ),
              const SizedBox(height: 16),

              // Price & City Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Price (\$)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Enter price' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Enter city' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Address & State Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Street Address',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Enter address' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _stateController,
                      decoration: const InputDecoration(
                        labelText: 'State',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Enter state' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Property Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Agent Request Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                ),
                child: CheckboxListTile(
                  value: _requiresAgent,
                  title: const Text(
                    'Assign Platform Agent for Inspections',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Check this if you don\'t have time for physical viewings. We will assign 1 dedicated agent to handle client inquiries and inspections.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  onChanged: (val) => setState(() => _requiresAgent = val ?? false),
                  activeColor: AppColors.accent,
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitProperty,
                  child: Text(_isSubmitting ? 'Posting Listing...' : 'Publish Property'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}