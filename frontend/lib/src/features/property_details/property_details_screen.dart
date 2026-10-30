import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/property_model.dart';
import '../../core/theme/app_theme.dart' as app_theme;
import '../auth/login_screen.dart';
import '../chat/chat_screen.dart';
import '../../services/storage_service.dart';
import '../../core/utils/image_helper.dart';
import '../../core/network/api_config.dart'; // 👈 Centralized API configuration

class PropertyDetailsScreen extends StatefulWidget {
  final Property property;

  const PropertyDetailsScreen({
    Key? key,
    required this.property,
  }) : super(key: key);

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  bool _isSaved = false;
  List<Property> _sameLocationProperties = [];
  bool _isLoadingOtherUnits = true;

  @override
  void initState() {
    super.initState();
    _fetchPropertiesAtSameLocation();
  }

  Future<void> _fetchPropertiesAtSameLocation() async {
    setState(() => _isLoadingOtherUnits = true);
    // 🌐 Use ApiConfig.baseUrl instead of local checks
    final String baseUrl = ApiConfig.baseUrl;
    final String currentAddress = widget.property.address.trim();

    try {
      final Uri requestUrl = Uri.parse(
        '$baseUrl/properties/?address=${Uri.encodeComponent(currentAddress)}',
      );
      final response = await http.get(requestUrl);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<Property> fetched =
            data.map((json) => Property.fromJson(json)).toList();

        setState(() {
          _sameLocationProperties = fetched
              .where((item) => item.id != widget.property.id)
              .toList();
          _isLoadingOtherUnits = false;
        });
      } else {
        setState(() => _isLoadingOtherUnits = false);
      }
    } catch (e) {
      debugPrint('Error fetching same location properties: $e');
      setState(() => _isLoadingOtherUnits = false);
    }
  }

  Future<bool> submitPropertyReview({
    required BuildContext context,
    required String baseUrl,
    required int propertyId,
    required int rating,
    required String comment,
  }) async {
    try {
      String? token = await StorageService.getToken();

      if (token == null || token.trim().isEmpty) {
        if (!context.mounted) return false;

        final bool? loggedIn = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );

        if (loggedIn == true) {
          token = await StorageService.getToken();
        } else {
          return false;
        }
      }

      if (token == null || token.trim().isEmpty) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/properties/$propertyId/reviews/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${token.trim()}',
        },
        body: jsonEncode({
          'rating': rating,
          'comment': comment,
        }),
      );

      if (response.statusCode == 201) {
        if (!context.mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully!')),
        );
        return true;
      } else {
        debugPrint('Error (${response.statusCode}): ${response.body}');
        if (!context.mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed: ${response.statusCode} - ${response.body}')),
        );
        return false;
      }
    } catch (e) {
      debugPrint('Review submission error: $e');
      return false;
    }
  }

  Widget _buildImageWidget(String path, {BoxFit fit = BoxFit.cover}) {
    return buildNetworkOrFileImage(path, fit: fit);
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFF1E293B),
      child: const Center(
        child: Icon(Icons.home_work_rounded, size: 48, color: Colors.white70),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.property;
    final images = property.imageUrls;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(property.title),
        backgroundColor: app_theme.AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Photo Grid & Action Bar Area
            Stack(
              children: [
                Container(
                  height: 320,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 6,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: images.isNotEmpty
                              ? _buildImageWidget(images[0])
                              : _buildPlaceholder(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: images.length > 1
                                    ? _buildImageWidget(images[1])
                                    : _buildPlaceholder(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    images.length > 2
                                        ? _buildImageWidget(images[2])
                                        : _buildPlaceholder(),
                                    if (images.length > 3)
                                      Container(
                                        color: Colors.black.withOpacity(0.4),
                                        child: Center(
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.photo_library,
                                                  color: Colors.white, size: 14),
                                              const SizedBox(width: 4),
                                              Text(
                                                '+${images.length - 2}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
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
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 20,
                  right: 20,
                  left: 120,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: _buildTopPillButton(
                          icon: Icons.block,
                          label: 'Hide',
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: _buildTopPillButton(
                          icon: Icons.ios_share,
                          label: 'Share',
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: _buildTopPillButton(
                          icon: _isSaved ? Icons.favorite : Icons.favorite_border,
                          iconColor: _isSaved ? Colors.red : Colors.black87,
                          label: _isSaved ? 'Saved' : 'Save',
                          onTap: () {
                            setState(() {
                              _isSaved = !_isSaved;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 20,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: property.requiresAgent
                          ? Colors.amber.shade800
                          : Colors.green.shade600,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      property.requiresAgent ? 'FOR RENT • AGENT' : 'FOR RENT • P2P',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // 2. Main Overview Section (Responsive Layout Builder Fix)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      bool isNarrow = constraints.maxWidth < 600;

                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPropertyMetaInfo(),
                            const SizedBox(height: 16),
                            _buildPriceAndActionSection(),
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 6,
                            child: _buildPropertyMetaInfo(),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 5,
                            child: _buildPriceAndActionSection(),
                          ),
                        ],
                      );
                    },
                  ),

                  const Divider(height: 36),

                  // 3. Contact Manager Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Contact Manager / Landlord',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          property.requiresAgent
                              ? 'Verified Listing Agent'
                              : 'Direct Property Owner',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.phone, size: 16),
                                label: const Text('Call'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  // 🌐 Use ApiConfig.baseUrl here
                                  final String baseUrl = ApiConfig.baseUrl;
                                  final String? token = await StorageService.getToken();
                                  if (token == null || token.trim().isEmpty) {
                                    if (!context.mounted) return;
                                    final bool? loggedIn = await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                                    );
                                    if (loggedIn != true) return;
                                  }

                                  final String? activeToken = await StorageService.getToken();
                                  if (activeToken == null) return;

                                  final propertyId = property.id;
                                  final landlordId = property.ownerId;

                                  try {

                                    debugPrint('DEBUG CHAT -> propertyId: ${widget.property.id}, landlordId: ${widget.property.ownerId}');
                                    debugPrint('DEBUG TOKEN: $token');
                                    debugPrint('DEBUG PROPERTY ID: ${widget.property.id}');
                                    debugPrint('DEBUG OWNER ID: ${widget.property.ownerId}');
                                    
                                    final response = await http.post(
                                      
                                      Uri.parse('$baseUrl/chat/initiate/'),
                                      headers: {
                                       'Content-Type': 'application/json',
                                        'Authorization': 'Bearer $token',
                                      },
                                      body: jsonEncode({
                                        'property_id': widget.property.id.toString(),
                                        'landlord_id': widget.property.ownerId.toString(),
                                      }),
                                    );

                                    if (response.statusCode == 200 || response.statusCode == 201) {
                                      final conversationData = jsonDecode(response.body);

                                      if (!context.mounted) return;

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ChatScreen(
                                            conversationId: conversationData['id'],
                                            title: property.title,
                                            currentUserId: conversationData['buyer'].toString(),
                                            authToken: activeToken.trim(),
                                          ),
                                        ),
                                      );
                                    } else {
                                      final errorBody = jsonDecode(response.body);
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            errorBody['error'] ?? 'Could not start conversation (${response.statusCode}).',
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    debugPrint('Error starting chat: $e');
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Network error. Failed to open chat.')),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.message, size: 16),
                                label: const Text('Message'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              showReviewBottomSheet(
                                context,
                                int.parse(property.id),
                                ApiConfig.baseUrl, // 👈 Use ApiConfig.baseUrl here
                              );
                            },
                            icon: const Icon(Icons.rate_review_outlined,
                                size: 16),
                            label: const Text('Leave a Review'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: app_theme.AppColors.primary,
                              side: BorderSide(color: app_theme.AppColors.primary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 4. Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    property.description.isNotEmpty
                        ? property.description
                        : 'No additional details specified for this property.',
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),

                  const Divider(height: 36),

                  // 5. Other Units at Same Address
                  const Text(
                    'Other Units at this Address',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildOtherUnitsSection(),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyMetaInfo() {
    final property = widget.property;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          property.title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${property.address}, ${property.city}, ${property.state}',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.king_bed_outlined, size: 18),
                const SizedBox(width: 4),
                Text('${property.beds} Beds', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bathtub_outlined, size: 18),
                const SizedBox(width: 4),
                Text('${property.baths} Baths', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.square_foot_outlined, size: 18),
                const SizedBox(width: 4),
                Text('${property.sqft} sqft', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceAndActionSection() {
    final property = widget.property;
    final bool isSoldOut = property.unitsLeft <= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '₦${property.price.toStringAsFixed(0)}/yr',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: app_theme.AppColors.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Caution fee deposit applies',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isSoldOut
                ? null
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Starting application process...'),
                      ),
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: isSoldOut
                  ? Colors.grey.shade400
                  : app_theme.AppColors.primary,
              disabledBackgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.grey.shade600,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              isSoldOut ? 'Sold Out' : 'Apply Now',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            color: isSoldOut ? Colors.red.shade50 : Colors.amber.shade50,
            border: Border.all(
              color: isSoldOut ? Colors.red.shade300 : Colors.amber.shade400,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            isSoldOut
                ? 'Sold Out'
                : '${property.unitsLeft} unit${property.unitsLeft == 1 ? '' : 's'} left',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSoldOut ? Colors.red.shade800 : Colors.amber.shade900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopPillButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color iconColor = Colors.black87,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherUnitsSection() {
    if (_isLoadingOtherUnits) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_sameLocationProperties.isEmpty) {
      return Text(
        'No other units available at this exact address right now.',
        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
      );
    }

    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _sameLocationProperties.length,
        itemBuilder: (context, index) {
          final item = _sameLocationProperties[index];
          final String imagePath = item.imageUrls.isNotEmpty
              ? item.imageUrls.first
              : 'assets/images/house1.jpg';

          return Container(
            width: 200,
            margin: const EdgeInsets.only(right: 14),
            child: GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PropertyDetailsScreen(property: item),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    SizedBox(
                      height: 240,
                      width: double.infinity,
                      child: _buildImageWidget(imagePath),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.4),
                              Colors.transparent,
                              Colors.black.withOpacity(0.5),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 14,
                      left: 14,
                      right: 14,
                      child: Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 4,
                              color: Colors.black45,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '₦${item.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: Color(0xFF0F172A),
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
        },
      ),
    );
  }

  void showReviewBottomSheet(BuildContext context, int propertyId, String baseUrl) {
    int selectedRating = 5;
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Leave a Review',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  const Text('Rating', style: TextStyle(fontWeight: FontWeight.w600)),
                  DropdownButton<int>(
                    value: selectedRating,
                    isExpanded: true,
                    items: [1, 2, 3, 4, 5].map((int val) {
                      return DropdownMenuItem<int>(
                        value: val,
                        child: Text('$val Star${val > 1 ? 's' : ''} ⭐'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          selectedRating = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Write your feedback...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final success = await submitPropertyReview(
                          context: context,
                          baseUrl: baseUrl,
                          propertyId: propertyId,
                          rating: selectedRating,
                          comment: commentController.text,
                        );
                        if (success && context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Submit Review'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() => commentController.dispose());
  }
}