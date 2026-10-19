import 'dart:convert';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../../services/storage_service.dart';


class PropertyUploadWizardScreen extends StatefulWidget {
  final String listingIntent; // 'rent' or 'own'
  final String subtype;       // 'self_contain', 'one_bedroom', etc.

  const PropertyUploadWizardScreen({
    Key? key,
    required this.listingIntent,
    required this.subtype,
  }) : super(key: key);

  @override
  State<PropertyUploadWizardScreen> createState() => _PropertyUploadWizardScreenState();
}

class _PropertyUploadWizardScreenState extends State<PropertyUploadWizardScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // Location State
  LatLng _selectedLocation = const LatLng(6.4549, 3.4246); // Default: Lekki / Lagos
  String _selectedAddressLabel = 'No location selected (Tap below to pin)';

  // Form Controllers
  late TextEditingController _titleController;
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController(text: 'Lekki Phase 1');
  final TextEditingController _cityController = TextEditingController(text: 'Lagos');
  final TextEditingController _stateController = TextEditingController(text: 'Lagos');

  String _selectedTenantPreference = 'ANY';
  bool _isSubmitting = false;

  // Media Storage
  final Map<String, XFile?> _mediaFiles = {};
  final Map<String, Uint8List> _mediaBytes = {};

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: _getDefaultTitle());
  }

  String _getDefaultTitle() {
    final String intentText = widget.listingIntent == 'rent' ? 'for Rent' : 'for Sale';
    switch (widget.subtype) {
      case 'self_contain':
        return 'Standard Self Contain Unit $intentText';
      case 'one_bedroom':
        return 'Modern 1 Bedroom & Parlour $intentText';
      case 'two_bedroom':
        return 'Spacious 2 Bedroom Flat $intentText';
      case 'three_bedroom':
        return 'Luxury 3 Bedroom Apartment $intentText';
      case 'three_bedroom_plus':
        return 'Premium 3 Bedroom+ Villa $intentText';
      default:
        return 'Property $intentText';
    }
  }

  List<Map<String, String>> _getPhotoSections() {
    switch (widget.subtype) {
      case 'self_contain':
        return [
          {'key': 'main', 'label': 'Front View', 'icon': 'front'},
          {'key': 'room', 'label': 'Room Size / View', 'icon': 'bed'},
          {'key': 'toilet', 'label': 'Toilet / Bathroom', 'icon': 'bath'},
          {'key': 'kitchen', 'label': 'Kitchen View', 'icon': 'kitchen'},
        ];
      case 'one_bedroom':
        return [
          {'key': 'main', 'label': 'Front View', 'icon': 'front'},
          {'key': 'parlor', 'label': 'Parlour Size', 'icon': 'parlor'},
          {'key': 'bedroom_1', 'label': 'Master Bedroom', 'icon': 'bed'},
          {'key': 'toilet', 'label': 'Toilet View', 'icon': 'bath'},
          {'key': 'kitchen', 'label': 'Kitchen View', 'icon': 'kitchen'},
        ];
      case 'two_bedroom':
        return [
          {'key': 'main', 'label': 'Front View', 'icon': 'front'},
          {'key': 'parlor', 'label': 'Living Room / Parlour', 'icon': 'parlor'},
          {'key': 'bedroom_1', 'label': 'Master Bedroom', 'icon': 'bed'},
          {'key': 'bedroom_2', 'label': '2nd Bedroom', 'icon': 'bed'},
          {'key': 'toilet', 'label': 'Toilet View', 'icon': 'bath'},
          {'key': 'kitchen', 'label': 'Kitchen Area', 'icon': 'kitchen'},
        ];
      case 'three_bedroom':
      case 'three_bedroom_plus':
        return [
          {'key': 'main', 'label': 'Front View', 'icon': 'front'},
          {'key': 'parlor', 'label': 'Living Room / Parlour', 'icon': 'parlor'},
          {'key': 'bedroom_1', 'label': 'Master Bedroom', 'icon': 'bed'},
          {'key': 'bedroom_2', 'label': '2nd Bedroom', 'icon': 'bed'},
          {'key': 'bedroom_3', 'label': '3rd Bedroom', 'icon': 'bed'},
          {'key': 'toilet', 'label': 'Bathroom / Toilet', 'icon': 'bath'},
          {'key': 'kitchen', 'label': 'Kitchen Area', 'icon': 'kitchen'},
        ];
      default:
        return [
          {'key': 'main', 'label': 'Front View', 'icon': 'front'},
          {'key': 'parlor', 'label': 'Living Room', 'icon': 'parlor'},
          {'key': 'bedroom_1', 'label': 'Bedroom', 'icon': 'bed'},
          {'key': 'kitchen', 'label': 'Kitchen', 'icon': 'kitchen'},
        ];
    }
  }

  IconData _getIconForType(String iconType) {
    switch (iconType) {
      case 'parlor':
        return Icons.weekend_outlined;
      case 'bed':
        return Icons.bed_outlined;
      case 'kitchen':
        return Icons.kitchen_outlined;
      case 'bath':
        return Icons.bathtub_outlined;
      case 'front':
      default:
        return Icons.add_a_photo_outlined;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String sectionKey) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _mediaFiles[sectionKey] = image;
        _mediaBytes[sectionKey] = bytes;
      });
    }
  }

  /// Opens full-screen search modal with auto-complete and interactive map
  Future<void> _openLocationPicker() async {
    final Map<String, dynamic>? result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LocationSearchModal(initialLocation: _selectedLocation),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result['location'] as LatLng;
        _selectedAddressLabel = result['address'] as String;
        
        // Auto-fill address field if user hasn't typed manually
        if (result['displayName'] != null) {
          _addressController.text = result['displayName'];
        }
      });
    }
  }

  Future<void> _publishListing() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final String baseUrl = kIsWeb
        ? 'http://127.0.0.1:8000/api'
        : (Platform.isAndroid ? 'http://10.0.2.2:8000/api' : 'http://127.0.0.1:8000/api');

    try {
      // 1. Retrieve the saved JWT token[cite: 1]
      final String? token = await StorageService.getToken();

      // 2. Create Multipart Request
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/properties/'));

      // ✅ Attach Authorization header if token exists[cite: 1]
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // 3. Add text fields
      request.fields['title'] = _titleController.text.trim();
      request.fields['description'] = _descriptionController.text.trim();
      request.fields['price'] = _priceController.text.trim();
      request.fields['intent'] = widget.listingIntent;
      request.fields['subtype'] = widget.subtype;
      request.fields['tenant_preference'] = _selectedTenantPreference;
      request.fields['address'] = _addressController.text.trim();
      request.fields['city'] = _cityController.text.trim();
      request.fields['state'] = _stateController.text.trim();
      request.fields['latitude'] = _selectedLocation.latitude.toString();
      request.fields['longitude'] = _selectedLocation.longitude.toString();
      request.fields['status'] = 'PENDING';

      // 4. Attach image files directly across Web and Mobile platforms
      for (var entry in _mediaFiles.entries) {
        final file = entry.value;
        if (file != null) {
          if (kIsWeb) {
            final bytes = await file.readAsBytes();
            request.files.add(http.MultipartFile.fromBytes(
              'uploaded_images',
              bytes,
              filename: file.name,
            ));
          } else {
            request.files.add(await http.MultipartFile.fromPath(
              'uploaded_images',
              file.path,
            ));
          }
        }
      }

      // 5. Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listing submitted successfully! Check your dashboard.'),
            backgroundColor: Colors.green,
          ),
        );
        if (Navigator.canPop(context)) {
          Navigator.pop(context, true);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit listing. Status: ${response.statusCode} - ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2563EB);
    final photoSections = _getPhotoSections();

    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Listing (${widget.listingIntent.toUpperCase()})'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Property Title *',
                      hintText: 'e.g., Luxury 2 Bedroom Apartment in Lekki',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Enter property title' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: widget.listingIntent == 'rent' ? 'Annual Rent (₦) *' : 'Sale Price (₦) *',
                      hintText: 'e.g., 2500000',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Enter price' : null,
                  ),
                  const SizedBox(height: 16),

                  if (widget.listingIntent == 'rent') ...[
                    DropdownButtonFormField<String>(
                      value: _selectedTenantPreference,
                      decoration: const InputDecoration(
                        labelText: 'Tenant Preference',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'ANY', child: Text('Any (No Preference)')),
                        DropdownMenuItem(value: 'SINGLE_MALE', child: Text('Single Male')),
                        DropdownMenuItem(value: 'SINGLE_FEMALE', child: Text('Single Female')),
                        DropdownMenuItem(value: 'FAMILY', child: Text('Family')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedTenantPreference = val);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Location Picker Tile Button
                  const Text(
                    'Property Location Pin',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _openLocationPicker,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: primaryColor, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tap to select on map or search street',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _selectedAddressLabel,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _cityController,
                          decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _stateController,
                          decoration: const InputDecoration(labelText: 'State', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Describe key features, water supply, power, security...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Property Photos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: kIsWeb ? 4 : 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: photoSections.length,
                    itemBuilder: (context, index) {
                      final item = photoSections[index];
                      return _buildImagePickerTile(
                        item['key']!,
                        item['label']!,
                        item['icon']!,
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _publishListing,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Publish Listing',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePickerTile(String key, String label, String iconType) {
    final bool hasBytes = _mediaBytes[key] != null;
    const primaryColor = Color(0xFF2563EB);

    return InkWell(
      onTap: () => _pickImage(key),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasBytes ? primaryColor : const Color(0xFFCBD5E1),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: hasBytes
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(_mediaBytes[key]!, fit: BoxFit.cover),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        color: Colors.black.withOpacity(0.65),
                        child: Text(
                          label,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getIconForType(iconType),
                      size: 32,
                      color: const Color(0xFF64748B),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        label,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tap to upload file',
                      style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Interactive Search & Pin Location Modal Widget
class _LocationSearchModal extends StatefulWidget {
  final LatLng initialLocation;

  const _LocationSearchModal({Key? key, required this.initialLocation}) : super(key: key);

  @override
  State<_LocationSearchModal> createState() => _LocationSearchModalState();
}

class _LocationSearchModalState extends State<_LocationSearchModal> {
  late MapController _mapController;
  late LatLng _currentPinnedLocation;
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  String _selectedDisplayName = '';

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentPinnedLocation = widget.initialLocation;
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);

    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5',
    );

    try {
      final response = await http.get(url, headers: {'User-Agent': 'com.example.app'});
      if (response.statusCode == 200) {
        final List results = jsonDecode(response.body);
        setState(() {
          _searchResults = results;
        });
      }
    } catch (_) {
      // Handle network errors gracefully
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _selectSearchResult(dynamic place) {
    final lat = double.parse(place['lat']);
    final lon = double.parse(place['lon']);
    final newLoc = LatLng(lat, lon);

    setState(() {
      _currentPinnedLocation = newLoc;
      _selectedDisplayName = place['display_name'] ?? '';
      _searchResults = [];
    });

    _mapController.move(newLoc, 16.0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle & Header
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Search & Pin Location',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              onChanged: _searchLocation,
              decoration: InputDecoration(
                hintText: 'Type street name, neighborhood, or city...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          // Search Auto-complete Suggestions Overlay
          if (_searchResults.isNotEmpty)
            Container(
              height: 200,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
                ],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final place = _searchResults[index];
                  return ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text(
                      place['display_name'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                    onTap: () => _selectSearchResult(place),
                  );
                },
              ),
            ),

          const SizedBox(height: 8),

          // Interactive Map View
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentPinnedLocation,
                    initialZoom: 14,
                    onTap: (_, point) {
                      setState(() {
                        _currentPinnedLocation = point;
                        _selectedDisplayName = '';
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
                      userAgentPackageName: 'com.example.app',
                      tileProvider: CancellableNetworkTileProvider(),
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _currentPinnedLocation,
                          width: 48,
                          height: 48,
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 44,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Confirm Selection Button Floating Overlay
                Positioned(
                  bottom: 24,
                  left: 16,
                  right: 16,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(context, {
                        'location': _currentPinnedLocation,
                        'address': _selectedDisplayName.isNotEmpty
                            ? _selectedDisplayName
                            : '${_currentPinnedLocation.latitude.toStringAsFixed(4)}, ${_currentPinnedLocation.longitude.toStringAsFixed(4)}',
                        'displayName': _selectedDisplayName.isNotEmpty ? _selectedDisplayName : null,
                      });
                    },
                    child: const Text(
                      'Confirm Location Pin',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}