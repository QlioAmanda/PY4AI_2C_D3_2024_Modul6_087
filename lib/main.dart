import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart'; 
import 'package:logbook_app_087/services/mongo_service.dart'; 
import 'package:logbook_app_087/features/onboarding/onboarding_view.dart';
import 'package:logbook_app_087/features/logbook/models/log_model.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Load Environment Variables
  await dotenv.load(fileName: ".env");

  // --- 2. INISIALISASI HIVE (LOCAL PERSISTENCE) ---
  await Hive.initFlutter();
  Hive.registerAdapter(LogModelAdapter()); 
  await Hive.openBox<LogModel>('offline_logs');
  await Hive.openBox('sync_queue'); // Box untuk menyimpan aksi offline (add, update, delete)
  // ------------------------------------------------

  // 3. Inisialisasi Koneksi Database (Cloud)
  final mongoService = MongoService();
  try {
    await mongoService.connect();
  } catch (e) {
    // ignore: avoid_print
    print("Error Koneksi di Main: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Logbook App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const OnboardingView(), 
    );
  }
}