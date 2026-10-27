import 'package:flutter/material.dart';
import '../../brand/brand_config.dart';

class BrandLogo extends StatelessWidget {
  final BrandConfig brand;
  final double height;
  final bool showInstitution;

  const BrandLogo({
    super.key,
    required this.brand,
    this.height = 36.0,
    this.showInstitution = true,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      brand.logo,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback elegante em texto quando o asset de logo não existir
        return _buildTextFallback(context);
      },
    );
  }

  Widget _buildTextFallback(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(50),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Colors.white.withAlpha(100),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                brand.appName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        if (showInstitution && brand.siglaInstituicao.isNotEmpty) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: brand.cores.secundaria,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              brand.siglaInstituicao,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
