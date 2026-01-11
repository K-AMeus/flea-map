import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../model/shop.dart';

class ShopListItem extends StatelessWidget {
  final Shop shop;
  final String openingHoursText;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final bool isLoadingFavorite;

  const ShopListItem({
    super.key,
    required this.shop,
    required this.openingHoursText,
    required this.isFavorite,
    required this.onFavoriteToggle,
    this.isLoadingFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          _buildShopImage(),
          const SizedBox(width: 12),
          Expanded(child: _buildShopInfo(context)),
          _buildFavoriteButton(),
        ],
      ),
    );
  }

  Widget _buildShopImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: shop.imageUrl != null && shop.imageUrl!.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: shop.imageUrl!,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              placeholder: (context, url) => _buildImagePlaceholder(
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => _buildImagePlaceholder(
                child: Icon(Icons.store, size: 30, color: Colors.grey.shade400),
              ),
            )
          : _buildImagePlaceholder(
              child: Icon(Icons.store, size: 30, color: Colors.grey.shade400),
            ),
    );
  }

  Widget _buildImagePlaceholder({required Widget child}) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: child,
    );
  }

  Widget _buildShopInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          shop.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        _buildRatingRow(context),
        const SizedBox(height: 4),
        Text(
          openingHoursText,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildRatingRow(BuildContext context) {
    return Row(
      children: [
        ..._buildRatingStars(context),
        if (shop.ratingCount != null) ...[
          const SizedBox(width: 4),
          Text(
            '(${shop.ratingCount})',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildRatingStars(BuildContext context) {
    return List.generate(5, (index) {
      final rating = shop.rating ?? 0;
      if (index < rating.floor()) {
        return const Icon(Icons.star, size: 16, color: Colors.amber);
      } else if (index < rating) {
        return const Icon(Icons.star_half, size: 16, color: Colors.amber);
      } else {
        return Icon(Icons.star_border, size: 16, color: Colors.grey.shade300);
      }
    });
  }

  Widget _buildFavoriteButton() {
    return IconButton(
      icon: isLoadingFavorite
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : Colors.grey,
            ),
      onPressed: onFavoriteToggle,
    );
  }
}
