class FamilyContact {
  const FamilyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
  });

  final String id;
  final String name;
  final String phoneNumber;

  FamilyContact copyWith({String? name, String? phoneNumber}) {
    return FamilyContact(
      id: id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'phone_number': phoneNumber,
  };

  factory FamilyContact.fromJson(Map<String, Object?> json) {
    return FamilyContact(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
    );
  }
}

String normalizePhoneNumber(String value) {
  final stripped = value.trim().replaceAll(RegExp(r'[\s().-]'), '');
  if (stripped.startsWith('+')) {
    return '+${stripped.substring(1).replaceAll(RegExp(r'\D'), '')}';
  }
  return stripped.replaceAll(RegExp(r'\D'), '');
}

bool isValidPhoneNumber(String value) {
  return RegExp(r'^\+?\d{6,15}$').hasMatch(normalizePhoneNumber(value));
}
