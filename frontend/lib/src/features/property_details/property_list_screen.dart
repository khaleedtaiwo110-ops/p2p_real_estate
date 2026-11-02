import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../core/theme/app_theme.dart' as app_theme;
import '../../models/property_model.dart';
import '../explore/widgets/staggered_property_card.dart';

class PropertyListScreen extends StatefulWidget {
  final List<Property> allProperties;
  final String initialCategory;
  final String initialSubCategory;
  final String searchQuery;

  const PropertyListScreen({
    Key? key,
    required this.allProperties,
    this.initialCategory = 'ALL',
    this.initialSubCategory = 'ALL',
    this.searchQuery = '',
  }) : super(key: key);

  @override
  State<PropertyListScreen> createState() => _PropertyListScreenState();
}

class _PropertyListScreenState extends State<PropertyListScreen> {
  late String _selectedCategory;
  late String _selectedSubCategory;
  late TextEditingController _searchController;

  final List<String> _houseSubcategories = [
    'ALL',
    'Bungalow',
    'Semi Detached Duplex',
    'Fully Detached Duplex',
    '2 Story Building',
    '3 Story Building',
    'Others'
  ];

  final List<String> _rentSubcategories = [
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
    _selectedCategory = widget.initialCategory;
    _selectedSubCategory = widget.initialSubCategory;
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Property> get _filteredProperties {
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

      // Fix 1: Case-insensitive property type comparison
      if (_selectedCategory != 'ALL' && 
          p.propertyType.trim().toUpperCase() != _selectedCategory.trim().toUpperCase()) {
        return false;
      }

      // Fix 2: Safe subcategory filtering (ignores 'ALL' and 'Others')
      if (_selectedSubCategory != 'ALL' && _selectedSubCategory != 'Others') {
        final sub = _selectedSubCategory.toLowerCase();
        final desc = p.description.toLowerCase();
        final title = p.title.toLowerCase();
        if (!desc.contains(sub) && !title.contains(sub)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredProperties;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        title: TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Search location, title...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 15),
          ),
          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: app_theme.AppColors.primary),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryChip('ALL', 'All Units'),
                  _buildDropdownCategoryChip('OWN', 'Houses', _houseSubcategories),
                  _buildDropdownCategoryChip('RENT', 'Rentals', _rentSubcategories),
                  _buildCategoryChip('LAND', 'Land/Plots'),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Results Grid
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'No listings found matching your search.',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: MasonryGridView.count(
                      crossAxisCount: MediaQuery.of(context).size.width > 700 ? 3 : 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final property = filtered[index];
                        final bool isTall = index % 2 == 0;
                        return StaggeredPropertyCard(
                          property: property,
                          imageHeight: isTall ? 260.0 : 180.0,
                        );
                      },
                    ),
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
    List<String> subcategories,
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