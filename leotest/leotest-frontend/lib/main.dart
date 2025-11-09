import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:leotest/views/login_view.dart';
import 'package:leotest/views/select_profile_view.dart';
import 'package:leotest/views/home_view.dart';
import 'package:leotest/models/perfil.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    print('API BASE: ${dotenv.env['API_BASE']}');
  } catch (e) {
    print('Error al cargar .env: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color accentColor = Color.fromARGB(255, 255, 166, 0);
    const Color darkBackground = Color.fromARGB(255, 3, 0, 12);

    final ColorScheme customColorScheme = ColorScheme.dark(
      primary: accentColor,
      secondary: accentColor,
      background: darkBackground,
      surface: const Color.fromARGB(255, 15, 10, 30),
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'LeoTest App',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: accentColor,
        colorScheme: customColorScheme,
        scaffoldBackgroundColor: darkBackground,
        useMaterial3: true,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
          titleMedium: TextStyle(color: Colors.white),
          labelLarge: TextStyle(color: Colors.white70),
        ),
      ),
      // Vista inicial
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginView(),
        '/selectProfile': (context) => const SelectProfileView(),
      },
    );
  }
}
