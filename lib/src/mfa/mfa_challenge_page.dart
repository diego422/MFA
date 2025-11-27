import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MfaChallengePage extends StatefulWidget {
  final FirebaseAuthMultiFactorException mfaException;
  const MfaChallengePage({super.key, required this.mfaException});

  @override
  State<MfaChallengePage> createState() => _MfaChallengePageState();
}

class _MfaChallengePageState extends State<MfaChallengePage> {
  String? _verificationId;
  String _sms = '';
  String? _error;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    final resolver = widget.mfaException.resolver;
    final PhoneMultiFactorInfo hint =
        resolver.hints.whereType<PhoneMultiFactorInfo>().first;
    FirebaseAuth.instance.verifyPhoneNumber(
      multiFactorSession: resolver.session,
      multiFactorInfo: hint,
      verificationCompleted: (_) {},
      verificationFailed: (e) => setState(() => _error = e.message),
      codeSent: (id, _) => setState(() => _verificationId = id),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<void> _confirm() async {
    if (_verificationId == null || _sms.isEmpty) return;
    setState(() { _sending = true; _error = null; });
    try {
      final cred = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _sms,
      );
      final assertion = PhoneMultiFactorGenerator.getAssertion(cred);
      await widget.mfaException.resolver.resolveSignIn(assertion);
      if (mounted) Navigator.pop(context, true);
    } on FirebaseAuthException catch (e) {
      setState(() { _error = e.message; });
    } finally {
      setState(() { _sending = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MFA: Código SMS')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Ingrese el código enviado por SMS'),
          TextField(
            keyboardType: TextInputType.number,
            onChanged: (v) => _sms = v,
            decoration: const InputDecoration(labelText: 'Código'),
          ),
          const SizedBox(height: 12),
          if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: (_verificationId != null && !_sending) ? _confirm : null,
              child: Text(_sending ? 'Verificando...' : 'Confirmar'),
            ),
          )
        ]),
      ),
    );
  }
}
