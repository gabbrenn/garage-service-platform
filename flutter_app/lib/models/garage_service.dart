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

  factory GarageService.fromJson(Map<String, dynamic> json) {
    return GarageService(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: json['price'].toDouble(),
      estimatedDurationMinutes: json['estimatedDurationMinutes'],
      createdAt: DateTime.parse(json['createdAt']),
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

  String get formattedPrice => '\$${price.toStringAsFixed(2)}';
  
  String get formattedDuration {
    if (estimatedDurationMinutes == null) return 'Duration not specified';
    if (estimatedDurationMinutes! < 60) return '${estimatedDurationMinutes}min';
    int hours = estimatedDurationMinutes! ~/ 60;
    int minutes = estimatedDurationMinutes! % 60;
    return minutes > 0 ? '${hours}h ${minutes}min' : '${hours}h';
  }
}