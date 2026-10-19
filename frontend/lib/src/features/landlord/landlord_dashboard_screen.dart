import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../explore/widgets/navbar.dart';
import 'select_property_type_screen.dart';
import '../../services/storage_service.dart';
import 'landlord_conversations_screen.dart';

// Assuming LandlordConversationsScreen is defined elsewhere or imported:
// import 'landlord_conversations_screen.dart';

class LandlordDashboardScreen extends StatefulWidget {
  final Map<String, dynamic>? newProperty;

  const LandlordDashboardScreen({Key? key, this.newProperty}) : super(key: key);

  @override
  State<LandlordDashboardScreen> createState() => _LandlordDashboardScreenState();
}

class _LandlordDashboardScreenState extends State<LandlordDashboardScreen> {
  bool _isLoading = false;

  // Dynamic list of property listings
  final List<Map<String, dynamic>> _myListings = [];

  @override
  void initState() {
    super.initState();
    _fetchLandlordListings();
  }

  // Base URL resolver based on platform environment
  String get _baseUrl {
    if (kIsWeb) return 'https://p2p-real-estate-backend.onrender.com/api';
    return Platform.isAndroid ? 'https://p2p-real-estate-backend.onrender.com/api' : 'https://p2p-real-estate-backend.onrender.com/api';
  }

  // Fetch properties from backend API with JWT Authorization header
  Future<void> _fetchLandlordListings() async {
    setState(() => _isLoading = true);

    final String baseUrl = kIsWeb 
        ? 'https://p2p-real-estate-backend.onrender.com/api' 
        : (Platform.isAndroid ? 'https://p2p-real-estate-backend.onrender.com/api' : 'https://p2p-real-estate-backend.onrender.com/api');

    // 1. Get the logged-in user's token
    final String? token = await StorageService.getToken();

    try {
      // 2. Fetch from the user-specific endpoint
      final response = await http.get(
        Uri.parse('$baseUrl/properties/my-properties/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token', // 👈 REQUIRED
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _myListings.clear();
          _myListings.addAll(data.cast<Map<String, dynamic>>());
        });
      } else {
        debugPrint('API Error Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('🚨 Fetch Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Interactive Unit Counter Control
  Widget _buildUnitCounter(Map<String, dynamic> property) {
    int currentUnits = property['units_left'] ?? 1;

    Future<void> updateUnits(int newCount) async {
      const storage = FlutterSecureStorage();
      final String? token = await storage.read(key: 'access_token');

      try {
        final response = await http.patch(
          Uri.parse('$_baseUrl/properties/${property['id']}/update-units/'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'units_left': newCount}),
        );

        if (response.statusCode == 200) {
          setState(() {
            property['units_left'] = newCount;
          });
        } else {
          debugPrint('Failed to update units: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('Error updating units: $e');
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Units Left: $currentUnits',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        Row(
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.remove_circle_outline, size: 20),
              onPressed: currentUnits > 0 ? () => updateUnits(currentUnits - 1) : null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text('$currentUnits', style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.add_circle_outline, size: 20),
              onPressed: () => updateUnits(currentUnits + 1),
            ),
          ],
        ),
      ],
    );
  }

  // Calculated Stats
  int get _totalInquiries => _myListings.fold(0, (sum, item) => sum + ((item['inquiries'] ?? 0) as int));
  int get _totalViews => _myListings.fold(0, (sum, item) => sum + ((item['views'] ?? 0) as int));

  // Handles launching the listing creation flow
  void _startPropertyListingFlow() async {
    final selectionResult = await Navigator.push<Map<String, String?>>(
      context,
      MaterialPageRoute(
        builder: (context) => const SelectPropertyTypeScreen(),
      ),
    );

    if (selectionResult != null) {
      _openPropertyDetailsModal(
        intent: selectionResult['intent'],
        subtype: selectionResult['subtype'],
      );
    }
  }

