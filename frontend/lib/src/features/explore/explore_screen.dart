import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart' as app_theme;
import '../../core/network/api_config.dart'; 
import '../../models/property_model.dart';
import 'widgets/navbar.dart';
import 'widgets/staggered_property_card.dart';

class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({this.milliseconds = 500});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({Key? key}) : super(key: key);

  @override
  State createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State {

  List _properties = [];
  bool _isLoading = true;

  String _selectedCategory = 'ALL';
  String _selectedSubCategory = 'ALL';
  String _userInitial = ''; // Stores the first letter[cite: 1]

  bool _isMapView = false;
  Property? _selectedPropertyForMap;

  final TextEditingController _searchController = TextEditingController();
  final Debouncer _debouncer = Debouncer(milliseconds: 400);

  final List _houseSubcategories = [
    'ALL',
    'Bungalow',
    'Semi Detached Duplex',
    'Fully Detached Duplex',
    '2 Story Building',
    '3 Story Building',
    'Others'
  ];

  final List _rentSubcategories = [
    'ALL',
    'Self Con',
    '1 Bed',
    '2 Bed',
    '3 Bed',
    'Others'
  ];

  @override
  void initState() {
    super.initState();
    _fetchProperties();
    _loadUserInitial(); // Load logged-in user's initial[cite: 1]
  }

  Future _loadUserInitial() async {
    final prefs = await SharedPreferences.getInstance(); //[cite: 1]
    
    // Retrieve username or full_name saved during login/registration
    final String? username = prefs.getString('p2p_username') ?? 
                             prefs.getString('p2p_full_name'); //[cite: 1]

    if (username != null && username.trim().isNotEmpty) { //[cite: 1]
      setState(() {
        // Grab first letter and convert to uppercase
        _userInitial = username.trim()[0].toUpperCase(); //[cite: 1]
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }


  void _addNewPropertyToList(Map data) {
    final photosMap = data['photos'] as Map? ?? {};
    List imagePaths = [];

    photosMap.forEach((key, value) {
      if (value != null && value is File) {
        imagePaths.add(value.path);
      }
    });

    if (imagePaths.isEmpty) {
      imagePaths.add('assets/images/house1.jpg');
    }

    final double parsedPrice = double.tryParse(
      data['price'].toString().replaceAll(RegExp(r'[^0-9.]'), ''),
    ) ?? 0.0;

    final newProperty = Property(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      ownerId: 1,
      title: data['title'] ?? 'New Listing',
      description: data['description'] ?? '',
      price: parsedPrice,
      propertyType: data['intent'] == 'rent' ? 'RENT' : 'OWN',
      address: data['address'] ?? 'Direct Owner Listing',
      city: data['city'] ?? 'Local Area',
      state: data['state'] ?? 'State',
      requiresAgent: false,
      imageUrls: imagePaths.cast(),
      beds: 2,
      baths: 2,
      sqft: 1200,
    );

    setState(() {
      _properties.insert(0, newProperty);
    });
  }

  Future _fetchProperties([String query = '']) async {
    setState(() => _isLoading = true);
    
    try {
      // 🌐 Uses ApiConfig.baseUrl with proper search query string interpolation
      final Uri url = Uri.parse(
        query.isEmpty
            ? '${ApiConfig.baseUrl}/properties/'
            : '${ApiConfig.baseUrl}/properties/?search=${Uri.encodeComponent(query)}',
      );
      
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          _properties = data.map((json) => Property.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        _loadMockData();
      }
    } catch (e) {
      _loadMockData();
    }
  }

  void _loadMockData() {
    setState(() {
      _properties = [
        Property(
          id: '1',
          ownerId: 1,
          title: 'Modern Waterfront Villa',
          description: 'Spacious luxury home featuring panoramic ocean views.',
          price: 1250000,
          propertyType: 'OWN',
          address: '450 Biscayne Blvd',
          city: 'Atlanta',
          state: 'GA',
          requiresAgent: false,
          imageUrls: ['assets/images/house1.jpg'],
          beds: 4,
          baths: 3,
          sqft: 3400,
        ),
        Property(
          id: '2',
          ownerId: 2,
          title: 'Downtown Penthouse Apartment',
          description: 'Fully furnished high-rise apartment.',
          price: 3500,
          propertyType: 'RENT',
          address: '789 Grand Ave',
          city: 'Scottsdale',
          state: 'AZ',
          requiresAgent: true,
          imageUrls: ['assets/images/house2.jpg'],
          beds: 2,
          baths: 2,
          sqft: 1450,
        ),
        Property(
          id: '3',
          ownerId: 3,
          title: 'Prime Commercial Plot',
          description: 'Ready-to-build land with approved permits.',
          price: 450000,
          propertyType: 'LAND',
          address: 'Plot 12 Sunset Highway',
          city: 'Austin',
          state: 'TX',
          requiresAgent: false,
          imageUrls: ['assets/images/land1.jpg'],
          beds: 0,
          baths: 0,
          sqft: 12500,
        ),
        Property(
          id: '4',
          ownerId: 4,
          title: 'Historic Suburban Home',
          description: 'Charming neighborhood family residence.',
          price: 520000,
          propertyType: 'OWN',
          address: '102 Beacon Street',
          city: 'Boston',
          state: 'MA',
          requiresAgent: false,
          imageUrls: ['assets/images/house1.jpg'],
          beds: 3,
          baths: 2,
          sqft: 2100,
        ),
      ];
      _isLoading = false;
    });
  }

  List get _filteredProperties {
    final search = _searchController.text.trim().toLowerCase();

    return _properties.where((p) {
      if (search.isNotEmpty) {
        final matchesTitle = p.title.toLowerCase().contains(search);
        final matchesAddress = p.address.toLowerCase().contains(search);
        final matchesCity = p.city.toLowerCase().contains(search);
        final matchesState = p.state.toLowerCase().contains(search);

        if (!matchesTitle && !matchesAddress && !matchesCity && !matchesState) {
          return false;
        }
      }

      if (_selectedCategory != 'ALL' && p.propertyType != _selectedCategory) {
        return false;
      }

      if (_selectedSubCategory != 'ALL') {
        final sub = _selectedSubCategory.toLowerCase();
        final desc = p.description.toLowerCase();
        final title = p.title.toLowerCase();
        return desc.contains(sub) || title.contains(sub);
      }

      return true;
    }).toList();
  }

  Widget _buildLiveMapView() {
    final Map propertyCoords = {
      1: const LatLng(25.7617, -80.1918),
      2: const LatLng(34.0522, -118.2437),
      3: const LatLng(30.2672, -97.7431),
    };

    return Stack(
      children: [
        FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(25.7617, -80.1918),
            initialZoom: 10.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
              userAgentPackageName: 'com.example.app',
              tileProvider: CancellableNetworkTileProvider(),
            ),
            MarkerLayer(
              markers: _filteredProperties.map((property) {
                final pos = propertyCoords[property.id] ?? const LatLng(25.7617, -80.1918);
                return Marker(
                  point: pos,
                  width: 80,
                  height: 40,
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedPropertyForMap = property);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: app_theme.AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '\$${(property.price / 1000).toStringAsFixed(0)}k',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        if (_selectedPropertyForMap != null)
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Stack(
              children: [
                StaggeredPropertyCard(
                  property: _selectedPropertyForMap!,
                  imageHeight: 220,
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    radius: 14,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.close, color: Colors.white, size: 16),
                      onPressed: () => setState(() => _selectedPropertyForMap = null),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildNotificationPill({
    required IconData icon,
    required Color iconBgColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: iconBgColor,
            child: Icon(icon, color: Colors.white, size: 15),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDreamHomeNotificationBanner() {
    final bool isMobile = MediaQuery.of(context).size.width < 850;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Flex(
        direction: isMobile ? Axis.vertical : Axis.horizontal,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: isMobile ? 0 : 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Get notified when we see\nyour dream house',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    height: 1.18,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Save your preferred locations, budget, and specs. We will automatically alert you the second a matching home hits the market.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF475569),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.notifications_active_rounded, size: 18),
                  label: const Text('Set Instant Alerts'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0256FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),

          if (!isMobile) const SizedBox(width: 48) else const SizedBox(height: 36),

          Expanded(
            flex: isMobile ? 0 : 6,
            child: SizedBox(
              height: 280,
              child: Stack(
                alignment: Alignment.centerRight,
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    right: 0,
                    top: 20,
                    child: Transform.rotate(
                      angle: 0.08,
                      child: Container(
                        width: 240,
                        height: 210,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 20,
                    top: 10,
                    child: Transform.rotate(
                      angle: 0.04,
                      child: Container(
                        width: 250,
                        height: 220,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 35,
                    top: 0,
                    child: Container(
                      width: 260,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: Image.network(
                              'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=500&q=80',
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  '\$695,000',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '4 bd | 3 ba | 3,102 sqft',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    top: 15,
                    child: _buildNotificationPill(
                      icon: Icons.location_on_rounded,
                      iconBgColor: Colors.deepOrange,
                      title: 'New match in preferred area',
                      subtitle: '2 mins ago • Austin, TX',
                    ),
                  ),
                  Positioned(
                    left: 30,
                    bottom: 20,
                    child: _buildNotificationPill(
                      icon: Icons.account_balance_wallet_rounded,
                      iconBgColor: const Color(0xFF0D9488),
                      title: 'Price dropped inside budget',
                      subtitle: 'Under \$700,000 target',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopRecommendedHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Text(
              'Top Recommended Properties',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -1.2,
                height: 1.1,
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Explore handpicked listings tailored to your preferences in prime locations.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredProperties;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                // 1. Hero Search Section
                SliverToBoxAdapter(
                  child: Stack(
                    children: [
                      SizedBox(
                        height: 420,
                        width: double.infinity,
                        child: Image.network(
                          'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1600&q=80',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.55),
                                Colors.black.withOpacity(0.35),
                                Colors.black.withOpacity(0.65),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SafeArea(
                        child: Column(
                          children: [
                            NavBar(
                              userInitial: _userInitial, // Pass to NavBar if required by widget spec
                              onCategorySelected: (category) {
                                setState(() {
                                  _selectedCategory = category == 'HOUSE' ? 'OWN' : category;
                                  _selectedSubCategory = 'ALL';
                                });
                              },
                              onPropertyAdded: (newPropertyData) {
                                _addNewPropertyToList(newPropertyData);
                              },
                            ),
                            const SizedBox(height: 20),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Column(
                                children: [
                                  const Text(
                                    'Find Your Dream Home',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      height: 1.15,
                                      letterSpacing: -0.5,
                                      shadows: [
                                        Shadow(
                                          offset: Offset(0, 2),
                                          blurRadius: 8,
                                          color: Colors.black45,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Container(
                                    constraints: const BoxConstraints(maxWidth: 680),
                                    height: 54,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 16,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _searchController,
                                            onChanged: (val) {
                                              _debouncer.run(() => _fetchProperties(val));
                                              setState(() {});
                                            },
                                            style: const TextStyle(
                                              fontSize: 15,
                                              color: Color(0xFF0F172A),
                                            ),
                                            decoration: const InputDecoration(
                                              hintText: 'Enter an address, neighborhood, city, or ZIP code',
                                              hintStyle: TextStyle(
                                                color: Color(0xFF64748B),
                                                fontSize: 14,
                                              ),
                                              border: InputBorder.none,
                                              contentPadding: EdgeInsets.symmetric(horizontal: 20),
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            _isMapView ? Icons.format_list_bulleted_rounded : Icons.map_rounded,
                                            color: app_theme.AppColors.primary,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _isMapView = !_isMapView;
                                            });
                                          },
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            _fetchProperties(_searchController.text);
                                          },
                                          child: Container(
                                            height: 40,
                                            width: 40,
                                            decoration: const BoxDecoration(
                                              color: app_theme.AppColors.primary,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.search_rounded,
                                              color: Colors.white,
                                              size: 22,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Category Filter Chips
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildCategoryChip('ALL', 'All Units'),
                          _buildDropdownCategoryChip(
                            'OWN',
                            'Houses',
                            _houseSubcategories,
                          ),
                          _buildDropdownCategoryChip(
                            'RENT',
                            'Rentals',
                            _rentSubcategories,
                          ),
                          _buildCategoryChip('LAND', 'Land/Plots'),
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. Main Property Listings / Map / Loading
                _isLoading
                    ? const SliverFillRemaining(
                        child: Center(
                          child: CircularProgressIndicator(
                            color: app_theme.AppColors.accent,
                          ),
                        ),
                      )
                    : _isMapView
                        ? SliverFillRemaining(child: _buildLiveMapView())
                        : filtered.isEmpty
                            ? const SliverFillRemaining(
                                child: Center(
                                  child: Text(
                                    'No listings found matching your search.',
                                    style: TextStyle(color: Colors.grey, fontSize: 16),
                                  ),
                                ),
                              )
                            : SliverMainAxisGroup(
                                slivers: [
                                  SliverToBoxAdapter(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildDreamHomeNotificationBanner(),
                                        _buildTopRecommendedHeader(),
                                      ],
                                    ),
                                  ),
                                  SliverPadding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    sliver: SliverMasonryGrid.count(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 16,
                                      crossAxisSpacing: 16,
                                      childCount: filtered.length,
                                      itemBuilder: (context, index) {
                                        final property = filtered[index];
                                        final bool isTall = index % 2 == 0;
                                        final double imageHeight = isTall ? 280.0 : 180.0;

                                        return StaggeredPropertyCard(
                                          property: property,
                                          imageHeight: imageHeight,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String categoryKey, String label) {
    final isSelected = _selectedCategory == categoryKey;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() {
          _selectedCategory = categoryKey;
          _selectedSubCategory = 'ALL';
        }),
        selectedColor: app_theme.AppColors.primary,
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : app_theme.AppColors.textMuted,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? app_theme.AppColors.primary : Colors.grey.shade300,
          ),
        ),
      ),
    );
  }
  
  Widget _buildDropdownCategoryChip(
  String categoryKey,
  String label,
  List subcategories,
) {
  final isSelected = _selectedCategory == categoryKey;
  final currentSub = _selectedSubCategory;
  final displayLabel = (isSelected && currentSub != 'ALL')
      ? '$label: $currentSub'
      : label;

 return Padding(
  padding: const EdgeInsets.only(right: 8),
    child: PopupMenuButton<String>(
      onSelected: (String sub) {
        setState(() {
          _selectedCategory = categoryKey;
          _selectedSubCategory = sub;
        });
      },
      itemBuilder: (BuildContext context) {
        return List.generate(subcategories.length, (index) {
          final sub = subcategories[index];
          final isSubSelected = currentSub == sub;

          return PopupMenuItem(
            value: sub,
            child: Text(
              sub == 'ALL' ? 'All $label' : sub,
              style: TextStyle(
                fontWeight: isSubSelected ? FontWeight.bold : FontWeight.normal,
                color: isSubSelected ? app_theme.AppColors.primary : Colors.black87,
              ),
            ),
          );
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? app_theme.AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? app_theme.AppColors.primary : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayLabel,
              style: TextStyle(
                color: isSelected ? Colors.white : app_theme.AppColors.textMuted,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: isSelected ? Colors.white : app_theme.AppColors.textMuted,
            ),
          ],
        ),
      ),
    ),
  );
}
}