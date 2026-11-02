import 'package:flutter/material.dart';
import '../models/property_model.dart';
import 'staggered_property_card.dart'; // Ensure this matches your project import path

class HorizontalStaggeredPropertyList extends StatelessWidget {
  final List<Property> properties;

  const HorizontalStaggeredPropertyList({
    Key? key,
    required this.properties,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (properties.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(
          child: Text(
            'No properties available',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
      );
    }

    return SizedBox(
      height: 300, // Fixed height container for the horizontal scroll strip
      child: ListView.builder(
        scrollDirection: Axis.horizontal, // 👈 Forces horizontal scrolling along the X-axis alone
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: properties.length,
        itemBuilder: (context, index) {
          final property = properties[index];
          
          // Stagger card sizes and vertical offsets based on even/odd index
          final bool isEven = index % 2 == 0;
          final double cardHeight = isEven ? 240.0 : 190.0;
          final double topOffset = isEven ? 0.0 : 35.0; // Dips alternate cards down along the Y-axis

          return Container(
            width: isEven ? 210.0 : 170.0, // Alternating widths for a staggered look
            margin: EdgeInsets.only(
              right: 16,
              top: topOffset, // Creates the staggered up-and-down visual rhythm
            ),
            child: StaggeredPropertyCard(
              property: property,
              imageHeight: cardHeight,
            ),
          );
        },
      ),
    );
  }
}