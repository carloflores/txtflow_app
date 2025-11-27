import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/storage_service.dart';
import 'providers/app_provider.dart';
import 'screens/dashboard_screen.dart';
import 'package:telephony/telephony.dart';
import 'services/api_service.dart';
import 'background_task.dart';
import 'background_message_handler.dart';
import 'utils/constants.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Storage
  final storage = StorageService();
  await storage.init();

  // Initialize Workmanager
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true, // TODO: Set to false in production
  );

  // Initialize Telephony Listener
  final telephony = Telephony.instance;
  await telephony.requestPhoneAndSmsPermissions;
  telephony.listenIncomingSms(
    onNewMessage: (SmsMessage message) async {
      final storage = StorageService();
      await storage.init();
      final api = ApiService(storage);
      
      final log = 'Received SMS from ${message.address}: ${message.body}';
      await storage.addLog(log);
      await storage.incrementReceivedCount();
      
      // Post to API
      await api.postMessage({
        'address': message.address,
        'body': message.body,
        'date': message.date,
      });
    },
    onBackgroundMessage: backgroundMessageHandler,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider(storage)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.primaryColor,
          brightness: Brightness.dark,
          surface: AppConstants.surfaceColor,
          background: AppConstants.backgroundColor,
        ),
        scaffoldBackgroundColor: AppConstants.backgroundColor,
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: AppConstants.surfaceColor,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
