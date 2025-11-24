import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repository/user_repository.dart';
import '../../bloc/login_bloc/bloc.dart';
import 'login_form.dart';

class LoginScreen extends StatelessWidget {
  final UserRepository repo;
  const LoginScreen({super.key, required this.repo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acceso')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: BlocProvider(
              create: (_) => LoginBloc(repo),
              child: const LoginForm(),
            ),
          ),
        ),
      ),
    );
  }
}
