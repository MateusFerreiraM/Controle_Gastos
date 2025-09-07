import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_fonts/google_fonts.dart';

import 'firebase_options.dart';
import 'pages/auth_wrapper.dart';
import 'app_colors.dart';

enum TipoTransacao { Entrada, Saida }

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('pt_BR', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return MaterialApp(
      title: 'Controle de Gastos',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.fundo,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaria,
          brightness: Brightness.light,
          primary: AppColors.primaria,
          secondary: AppColors.secundaria,
          error: AppColors.saida,
          surface: AppColors.card,
        ),
        textTheme: GoogleFonts.latoTextTheme(textTheme).copyWith(
          bodyMedium: GoogleFonts.lato(color: AppColors.textoPrincipal),
          bodySmall: GoogleFonts.lato(color: AppColors.textoSecundario),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primaria,
          foregroundColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          color: AppColors.card,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaria,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primaria,
          foregroundColor: Colors.white,
        ),
      ),
      home: AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}