import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'core/constants/app_theme.dart';
import 'data/datasources/local_datasource.dart';
import 'data/repositories/qr_repository_impl.dart';
import 'domain/usecases/get_scan_history.dart';
import 'domain/usecases/save_scan_result.dart';
import 'domain/usecases/delete_scan_result.dart';
import 'domain/usecases/clear_history.dart';
import 'presentation/providers/ad_provider.dart';
import 'presentation/providers/history_provider.dart';
import 'presentation/providers/qr_scanner_provider.dart';
import 'presentation/providers/qr_generator_provider.dart';
import 'presentation/pages/splash_page.dart';

Future<void> main() async {
  // Preserve the native splash until FlutterNativeSplash.remove() is called
  // inside SplashPage — this ensures a gapless handoff to the Flutter
  // animated splash (same dark background, same icon).
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // AdMob SDK 초기화 — runApp을 블로킹하지 않도록 await 없이 시작.
  // AdProvider 는 SDK 준비 전에도 로딩 상태를 안전하게 처리함.
  MobileAds.instance.initialize();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0A14), // AppColors.background 와 정확히 일치
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final prefs = await SharedPreferences.getInstance();

  final localDataSource = LocalDataSource(prefs);
  final repository = QrRepositoryImpl(localDataSource);

  final getScanHistory = GetScanHistory(repository);
  final saveScanResult = SaveScanResult(repository);
  final deleteScanResult = DeleteScanResult(repository);
  final clearHistory = ClearHistory(repository);

  runApp(
    QrScannerApp(
      getScanHistory: getScanHistory,
      saveScanResult: saveScanResult,
      deleteScanResult: deleteScanResult,
      clearHistory: clearHistory,
    ),
  );
}

class QrScannerApp extends StatelessWidget {
  final GetScanHistory getScanHistory;
  final SaveScanResult saveScanResult;
  final DeleteScanResult deleteScanResult;
  final ClearHistory clearHistory;

  const QrScannerApp({
    super.key,
    required this.getScanHistory,
    required this.saveScanResult,
    required this.deleteScanResult,
    required this.clearHistory,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // AdMob 광고 관리 (standalone)
        ChangeNotifierProvider(create: (_) => AdProvider()),
        ChangeNotifierProvider(
          create: (_) => HistoryProvider(
            getScanHistory: getScanHistory,
            saveScanResult: saveScanResult,
            deleteScanResult: deleteScanResult,
            clearHistory: clearHistory,
          ),
        ),
        // QrScannerProvider는 HistoryProvider 외 AdProvider도 필요
        ChangeNotifierProxyProvider2<HistoryProvider, AdProvider,
            QrScannerProvider>(
          create: (ctx) => QrScannerProvider(
            historyProvider: ctx.read<HistoryProvider>(),
            adProvider: ctx.read<AdProvider>(),
          ),
          update: (_, history, ad, scanner) =>
              scanner ??
              QrScannerProvider(historyProvider: history, adProvider: ad),
        ),
        ChangeNotifierProxyProvider<HistoryProvider, QrGeneratorProvider>(
          create: (ctx) => QrGeneratorProvider(
            historyProvider: ctx.read<HistoryProvider>(),
          ),
          update: (_, history, generator) =>
              generator ?? QrGeneratorProvider(historyProvider: history),
        ),
      ],
      child: MaterialApp(
        title: 'QR Scanner & Generator',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashPage(),
      ),
    );
  }
}

