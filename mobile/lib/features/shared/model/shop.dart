class Shop {
  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final String category;
  final String? about;
  final String? phone;
  final String? website;
  final Map<String, dynamic>? openingHours;
  final double? rating;
  final int? ratingCount;
  final String? imageUrl;
  const Shop({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.category,
    this.about,
    this.phone,
    this.website,
    this.openingHours,
    this.rating,
    this.ratingCount,
    this.imageUrl,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      category: json['category'] as String,
      about: json['about'] as String?,
      phone: json['phone'] as String?,
      website: json['website'] as String?,
      openingHours: json['opening_hours'] != null
          ? Map<String, dynamic>.from(json['opening_hours'] as Map)
          : null,
      rating: json['rating'] != null
          ? (json['rating'] as num).toDouble()
          : null,
      ratingCount: json['rating_count'] != null
          ? (json['rating_count'] as num).toInt()
          : null,
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'lat': lat,
      'lng': lng,
      'category': category,
      'about': about,
      'phone': phone,
      'website': website,
      'opening_hours': openingHours,
      'rating': rating,
      'rating_count': ratingCount,
      'image_url': imageUrl,
    };
  }

  Map<String, dynamic> toJsonWithId() {
    return {'id': id, ...toJson()};
  }
}
