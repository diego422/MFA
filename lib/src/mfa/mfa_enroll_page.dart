import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MfaEnrollPage extends StatefulWidget {
  const MfaEnrollPage({super.key});
  @override
  State<MfaEnrollPage> createState() => _MfaEnrollPageState();
}

class _MfaEnrollPageState extends State<MfaEnrollPage> {
  final _phone = TextEditingController(text: '+50660000000');
  final _code = TextEditingController();

  String? _verificationId;
  String? _error;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    // Si el correo no está verificado, avisamos y volvemos.
    final verified = FirebaseAuth.instance.currentUser?.emailVerified ?? false;
    if (!verified) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debes verificar tu correo antes de inscribir 2FA')),
        );
        Navigator.pop(context);
      });
    }
  }

  Future<void> _sendCode() async {
    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _error = 'No hay usuario autenticado.';
          _sending = false;
        });
        return;
      }

      // Sesión MFA requerida para inscripción
      final session = await user.multiFactor.getSession();

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _phone.text.trim(),
        multiFactorSession: session,
        verificationCompleted: (PhoneAuthCredential cred) async {
          // En algunos casos (instant verification) llega aquí con el SMS resuelto.
          try {
            final assertion = PhoneMultiFactorGenerator.getAssertion(cred);
            await user.multiFactor.enroll(assertion, displayName: 'SMS');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('2FA (SMS) inscrito correctamente ✅')),
              );
              Navigator.pop(context, true);
            }
          } catch (e) {
            setState(() => _error = e.toString());
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _error = e.message);
        },
        codeSent: (String id, int? _) {
          setState(() => _verificationId = id);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Código enviado')),
          );
        },
        codeAutoRetrievalTimeout: (_) {},
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _sending = false);
    }
  }

  Future<void> _confirm() async {
    if (_verificationId == null || _code.text.isEmpty) return;

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final cred = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _code.text.trim(),
      );
      final assertion = PhoneMultiFactorGenerator.getAssertion(cred);
      await user.multiFactor.enroll(assertion, displayName: 'SMS');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('2FA (SMS) inscrito correctamente ✅')),
        );
        Navigator.pop(context, true);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canConfirm = _verificationId != null && !_sending && _code.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Inscribir 2FA (SMS)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Número (ej. +50660000000)'),
          const SizedBox(height: 6),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '+50660000000',
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _sending ? null : _sendCode,
            child: _sending ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Enviar código'),
          ),
          const SizedBox(height: 24),
          const Text('Código SMS'),
          const SizedBox(height: 6),
          TextField(
            controller: _code,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            onChanged: (_) => setState(() {}), // para habilitar/deshabilitar Confirmar
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: canConfirm ? _confirm : null,
            child: _sending ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Confirmar inscripción'),
          ),
          const SizedBox(height: 12),
          if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
        ]),
      ),
    );
  }
}
