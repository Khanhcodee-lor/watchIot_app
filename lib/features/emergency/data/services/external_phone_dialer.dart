import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/family_contact.dart';
import '../../domain/repositories/phone_dialer.dart';

class ExternalPhoneDialer implements PhoneDialer {
  @override
  Future<bool> openDialer(String phoneNumber) async {
    final number = normalizePhoneNumber(phoneNumber);
    if (!isValidPhoneNumber(number)) return false;

    return launchUrl(
      Uri(scheme: 'tel', path: number),
      mode: LaunchMode.externalApplication,
    );
  }
}
