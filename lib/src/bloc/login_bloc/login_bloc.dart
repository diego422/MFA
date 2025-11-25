import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../repository/user_repository.dart';
import '../../util/validators.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final UserRepository _repo;
  LoginBloc(this._repo) : super(LoginState.empty()) {
    on<EmailChanged>((e, emit) => emit(state.update(isEmailValid: Validators.isValidEmail(e.email))));
    on<PasswordChanged>((e, emit) => emit(state.update(isPasswordValid: Validators.isValidPassword(e.password))));
    on<LoginWithCredentialsPressed>(_onLogin);
  }

  Future<void> _onLogin(LoginWithCredentialsPressed e, Emitter<LoginState> emit) async {
    emit(LoginState.loading());
    try {
      await _repo.signInWithCredentials(e.email, e.password);
      emit(LoginState.success());
    } on FirebaseAuthMultiFactorException catch (ex) {
      emit(LoginState.mfaRequired(ex));
    } catch (_) {
      emit(LoginState.failure());
    }
  }
}