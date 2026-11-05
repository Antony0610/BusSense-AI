/// Commuter Favorite Destination Categories
enum PlaceCategory {
  home('Home'),
  work('Work'),
  college('College'),
  custom('Custom');

  final String label;
  const PlaceCategory(this.label);

  static PlaceCategory fromString(String val) {
    switch (val.toLowerCase()) {
      case 'home':
        return PlaceCategory.home;
      case 'work':
      case 'office':
        return PlaceCategory.work;
      case 'college':
      case 'campus':
      case 'university':
        return PlaceCategory.college;
      default:
        return PlaceCategory.custom;
    }
  }
}

/// Commuter Saved Favorite Place
class SavedPlaceModel {
  final String id;
  final String label;
  final String itemType;
  final String referenceId; // Stop name or location identifier
  final String? address;
  final String? createdAt;
  final PlaceCategory category;

  const SavedPlaceModel({
    required this.id,
    required this.label,
    this.itemType = 'DESTINATION',
    required this.referenceId,
    this.address,
    this.createdAt,
    this.category = PlaceCategory.custom,
  });

  factory SavedPlaceModel.fromJson(Map<String, dynamic> json) {
    final label = json['label'] as String? ?? 'Saved Destination';
    return SavedPlaceModel(
      id: json['id'] as String? ?? '',
      label: label,
      itemType: json['item_type'] as String? ?? 'DESTINATION',
      referenceId: json['reference_id'] as String? ?? '',
      address: json['address'] as String?,
      createdAt: json['created_at'] as String?,
      category: PlaceCategory.fromString(label),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'item_type': itemType,
        'reference_id': referenceId,
        'address': address,
        'created_at': createdAt,
      };

  SavedPlaceModel copyWith({
    String? id,
    String? label,
    String? itemType,
    String? referenceId,
    String? address,
    String? createdAt,
    PlaceCategory? category,
  }) {
    return SavedPlaceModel(
      id: id ?? this.id,
      label: label ?? this.label,
      itemType: itemType ?? this.itemType,
      referenceId: referenceId ?? this.referenceId,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
    );
  }
}
