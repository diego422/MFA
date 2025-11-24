import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'src/ui/login/login_screen.dart';
import 'src/repository/user_repository.dart';
import 'src/mfa/mfa_enroll_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MFA Demo BLoC (SDK >=2.17)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const _Gate(),
    );
  }
}

class _Gate extends StatelessWidget {
  const _Gate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = snap.data;
        if (user == null) return LoginScreen(repo: UserRepository());
        return const HomeScreen();
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<int> _factorCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;
    try {
      final factors = await user.multiFactor.getEnrolledFactors();
      return factors.length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _sendEmailVerification(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await user.sendEmailVerification();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Correo de verificación enviado')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _refreshVerified(BuildContext context) async {
    await FirebaseAuth.instance.currentUser?.reload();
    final verified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(verified ? 'Correo verificado ✅' : 'Aún no verificado ❌')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final emailVerified = user?.emailVerified ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          IconButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'Bienvenido, ${user?.email ?? user?.uid}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),

          // Estado de correo
          Row(
            children: [
              Chip(
                label: Text(emailVerified ? 'Correo verificado' : 'Correo NO verificado'),
                avatar: Icon(
                  emailVerified ? Icons.verified : Icons.error_outline,
                  color: emailVerified ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () => _sendEmailVerification(context),
                child: const Text('Enviar verificación de correo'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => _refreshVerified(context),
                child: const Text('Ya verifiqué (refrescar)'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Estado 2FA
          FutureBuilder<int>(
            future: _factorCount(),
            builder: (context, snap) {
              final label = !snap.hasData
                  ? 'Estado 2FA: ...'
                  : 'Estado 2FA: ${snap.data! > 0 ? 'Inscrito' : 'No inscrito'}';
              return Text(label, style: Theme.of(context).textTheme.bodyLarge);
            },
          ),

          const SizedBox(height: 24),

          // Inscribir 2FA
          FilledButton.icon(
            onPressed: emailVerified
                ? () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MfaEnrollPage()),
                    )
                : null,
            icon: const Icon(Icons.phonelink_lock),
            label: const Text('Inscribir 2FA (SMS)'),
          ),
          if (!emailVerified) ...[
            const SizedBox(height: 8),
            const Text(
              'Debes verificar tu correo antes de inscribir el 2FA.',
              style: TextStyle(color: Colors.red),
            ),
          ],
        ]),
      ),
    );
  }
}
