class AppStrings {
  AppStrings._();

  static const String appName = 'QR Scanner & Generator';

  // Navigation
  static const String scanTab = 'Scan';
  static const String generateTab = 'Generate';
  static const String historyTab = 'History';

  // Scanner
  static const String scannerTitle = 'Scan QR Code';
  static const String scannerHint = 'Point the camera at a QR code';
  static const String scanResult = 'Scan Result';
  static const String scanAgain = 'Scan Again';
  static const String torchOn = 'Torch On';
  static const String torchOff = 'Torch Off';
  static const String flipCamera = 'Flip Camera';

  // Generator
  static const String generatorTitle = 'Generate QR Code';
  static const String enterText = 'Enter text or URL';
  static const String generate = 'Generate';
  static const String generatorHint = 'Type anything — URL, text, email...';
  static const String qrGenerated = 'QR Code Generated';
  static const String clearInput = 'Clear';

  // History
  static const String historyTitle = 'Scan History';
  static const String noHistory = 'No scans yet';
  static const String noHistorySubtitle = 'Start scanning QR codes and they\'ll appear here.';
  static const String clearHistory = 'Clear History';
  static const String clearHistoryConfirm = 'Clear all history?';
  static const String clearHistoryMessage =
      'This action cannot be undone. All scan history will be permanently deleted.';
  static const String confirmClear = 'Clear';
  static const String cancel = 'Cancel';

  // Actions
  static const String copy = 'Copy';
  static const String share = 'Share';
  static const String open = 'Open';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String openInBrowser = 'Open in Browser';
  static const String sendEmail = 'Send Email';
  static const String callNumber = 'Call';
  static const String sendSms = 'Send SMS';

  // Feedback
  static const String copiedToClipboard = 'Copied to clipboard';
  static const String cannotOpen = 'Cannot open this link';
  static const String savedToHistory = 'Saved to history';
  static const String deleted = 'Deleted';
  static const String errorOccurred = 'An error occurred';

  // QR types
  static const String typeURL = 'URL';
  static const String typeText = 'Text';
  static const String typeEmail = 'Email';
  static const String typeSMS = 'SMS';
  static const String typePhone = 'Phone';
  static const String typeWifi = 'Wi-Fi';
  static const String typeOther = 'Other';
}
