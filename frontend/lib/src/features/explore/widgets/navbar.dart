import 'package:flutter/material.dart';
import '../../explore/explore_screen.dart';
import '../../landlord/landlord_dashboard_screen.dart';
import '../../auth/login_screen.dart';

class NavBar extends StatefulWidget implements PreferredSizeWidget {
  final Function(String category)? onCategorySelected;
  final Function(Map<String, dynamic> propertyData)? onPropertyAdded;
  final String userInitial;

  const NavBar({
    Key? key,
    this.onCategorySelected,
    this.onPropertyAdded,
    this.userInitial = '',
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(65);

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  bool _isMenuExpanded = false;

  void _openLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  Future<void> _handleCategoryTap(String categoryKey) async {
    if (_isMenuExpanded) {
      setState(() {
        _isMenuExpanded = false;
      });
    }

    // 1. Navigate to Landlord Dashboard on Sell and await returned listing
    if (categoryKey == 'SELL') {
      final newProperty = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(
          builder: (context) => const LandlordDashboardScreen(),
        ),
      );

      if (newProperty != null && widget.onPropertyAdded != null) {
        widget.onPropertyAdded!(newProperty);
      }
      return;
    }

    // 2. Return to ExploreScreen on Buy, Rent, or All
    if (categoryKey == 'HOUSE' || categoryKey == 'RENT' || categoryKey == 'ALL') {
      if (context.findAncestorWidgetOfExactType<LandlordDashboardScreen>() != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const ExploreScreen(),
          ),
        );
        return;
      }
    }

    // Pass selected category filter back to ExploreScreen state
    if (widget.onCategorySelected != null) {
      widget.onCategorySelected!(categoryKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 800;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Transparent Top Navigation Bar
        Container(
          height: widget.preferredSize.height,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          color: Colors.transparent,
          child: isDesktop
              ? Row(
                  children: [
                    // Desktop Left Links
                    Expanded(
                      child: Row(
                        children: [
                          _buildNavText('Buy', 'HOUSE'),
                          _buildNavText('Rent', 'RENT'),
                          _buildNavText('Sell', 'SELL'),
                        ],
                      ),
                    ),
                    
                    // Clickable Logo (Home Link)
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const ExploreScreen(),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.home_work_rounded, color: Colors.white, size: 28),
                            SizedBox(width: 8),
                            Text(
                              'P2P Estate',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Desktop Right Links
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildNavText('Manage rentals', 'RENT'),
                          _buildNavText('Advertise', 'ALL'),
                          _buildNavText('Get help', 'ALL'),
                          const SizedBox(width: 12),
                          
                          // Desktop Clickable Avatar
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: _openLogin,
                              child: const CircleAvatar(
                                radius: 18,
                                backgroundColor: Color(0xFF064E3B),
                                child: Text(
                                  'KT',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              // Mobile Header View
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        _isMenuExpanded ? Icons.close_rounded : Icons.menu_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () {
                        setState(() {
                          _isMenuExpanded = !_isMenuExpanded;
                        });
                      },
                    ),
                    
                    // Clickable Mobile Logo
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const ExploreScreen(),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.home_work_rounded, color: Colors.white, size: 24),
                          SizedBox(width: 6),
                          Text(
                            'P2P Estate',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
// Mobile Clickable Avatar
                    GestureDetector(
                      onTap: _openLogin,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFF064E3B),
                        child: Text(
                          widget.userInitial.isNotEmpty ? widget.userInitial : 'U', // Fallback character
                            style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,),
                        ),
                      ),
                    ),
                  ],
                ),
        ),        // Mobile Menu Dropdown Overlay
        if (!isDesktop && _isMenuExpanded)
          Container(
            width: double.infinity,
            color: const Color(0xFF0F172A).withValues(alpha: 0.95),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildMobileMenuItem('Buy', 'HOUSE', Icons.key_rounded),
                _buildMobileMenuItem('Rent', 'RENT', Icons.king_bed_rounded),
                _buildMobileMenuItem('Sell', 'SELL', Icons.sell_rounded),
                const Divider(height: 1, color: Colors.white24),
                _buildMobileMenuItem('Manage rentals', 'RENT', Icons.real_estate_agent_rounded),
                _buildMobileMenuItem('Advertise', 'ALL', Icons.campaign_rounded),
                _buildMobileMenuItem('Get help', 'ALL', Icons.help_outline_rounded),
                const SizedBox(height: 8),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildNavText(String title, String categoryKey) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: TextButton(
        onPressed: () => _handleCategoryTap(categoryKey),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildMobileMenuItem(String title, String categoryKey, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 20),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      onTap: () => _handleCategoryTap(categoryKey),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
    );
  }
}