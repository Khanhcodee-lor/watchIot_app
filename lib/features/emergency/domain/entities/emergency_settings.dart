import 'family_contact.dart';

class EmergencySettings {
  const EmergencySettings({
    required this.databaseUrl,
    required this.deviceUid,
    required this.contacts,
    required this.allowCallWhenConfirmed,
  });

  final String databaseUrl;
  final String deviceUid;
  final List<FamilyContact> contacts;
  final bool allowCallWhenConfirmed;

  bool get hasValidDatabaseUrl {
    final uri = Uri.tryParse(databaseUrl.trim());
    return uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty;
  }

  bool get hasValidDeviceUid => deviceUid.trim().isNotEmpty;

  bool get hasValidContact => contacts.any(
    (contact) =>
        contact.name.trim().isNotEmpty &&
        isValidPhoneNumber(contact.phoneNumber),
  );

  bool get isReadyForCall =>
      hasValidDatabaseUrl && hasValidDeviceUid && hasValidContact;

  EmergencySettings copyWith({
    String? databaseUrl,
    String? deviceUid,
    List<FamilyContact>? contacts,
    bool? allowCallWhenConfirmed,
  }) {
    return EmergencySettings(
      databaseUrl: databaseUrl ?? this.databaseUrl,
      deviceUid: deviceUid ?? this.deviceUid,
      contacts: contacts ?? this.contacts,
      allowCallWhenConfirmed:
          allowCallWhenConfirmed ?? this.allowCallWhenConfirmed,
    );
  }

  Map<String, Object?> toJson() => {
    'database_url': databaseUrl,
    'device_uid': deviceUid,
    'contacts': contacts.map((contact) => contact.toJson()).toList(),
    'allow_call_when_confirmed': allowCallWhenConfirmed,
  };

  factory EmergencySettings.fromJson(Map<String, Object?> json) {
    final contactsValue = json['contacts'];
    final contacts = contactsValue is List
        ? contactsValue
              .whereType<Map>()
              .map(
                (contact) =>
                    FamilyContact.fromJson(Map<String, Object?>.from(contact)),
              )
              .where(
                (contact) => contact.id.isNotEmpty && contact.name.isNotEmpty,
              )
              .toList(growable: false)
        : const <FamilyContact>[];

    return EmergencySettings(
      databaseUrl: json['database_url']?.toString() ?? '',
      deviceUid: json['device_uid']?.toString() ?? '',
      contacts: contacts,
      allowCallWhenConfirmed: json['allow_call_when_confirmed'] == true,
    );
  }
}
