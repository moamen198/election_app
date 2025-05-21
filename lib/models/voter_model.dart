class Voter {
  final String name;
  final String motherName;
  final String birthdate;
  final String voterNumber;
  final String phone;
  final String region; // المحافظة
  final String familyNumber; // رقم العائلة
  final String registerCenter; // رقم مركز التسجيل
  final String stationInfo; // رقم واسم مركز الاقتراع
  final int fingerprints;

  Voter({
    required this.name,
    required this.motherName,
    required this.birthdate,
    required this.voterNumber,
    required this.phone,
    required this.region,
    required this.familyNumber,
    required this.registerCenter,
    required this.stationInfo,
    this.fingerprints = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'motherName': motherName,
      'birthdate': birthdate,
      'voterNumber': voterNumber,
      'phone': phone,
      'region': region,
      'familyNumber': familyNumber,
      'registerCenter': registerCenter,
      'stationInfo': stationInfo,
      'fingerprints': fingerprints,
    };
  }

  static Voter fromMap(Map<String, dynamic> map) {
    return Voter(
      name: map['name'] ?? '',
      motherName: map['motherName'] ?? '',
      birthdate: map['birthdate'] ?? '',
      voterNumber: map['voterNumber'] ?? '',
      phone: map['phone'] ?? '',
      region: map['region'] ?? '',
      familyNumber: map['familyNumber'] ?? '',
      registerCenter: map['registerCenter'] ?? '',
      stationInfo: map['stationInfo'] ?? '',
      fingerprints: map['fingerprints'] ?? 0,
    );
  }
}