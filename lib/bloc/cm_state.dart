part of 'cm_bloc.dart';

sealed class CmState {
  const CmState();
}

final class CmInitial extends CmState {
  const CmInitial();
}

final class PassToggleState extends CmState {
  const PassToggleState();
}

final class SignUpErrorState extends CmState {
  final String msg;

  const SignUpErrorState(this.msg);
}

final class SignUpSuccessState extends CmState {}

final class UnconfirmedEmailState extends CmState {
  final String email;
  const UnconfirmedEmailState(this.email);
}

final class OtpErrorState extends CmState {
  final String msg;
  const OtpErrorState(this.msg);
}

final class SigningUpState extends CmState {}

final class AccountExistsState extends CmState {}

final class OtpTimerEndedState extends CmState {}

final class OtpTimerResetState extends CmState {}

final class ConfirmingOtpState extends CmState {}

final class OtpResentState extends CmState {}

final class OtpResendingState extends CmState {}

final class LoginErrorState extends CmState {
  final String msg;
  const LoginErrorState(this.msg);
}

final class LoggingInState extends CmState {}

final class LoginSuccessState extends CmState {}

final class LoggedOutState extends CmState {}

final class PassResetErrorState extends CmState {
  final String msg;

  const PassResetErrorState(this.msg);
}

final class PasswordResetSendingState extends CmState {}

final class PassResetReqSentState extends CmState {
  final String email;
  const PassResetReqSentState(this.email);
}

final class OtpVerificationSuccessState extends CmState {}

final class SetPassErrorState extends CmState {
  final String msg;
  const SetPassErrorState(this.msg);
}

final class SetPassSuccessState extends CmState {}
