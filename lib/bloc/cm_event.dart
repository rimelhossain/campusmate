part of 'cm_bloc.dart';

sealed class CmEvent {
  const CmEvent();
}

final class PassToggleEvent extends CmEvent {
  const PassToggleEvent();
}

final class SignUpPressedEvent extends CmEvent {
  final String name;
  final String email;
  final String id;
  final String pass1;
  final String pass2;

  const SignUpPressedEvent(
    this.name,
    this.email,
    this.id,
    this.pass1,
    this.pass2,
  );
}

final class OtpConfimationEvent extends CmEvent {
  final String email;
  final String otp;
  final OtpType otpType;
  const OtpConfimationEvent(this.otp, this.email, this.otpType);
}

final class OtpTimerEndedEvent extends CmEvent {}

final class OtpResendRequestedEvent extends CmEvent {
  final String email;
  final OtpType otpType;
  const OtpResendRequestedEvent(this.email, this.otpType);
}

final class LoginRequestedEvent extends CmEvent {
  final String email;
  final String pass;
  const LoginRequestedEvent(this.email, this.pass);
}

final class LogoutRequestedEvent extends CmEvent {}

final class PasswordResetEvent extends CmEvent {
  final String email;
  const PasswordResetEvent(this.email);
}

final class SetPassEvent extends CmEvent {
  final String pass1;
  final String pass2;

  const SetPassEvent(this.pass1, this.pass2);
}
