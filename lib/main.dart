import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.init();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const EChat());
}

class EChat extends StatelessWidget {
  const EChat({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(AppColors.backgroundDark),
          colorScheme: const ColorScheme.dark(
            primary: Color(AppColors.accent),
            surface: Color(AppColors.surfaceDark),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(AppColors.surfaceDark),
            elevation: 0,
          ),
          snackBarTheme: const SnackBarThemeData(
            backgroundColor: Color(AppColors.cardDark),
            contentTextStyle: TextStyle(color: Color(AppColors.textPrimary)),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
