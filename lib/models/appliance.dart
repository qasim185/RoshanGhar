class Appliance {
  String id;
  String name;
  int watts;
  double hoursPerDay;
  bool isDaytime; // True = Daytime load, False = Nighttime load
  int quantity;

  Appliance({
    required this.id,
    required this.name,
    required this.watts,
    this.hoursPerDay = 4.0,
    this.isDaytime = true,
    this.quantity = 1,
  });

  // Calculate total watts for this appliance type based on quantity
  int get totalWatts => watts * quantity;

  // Calculate daily energy consumed in kilowatt-hours (kWh)
  double get dailyKWh => (totalWatts * hoursPerDay) / 1000.0;

  // Factory constructor for parsing JSON from SharedPreferences
  factory Appliance.fromJson(Map<String, dynamic> json) {
    return Appliance(
      id: json['id'] as String,
      name: json['name'] as String,
      watts: json['watts'] as int,
      hoursPerDay: (json['hoursPerDay'] as num).toDouble(),
      isDaytime: json['isDaytime'] as bool? ?? true,
      quantity: json['quantity'] as int? ?? 1,
    );
  }

  // Convert to JSON for local persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'watts': watts,
      'hoursPerDay': hoursPerDay,
      'isDaytime': isDaytime,
      'quantity': quantity,
    };
  }

  Appliance copyWith({
    String? id,
    String? name,
    int? watts,
    double? hoursPerDay,
    bool? isDaytime,
    int? quantity,
  }) {
    return Appliance(
      id: id ?? this.id,
      name: name ?? this.name,
      watts: watts ?? this.watts,
      hoursPerDay: hoursPerDay ?? this.hoursPerDay,
      isDaytime: isDaytime ?? this.isDaytime,
      quantity: quantity ?? this.quantity,
    );
  }
}
