import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginState extends Equatable {
  final bool isEmailValid;
  final bool isPasswordValid;
  final bool isSubmitting;
  final bool isSuccess;
  final bool isFailure;
  final bool isMfaRequired;
  final FirebaseAuthMultiFactorException? mfaException;

  const LoginState({
    required this.isEmailValid,
    required this.isPasswordValid,
    required this.isSubmitting,
    required this.isSuccess,
    required this.isFailure,
    this.isMfaRequired = false,
    this.mfaException,
  });

  factory LoginState.empty() => const LoginState(
    isEmailValid: true,
    isPasswordValid: true,
    isSubmitting: false,
    isSuccess: false,
    isFailure: false,
    isMfaRequired: false,
  );

  factory LoginState.loading() => const LoginState(
    isEmailValid: true,
    isPasswordValid: true,
    isSubmitting: true,
    isSuccess: false,
    isFailure: false,
    isMfaRequired: false,
  );

  factory LoginState.failure() => const LoginState(
    isEmailValid: true,
    isPasswordValid: true,
    isSubmitting: false,
    isSuccess: false,
    isFailure: true,
    isMfaRequired: false,
  );

  factory LoginState.success() => const LoginState(
    isEmailValid: true,
    isPasswordValid: true,
    isSubmitting: false,
    isSuccess: true,
    isFailure: false,
    isMfaRequired: false,
  );

  factory LoginState.mfaRequired(FirebaseAuthMultiFactorException e) => LoginState(
    isEmailValid: true,
    isPasswordValid: true,
    isSubmitting: false,
    isSuccess: false,
    isFailure: false,
    isMfaRequired: true,
    mfaException: e,
  );

  LoginState update({bool? isEmailValid, bool? isPasswordValid}) => LoginState(
    isEmailValid: isEmailValid ?? this.isEmailValid,
    isPasswordValid: isPasswordValid ?? this.isPasswordValid,
    isSubmitting: false,
    isSuccess: false,
    isFailure: false,
  );

  @override
  List<Object?> get props => [isEmailValid, isPasswordValid, isSubmitting, isSuccess, isFailure, isMfaRequired, mfaException];
}