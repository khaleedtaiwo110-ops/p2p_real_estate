import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'property_upload_wizard_screen.dart';

class SelectPropertyTypeScreen extends StatefulWidget {
  const SelectPropertyTypeScreen({Key? key}) : super(key: key);

  @override
  State<SelectPropertyTypeScreen> createState() => _SelectPropertyTypeScreenState();
}

class _SelectPropertyTypeScreenState extends State<SelectPropertyTypeScreen> {
  // Default intent set to 'rent' so cards show immediately
  String _selectedListingIntent = 'rent'; 
  String? _selectedRentSubtype;

  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Rental Types Config
  final List<Map<String, String>> _rentalTypes = [
    {
      'id': 'self_contain',
      'title': 'Self Contain',
      'subtitle': 'Studio / Single room with private facility',
      'image': 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=800&q=80',
    },
    {
      'id': 'one_bedroom',
      'title': '1 Bedroom & Parlour',
      'subtitle': '1 Bed + 1 Living room unit',
      'image': 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?auto=format&fit=crop&w=800&q=80',
    },
    {
      'id': 'two_bedroom',
      'title': '2 Bedroom Flat',
      'subtitle': 'Standard 2-bedroom apartment',
      'image': 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=800&q=80',
    },
    {
      'id': 'three_bedroom',
      'title': '3 Bedroom Flat',
      'subtitle': 'Spacious 3-bedroom family unit',
      'image': 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=800&q=80',
    },
    {
      'id': 'three_bedroom_plus',
      'title': '3 Bedroom+',
      'subtitle': 'Luxury penthouses, duplexes & villas',
      'image': 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=800&q=80',
    },
  ];

  // Sale/Ownership Types Config
  final List<Map<String, String>> _saleTypes = [
    {
      'id': 'bungalow',
      'title': 'Bungalow',
      'subtitle': 'Single-story residential building',
      'image': 'https://images.unsplash.com/photo-1570129477492-45c003edd2be?auto=format&fit=crop&w=800&q=80',
    },
    {
      'id': 'semi_detached_duplex',
      'title': 'Semi-Detached Duplex',
      'subtitle': 'Joined property sharing a single wall',
      'image': 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=800&q=80',
    },
    {
      'id': 'fully_detached_duplex',
      'title': 'Fully Detached Duplex',
      'subtitle': 'Standalone duplex with private compound',
      'image': 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=800&q=80',
    },
    {
      'id': '2_story_building',
      'title': '2 Story Building',
      'subtitle': 'Multi-level architectural house',
      'image': 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=800&q=80',
    },
    {
      'id': '3_story_building',
      'title': '3 Story Building',
      'subtitle': 'High-capacity storey residence',
      'image': 'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=800&q=80',
    },
  ];

  List<Map<String, String>> get _currentActiveList {
    return _selectedListingIntent == 'own' ? _saleTypes : _rentalTypes;
  }

  void _scrollToNext() {
    if (_currentPage < _currentActiveList.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollToPrevious() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeList = _currentActiveList;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('List Your Property', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Header & Intent Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Your Intended Property Type',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildIntentCard(
                          intent: 'rent',
                          title: 'For Rent',
                          icon: Icons.key_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildIntentCard(
                          intent: 'own',
                          title: 'For Sale (Own)',
                          icon: Icons.sell_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Rental / Sale Types Full-Height Carousel Card Stack
            Expanded(
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: activeList.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final item = activeList[index];
                      final isSelected = _selectedRentSubtype == item['id'];

                      return Container(
                        margin: const EdgeInsets.all(16),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedRentSubtype = item['id'];
                            });
                          },
                          borderRadius: BorderRadius.circular(24),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isSelected ? AppColors.accent : Colors.white24,
                                width: isSelected ? 4 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Stack(
                                children: [
                                  // Background Image
                                  Positioned.fill(
                                    child: Image.network(
                                      item['image']!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  // Dark Gradient Overlay
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.black.withOpacity(0.2),
                                            Colors.black.withOpacity(0.85),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Top Right Badge
                                  Positioned(
                                    top: 20,
                                    right: 20,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppColors.accent : Colors.black54,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            isSelected ? 'Selected' : 'Tap to Select',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Bottom Text Overlay
                                  Positioned(
                                    left: 20,
                                    right: 20,
                                    bottom: 24,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['title']!,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 26,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          item['subtitle']!,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 15,
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Left Nav Arrow
                  if (_currentPage > 0)
                    Positioned(
                      left: 28,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.black.withOpacity(0.65),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                            onPressed: _scrollToPrevious,
                          ),
                        ),
                      ),
                    ),

                  // Right Nav Arrow
                  if (_currentPage < activeList.length - 1)
                    Positioned(
                      right: 28,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.black.withOpacity(0.65),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 20),
                            onPressed: _scrollToNext,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Footer Action Button
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _selectedRentSubtype == null
                      ? null
                      : () async {
                          final listingData = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PropertyUploadWizardScreen(
                                listingIntent: _selectedListingIntent,
                                subtype: _selectedRentSubtype!,
                              ),
                            ),
                          );

                          if (listingData != null && mounted) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                Navigator.pop(context, listingData);
                              }
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Continue to Property Details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntentCard({
    required String intent,
    required String title,
    required IconData icon,
  }) {
    final bool isSelected = _selectedListingIntent == intent;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedListingIntent = intent;
          _selectedRentSubtype = null; // Clear card selection on category change
          _currentPage = 0;
          if (_pageController.hasClients) {
            _pageController.jumpToPage(0);
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.accent : Colors.white12,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}