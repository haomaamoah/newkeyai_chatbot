
import '../providers/homework.dart';
import '../providers/identifyeverything.dart';
import '../views/splashscreen/splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';


Future<void> main() async {
  // Initialize environment variables before running the app
  WidgetsFlutterBinding.ensureInitialized();
  // await dotenv.load(fileName: '.env');
  setUrlStrategy(const HashUrlStrategy());
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeworkSolutionProvider()),
        ChangeNotifierProvider(create: (_) => IdentifyEverythingProvider()),
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
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      home: SplashScreen(),
    );
  }
}