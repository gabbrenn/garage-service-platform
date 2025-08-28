class GarageService {
  final int id;
  final String name;
  final String? description;
  final double price;
  final int? estimatedDurationMinutes;
  final DateTime createdAt;

  GarageService({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.estimatedDurationMinutes,
    required this.createdAt,
  });

  // Safe JSON parsing with null checks and fallbacks
  factory GarageService.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return GarageService.fallback();
    }

    return GarageService(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? 'Unknown Service',
      description: json['description']?.toString(),
      price: json['price'] != null ? (json['price'] as num).toDouble() : 0.0,
      estimatedDurationMinutes: json['estimatedDurationMinutes'] != null
          ? (json['estimatedDurationMinutes'] as num).toInt()
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Fallback instance in case of null or missing data
  factory GarageService.fallback() {
    return GarageService(
      id: 0,
      name: 'Unknown Service',
      description: null,
      price: 0.0,
      estimatedDurationMinutes: null,
      createdAt: DateTime.now(),
    );
  }

  String get formattedPrice => '\$${price.toStringAsFixed(2)}';
  
  String get formattedDuration {
    if (estimatedDurationMinutes == null) return 'Duration not specified';
    if (estimatedDurationMinutes! < 60) return '${estimatedDurationMinutes}min';
    int hours = estimatedDurationMinutes! ~/ 60;
    int minutes = estimatedDurationMinutes! % 60;
    return minutes > 0 ? '${hours}h ${minutes}min' : '${hours}h';
  }
}
