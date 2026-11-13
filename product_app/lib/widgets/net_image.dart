import 'package:flutter/material.dart';

/// Small square network image with placeholder / error icon.
class NetImage extends StatelessWidget {
  final String? url;
  final double size;
  final IconData placeholder;

  const NetImage({
    super.key,
    required this.url,
    this.size = 56,
    this.placeholder = Icons.inventory_2,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: size,
        height: size,
        child: url == null
            ? Icon(placeholder, size: size * 0.6, color: Colors.grey)
            : Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.broken_image, size: size * 0.6, color: Colors.grey),
              ),
      ),
    );
  }
}
