import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../mfa/mfa_challenge_page.dart';
import '../../repository/user_repository.dart';
import '../../bloc/login_bloc/bloc.dart';
import 'login_button.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});
  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _email = TextEditingController();
  final _pass = TextEditingController();

  bool get isPopulated => _email.text.isNotEmpty && _pass.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<LoginBloc>();
    _email.addListener(() => bloc.add(EmailChanged(_email.text)));
    _pass.addListener(() => bloc.add(PasswordChanged(_pass.text)));
  }

  void _submit() {
    final bloc = context.read<LoginBloc>();
    bloc.add(LoginWithCredentialsPressed(email: _email.text.trim(), password: _pass.text));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoginBloc, LoginState>(
      listener: (context, state) async {
        if (state.isMfaRequired && state.mfaException != null) {
          final ok = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => MfaChallengePage(mfaException: state.mfaException!)),
          );
          if (ok == true) return;
        }
        if (state.isFailure) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fallo al iniciar sesión')));
        }
        if (state.isSubmitting) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresando...')));
        }
      },
      builder: (context, state) {
        final enabled = state.isEmailValid && state.isPasswordValid && isPopulated && !state.isSubmitting;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _email, decoration: InputDecoration(labelText: 'Correo', errorText: state.isEmailValid ? null : 'Correo inválido')),
            const SizedBox(height: 8),
            TextField(controller: _pass, decoration: InputDecoration(labelText: 'Contraseña', errorText: state.isPasswordValid ? null : 'Inválida'), obscureText: true),
            const SizedBox(height: 12),
            LoginButton(onPressed: enabled ? _submit : null),
          ],
        );
      },
    );
  }
}
