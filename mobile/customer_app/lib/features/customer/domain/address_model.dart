class AddressModel {
  final String id;
  final String label;
  final String street;
  final String? apartment;
  final String? comment;
  final bool isDefault;
  final double? latitude;
  final double? longitude;
  final int? entrance;
  final int? floor;
  final String? intercom;

  const AddressModel({
    required this.id,
    required this.label,
    required this.street,
    this.apartment,
    this.comment,
    this.isDefault = false,
    this.latitude,
    this.longitude,
    this.entrance,
    this.floor,
    this.intercom,
  });

  String get fullAddress {
    if (apartment != null && apartment!.isNotEmpty) {
      return '$street, кв. $apartment';
    }
    return street;
  }

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'].toString(),
      label: json['label'] as String? ?? '',
      street: json['address'] as String? ?? '',
      apartment: json['apartment'] as String?,
      comment: null,
      isDefault: json['is_default'] as bool? ?? false,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      entrance: json['entrance'] as int?,
      floor: json['floor'] as int?,
      intercom: json['intercom'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'label': label,
    'address': street,
    if (apartment != null) 'apartment': apartment,
    if (entrance != null) 'entrance': entrance,
    if (floor != null) 'floor': floor,
    if (intercom != null) 'intercom': intercom,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
  };

  AddressModel copyWith({
    String? id,
    String? label,
    String? street,
    String? apartment,
    String? comment,
    bool? isDefault,
    double? latitude,
    double? longitude,
    int? entrance,
    int? floor,
    String? intercom,
  }) {
    return AddressModel(
      id: id ?? this.id,
      label: label ?? this.label,
      street: street ?? this.street,
      apartment: apartment ?? this.apartment,
      comment: comment ?? this.comment,
      isDefault: isDefault ?? this.isDefault,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      entrance: entrance ?? this.entrance,
      floor: floor ?? this.floor,
      intercom: intercom ?? this.intercom,
    );
  }
}
