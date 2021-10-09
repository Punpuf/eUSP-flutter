class Restaurant {
  final int id;
  final String name;
  final String campusName;
  final String thumbnailUrl;
  final String address;
  final String latitude;
  final String longitude;
  final String phoneNumber;
  final String workingHours_weekday;
  final String workingHours_saturday;
  final String workingHours_sunday;
  final String cashierInfo;

  const Restaurant({
    required this.id,
    required this.name,
    required this.campusName,
    required this.thumbnailUrl,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.phoneNumber,
    required this.workingHours_weekday,
    required this.workingHours_saturday,
    required this.workingHours_sunday,
    required this.cashierInfo,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'],
      name: json['name'],
      campusName: json['campusName'],
      thumbnailUrl: json['thumbnailUrl'],
      address: json['address'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      phoneNumber: json['phoneNumber'],
      workingHours_weekday: json['workingHours_weekday'],
      workingHours_saturday: json['workingHours_saturday'],
      workingHours_sunday: json['workingHours_sunday'],
      cashierInfo: json['cashierInfo'],
    );
  }
}