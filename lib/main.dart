import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_colors.dart';
import 'core/widgets/offline_banner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Boli App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.backgroundDark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
          surface: AppColors.surfaceLight,
        ),
        useMaterial3: true,
      ),
      builder: (context, child) {
        return Container(
          color: Colors.black, // Fond du navigateur
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24), // Bordure style iPhone
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430, maxHeight: 932), // Dimensions max d'un smartphone
                child: Container(
                  color: AppColors.backgroundDark,
                  child: child != null ? OfflineBannerWrapper(child: child) : null,
                ),
              ),
            ),
          ),
        );
      },
      routerConfig: router,
    );
  }
}