  // Modal to fill final details (Title, Price, Image)
  void _openPropertyDetailsModal({
    required String? intent,
    required String? subtype,
    Map<String, dynamic>? existingProperty,
    int? index,
  }) {
    final titleController = TextEditingController(text: existingProperty?['title'] ?? '');
    final priceController = TextEditingController(text: existingProperty?['price']?.toString() ?? '');

    String displayType = subtype != null
        ? subtype.replaceAll('_', ' ').toUpperCase()
        : (intent == 'own' ? 'FOR SALE' : 'RENTAL');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  existingProperty == null ? 'Complete Listing Details' : 'Edit Property',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Listing Category: $displayType',
                  style: const TextStyle(fontSize: 13, color: AppColors.accent, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Property Title',
                    hintText: 'e.g., Luxury 2 Bedroom Apartment',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(
                    labelText: intent == 'rent' ? 'Price (e.g., \$1,500/mo)' : 'Price (e.g., \$350,000)',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      if (titleController.text.isEmpty || priceController.text.isEmpty) return;

                      setState(() {
                        if (existingProperty != null && index != null) {
                          _myListings[index]['title'] = titleController.text;
                          _myListings[index]['price'] = priceController.text;
                        } else {
                          _myListings.insert(0, {
                            'id': DateTime.now().millisecondsSinceEpoch.toString(),
                            'title': titleController.text,
                            'price': priceController.text,
                            'type': displayType,
                            'intent': intent,
                            'views': 0,
                            'inquiries': 0,
                            'units_left': 1,
                            'status': 'PENDING',
                            'image': 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=600&q=80',
                          });
                        }
                      });

                      Navigator.pop(ctx);
                    },
                    child: Text(
                      existingProperty == null ? 'Publish Listing' : 'Update Property',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _deleteListing(int index) {
    setState(() {
      _myListings.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Listing deleted successfully.')),
    );
  }

  void _toggleStatus(int index) {
    setState(() {
      final currentStatus = _myListings[index]['status']?.toString().toUpperCase();
      _myListings[index]['status'] = (currentStatus == 'ACTIVE') ? 'PENDING' : 'ACTIVE';
    });
  }

  Widget _buildListingImage(Map<String, dynamic> item) {
    if (item['image'] is String && (item['image'] as String).isNotEmpty) {
      return Image.network(
        item['image'],
        width: 110,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
      );
    }

    if (item['photos'] is Map) {
      final Map photosMap = item['photos'] as Map;
      for (var val in photosMap.values) {
        if (val is XFile) {
          if (kIsWeb || val.path.startsWith('blob:') || val.path.startsWith('http')) {
            return Image.network(
              val.path,
              width: 110,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
            );
          } else {
            return Image.file(
              File(val.path),
              width: 110,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
            );
          }
        }
      }
    }

    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 110,
      height: 80,
      color: Colors.grey.shade200,
      child: const Icon(Icons.home_outlined, color: Colors.grey),
    );
  }

  // Promotional Hero Header Content Replacement
  Widget _buildSellConfidenceHero() {
    final bool isMobile = MediaQuery.of(context).size.width < 850;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Flex(
            direction: isMobile ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Content
              Expanded(
                flex: isMobile ? 0 : 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sell your home with\nconfidence',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.15,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'We give you multiple options to sell your home with the flexibility to choose what works best for your unique situation, timeline and goals.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF94A3B8),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _startPropertyListingFlow,
                      icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                      label: const Text('Explore your options'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0256FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),

              if (!isMobile) const SizedBox(width: 40) else const SizedBox(height: 32),

              // Right Showcase Card Image Overlay
              Expanded(
                flex: isMobile ? 0 : 6,
                child: Container(
                  height: 280,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: const DecorationImage(
                      image: NetworkImage(
                        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=800&q=80',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: 20,
                        bottom: 20,
                        child: Container(
                          width: 220,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Showcase Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0256FF),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                                    SizedBox(width: 4),
                                    Text(
                                      'Showcase',
                                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=400&q=80',
                                  height: 75,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '\$465,500',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A)),
                              ),
                              const Text(
                                '4 beds • 3 baths • 2,048 sqft',
                                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Dark Hero Section (Contains Navbar & Sell Confidence Showcase)
            Container(
              color: const Color(0xFF0F172A),
              child: Column(
                children: [
                  const NavBar(),
                  _buildSellConfidenceHero(),
                ],
              ),
            ),

            // Content Container
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1100),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview Stats Section (Responsive Layout Fix)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        bool isMobile = constraints.maxWidth < 650;

                        if (isMobile) {
                          return Column(
                            children: [
                              Row(
                                children: [
                                  _buildStatCard('Active Listings', '${_myListings.length}', Icons.home_work_outlined, Colors.blue),
                                  const SizedBox(width: 12),
                                  _buildStatCard('Total Inquiries', '$_totalInquiries', Icons.chat_bubble_outline_rounded, Colors.green),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _buildStatCard('Total Views', '$_totalViews', Icons.remove_red_eye_outlined, Colors.purple),
                                ],
                              ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            _buildStatCard('Active Listings', '${_myListings.length}', Icons.home_work_outlined, Colors.blue),
                            const SizedBox(width: 16),
                            _buildStatCard('Total Inquiries', '$_totalInquiries', Icons.chat_bubble_outline_rounded, Colors.green),
                            const SizedBox(width: 16),
                            _buildStatCard('Total Views', '$_totalViews', Icons.remove_red_eye_outlined, Colors.purple),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 36),

                    // Active Properties Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Your Listed Properties',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        IconButton(
                          onPressed: _fetchLandlordListings,
                          icon: const Icon(Icons.refresh_rounded),
                          tooltip: 'Refresh Properties',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Property Cards List with Loading Indicator
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_myListings.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text('No properties listed yet. Click "Explore your options" to get started.'),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _myListings.length,
                        itemBuilder: (context, index) {
                          final item = _myListings[index];
                          return _buildListingRow(item, index);
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Stat Card Widget
  // Stat Card Widget (Overflow Protected)
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Listing Item Card with Responsive Overflow Fix
  Widget _buildListingRow(Map<String, dynamic> item, int index) {
    final String rawStatus = item['status']?.toString().toUpperCase() ?? 'PENDING';
    final bool isActive = rawStatus == 'ACTIVE';
    final bool isMobile = MediaQuery.of(context).size.width < 850;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildListingImage(item),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isActive ? Colors.green.shade50 : Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isActive ? 'LOCKED' : 'ACTIVE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isActive ? Colors.green.shade700 : Colors.amber.shade800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  (item['subtype'] ?? item['type'] ?? 'PROPERTY').toString().toUpperCase(),
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['title'] ?? 'Listing',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['price'] != null ? '\$${item['price']}' : '',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LandlordConversationsScreen(
                              propertyId: item['id'].toString(),
                              propertyTitle: item['title'] ?? 'Property Chat',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline, size: 16),
                      label: const Text('Messages', style: TextStyle(fontSize: 12)),
                    ),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _openPropertyDetailsModal(
                            intent: item['intent'],
                            subtype: item['subtype'],
                            existingProperty: item,
                            index: index,
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 14),
                          label: const Text('Edit', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0F172A),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF64748B), size: 20),
                          onSelected: (value) {
                            if (value == 'toggle_status') {
                              _toggleStatus(index);
                            } else if (value == 'delete') {
                              _deleteListing(index);
                            }
                          },
                          itemBuilder: (BuildContext context) => [
                            PopupMenuItem(
                              value: 'toggle_status',
                              child: Text(isActive ? 'Mark as Pending' : 'Mark as Active'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete Listing', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: _buildUnitCounter(item)),
                    Row(
                      children: [
                        Text('${item['views'] ?? 0} views', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        const SizedBox(width: 12),
                        Text('${item['inquiries'] ?? 0} inquiries', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent)),
                      ],
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildListingImage(item),
                ),
                const SizedBox(width: 16),

                // Property Info
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.green.shade50 : Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isActive ? 'LOCKED (PENDING)' : 'ACTIVE (UNLOCKED)',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isActive ? Colors.green.shade700 : Colors.amber.shade800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              (item['subtype'] ?? item['type'] ?? 'PROPERTY').toString().toUpperCase(),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item['title'] ?? 'Listing',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LandlordConversationsScreen(
                                    propertyId: item['id'].toString(),
                                    propertyTitle: item['title'] ?? 'Property Chat',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.chat_bubble_outline, size: 16),
                            label: const Text('Messages'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['price'] != null ? '\$${item['price']}' : '',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                      const SizedBox(height: 8),
                      _buildUnitCounter(item),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Analytics Summary
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Column(
                        children: [
                          Text('${item['views'] ?? 0}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          const Text('Views', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Column(
                        children: [
                          Text('${item['inquiries'] ?? 0}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.accent)),
                          const Text('Inquiries', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Action Buttons (Wrapped safely)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _openPropertyDetailsModal(
                        intent: item['intent'],
                        subtype: item['subtype'],
                        existingProperty: item,
                        index: index,
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F172A),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF64748B)),
                      onSelected: (value) {
                        if (value == 'toggle_status') {
                          _toggleStatus(index);
                        } else if (value == 'delete') {
                          _deleteListing(index);
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        PopupMenuItem(
                          value: 'toggle_status',
                          child: Text(isActive ? 'Mark as Pending' : 'Mark as Active'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete Listing', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}