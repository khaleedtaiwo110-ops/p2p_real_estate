import 'package:flutter/material.dart';
import '../../../models/property_model.dart';
import '../../property_details/property_details_screen.dart';

class StaggeredPropertyCard extends StatelessWidget {
  final Property property;
  final double imageHeight;

  const StaggeredPropertyCard({
    Key? key,
    required this.property,
    required this.imageHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String imagePath = property.imageUrls.isNotEmpty
        ? property.imageUrls.first
        : 'assets/images/house1.jpg';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PropertyDetailsScreen(property: property),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background Image
            SizedBox(
              height: imageHeight,
              width: double.infinity,
              child: Image.network(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFF1E293B),
                  child: const Icon(Icons.home, color: Colors.white54, size: 40),
                ),
              ),
            ),

            // Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.4),
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                    ],
                  ),
                ),
              ),
            ),

            // Location Text Header
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Text(
                '${property.city}, ${property.state}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                  shadows: [
                    Shadow(offset: Offset(0, 1), blurRadius: 4, color: Colors.black45),
                  ],
                ),
              ),
            ),

            // Floating Pill Button
            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                  children: const [
                    Text(
                      'View Homes',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
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
    );
  }
}

class TestimonialCard extends StatelessWidget {
  const TestimonialCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF64748B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Community Reviewer',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'Local Resident',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: 14),
          Text(
            '“I just moved to the neighborhood 2 years ago and love it! It\'s a great mix of families, quiet streets, and close to everything.”',
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}