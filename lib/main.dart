import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';
import 'core/theme.dart';
import 'features/skill_exchange/presentation/pages/splash_screen.dart';
import 'features/skill_exchange/presentation/pages/auth_page.dart';
import 'features/skill_exchange/presentation/pages/main_screen.dart';
import 'features/skill_exchange/presentation/providers/auth_providers.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (initError, stack) {
    runApp(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: SingleChildScrollView(
            child: Text('Firebase Init Error:\n$initError\n$stack', style: const TextStyle(color: Colors.red)),
          ),
        ),
      ),
    );
    return;
  }
  
  try {
    // Only register background handler on non-web platforms
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }
    
    // Request permissions (optional here, but good practice)
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  } catch (e) {
    print('Firebase Messaging init failed (expected on some web environments): $e');
  }

  try {
    runApp(
      const ProviderScope(
        child: CronoSwapApp(),
      ),
    );
  } catch (e, stack) {
    runApp(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: SingleChildScrollView(
            child: Text('Global Error:\n$e\n$stack', style: const TextStyle(color: Colors.red)),
          ),
        ),
      ),
    );
  }
}


class CronoSwapApp extends ConsumerWidget {
  const CronoSwapApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Crono Swap',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          return const MainScreen();
        } else {
          return const AuthPage();
        }
      },
      loading: () => const SplashScreen(),
      error: (err, stack) => Scaffold(
        body: Center(child: Text('Error: $err')),
      ),
    );
  }
}
