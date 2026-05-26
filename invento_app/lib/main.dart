import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'core/constants/strings.dart';
import 'routes/app_routes.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/auth_service.dart';
import 'services/firebase_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.initialization});

  final Future<FirebaseBootstrapResult>? initialization;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppStrings.appName,
      theme: AppTheme.lightTheme,
      routes: AppRoutes.routes,
      home: AppBootstrap(initialization: initialization),
    );
  }
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key, this.initialization});

  final Future<FirebaseBootstrapResult>? initialization;

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  late final Future<FirebaseBootstrapResult> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = widget.initialization ?? FirebaseService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FirebaseBootstrapResult>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final result = snapshot.data;
        if (result == null || !result.isReady) {
          return FirebaseSetupScreen(message: result?.message);
        }

        return const AuthGate();
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == null) {
          return const LoginScreen();
        }

        return const HomeScreen();
      },
    );
  }
}

class FirebaseSetupScreen extends StatelessWidget {
  const FirebaseSetupScreen({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.appName,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.firebaseSetupTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      message ??
                          'Firebase is not available yet. Finish the Zeppo project setup '
                              'to enable login, Firestore, and batch tracking.',
                    ),
                    const SizedBox(height: 20),
                    const Text('Complete these steps before running Zeppo:'),
                    const SizedBox(height: 12),
                    const Text(
                      '1. Run FlutterFire configure for the platforms you want to support.',
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '2. Enable Email/Password Authentication in Firebase Authentication.',
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '3. Create a Firestore database in production or test mode.',
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '4. Rebuild the app so the latest Firebase config is loaded.',
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const _SetupReferenceScreen(),
                          ),
                        );
                      },
                      child: const Text('View data model'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SetupReferenceScreen extends StatelessWidget {
  const _SetupReferenceScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zeppo Firestore Shape')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          Text('users/{uid}'),
          SizedBox(height: 8),
          Text('- profile fields: email, displayName, role, createdAt'),
          SizedBox(height: 8),
          Text('users/{uid}/products/{productId}'),
          SizedBox(height: 8),
          Text('- master product data: name, sku, qrCode, unit, timestamps'),
          SizedBox(height: 8),
          Text('users/{uid}/batches/{batchId}'),
          SizedBox(height: 8),
          Text(
            '- batch data: productId, batchNumber, expiryDate, remainingQuantity, warehouseName, locationCode, source',
          ),
          SizedBox(height: 8),
          Text('users/{uid}/warehouses/{warehouseId}'),
          SizedBox(height: 8),
          Text('- warehouse data: name, locationCode, timestamps'),
        ],
      ),
    );
  }
}
