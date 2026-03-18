class QrTypeDetector {
  QrTypeDetector._();

  static String detect(String content) {
    final lower = content.toLowerCase().trim();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return 'URL';
    } else if (lower.startsWith('mailto:') || lower.contains('@')) {
      return 'Email';
    } else if (lower.startsWith('sms:') || lower.startsWith('smsto:')) {
      return 'SMS';
    } else if (lower.startsWith('tel:') || lower.startsWith('phone:')) {
      return 'Phone';
    } else if (lower.startsWith('wifi:')) {
      return 'Wi-Fi';
    } else if (lower.startsWith('begin:vcard')) {
      return 'Contact';
    } else {
      return 'Text';
    }
  }
}
