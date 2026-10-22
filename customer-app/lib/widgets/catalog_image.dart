import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

String? firstCatalogUrl(Iterable<String?> urls) {
  for (final url in urls) {
    final value = url?.trim() ?? '';
    if (value.isNotEmpty) return value;
  }
  return null;
}

/// Catalogue picture from `icon_url`. A missing or failed URL leaves an empty box.
class CatalogImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;

  const CatalogImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    final value = url?.trim() ?? '';
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: value,
        width: width,
        height: height,
        fit: fit,
        placeholder: (_, __) => SizedBox(width: width, height: height),
        errorWidget: (_, __, ___) => SizedBox(width: width, height: height),
      );
    }
    if (value.startsWith('assets/')) {
      return Image.asset(value, width: width, height: height, fit: fit);
    }
    return SizedBox(width: width, height: height);
  }
}
