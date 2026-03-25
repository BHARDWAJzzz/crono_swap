import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme.dart';
import 'features/skill_exchange/presentation/pages/auth_page.dart';
import 'features/skill_exchange/presentation/providers/auth_providers.dart';
import 'features/skill_exchange/presentation/pages/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    const ProviderScope(
      child: CronoSwapApp(),
    ),
  );
}

class CronoSwapApp extends ConsumerWidget {
  const CronoSwapApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Crono Swap',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: authState.when<Widget>(
        data: (user) => user != null ? const MainScreen() : const AuthPage(),
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
      ),
    );
  }
}
