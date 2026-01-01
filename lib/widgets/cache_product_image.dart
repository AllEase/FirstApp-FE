import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class CachedProductImage extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;
  final double borderRadius;

  const CachedProductImage({
    super.key,
    required this.imageUrl,
    this.width = 80.0,
    this.height = 100.0,
    this.borderRadius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        
        fadeInDuration: const Duration(milliseconds: 500), // Smooth 0.5s fade
        fadeOutDuration: const Duration(milliseconds: 300),
        fadeInCurve: Curves.easeIn, 

        placeholder: (context, url) => Shimmer.fromColors(
          baseColor: const Color(0xFFE5E7EB),
          highlightColor: const Color(0xFFF3F4F6),
          child: Container(
            width: width,
            height: height,
            color: Colors.white,
          ),
        ),

        // --- ERROR STATE ---
        errorWidget: (context, url, error) => Container(
          width: width,
          height: height,
          color: const Color(0xFFF3F4F6),
          child: const Icon(
            Icons.broken_image_outlined,
            size: 30,
            color: Color(0xFF9CA3AF),
          ),
        ),
      ),
    );
  }
}