import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
  await ApiService.loadPersistedSession(); // daha önce giriş yapıldıysa hatırla
  // OneSignal başlatma bir sebeple başarısız olursa (izin reddi vb.) sessizce
  // atlanır, uygulamanın geri kalanını etkilemez.
  unawaited(NotificationService.initialize());
  runApp(const EadMobileApp());
}

class EadMobileApp extends StatelessWidget {
  const EadMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EAD Demir',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: ApiService.isLoggedIn ? const HomeDashboardScreen() : const LoginScreen(),
    );
  }
}
