import 'package:campusmate/utils/validators.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'cm_event.dart';
part 'cm_state.dart';

/*
1. Done: Create a Logout option
2. TODO: Create a forgot password option
*/

class CmBloc extends Bloc<CmEvent, CmState> {
  CmBloc() : super(CmInitial()) {
    final sbclient = Supabase.instance.client;

    on<PassToggleEvent>((event, emit) => emit(PassToggleState()));

    on<SignUpPressedEvent>((event, emit) async {
      final checkMsg = finalCheck(
        event.name,
        event.email,
        event.id,
        event.pass1,
        event.pass2,
      );

      if (checkMsg != null) {
        return emit(SignUpErrorState(checkMsg));
      }

      emit(SigningUpState());

      final AuthResponse resp;

      try {
        final data = await sbclient
            .from("emails")
            .select("email")
            .eq("email", event.email);
        if (data.isNotEmpty) {
          return emit(AccountExistsState());
        }
        resp = await sbclient.auth.signUp(
          email: event.email,
          password: event.pass1,
          data: {"sid": event.id, "name": event.name},
        );
      } on AuthWeakPasswordException catch (e) {
        return emit(SignUpErrorState(e.message));
      } on AuthApiException catch (e) {
        return emit(SignUpErrorState(e.message));
      } catch (e) {
        return emit(
          SignUpErrorState("An Unknown error Occurred. [${e.toString()}]"),
        );
      }

      if (resp.user == null) {
        return emit(SignUpErrorState("Could not create user object"));
      }

      if (resp.user!.emailConfirmedAt == null) {
        return emit(UnconfirmedEmailState(resp.user!.email!));
      }
    });

    on<OtpConfimationEvent>((event, emit) async {
      if (event.otp.isEmpty) {
        return emit(OtpErrorState("An OTP is a Required Value"));
      }
      try {
        await sbclient.auth.verifyOTP(
          type: event.otpType,
          email: event.email,
          token: event.otp,
        );
        if (event.otpType == OtpType.recovery) {
          return emit(OtpVerificationSuccessState());
        } else {
          await sbclient.from("emails").insert({
            "id": sbclient.auth.currentSession?.user.id,
            "email": event.email,
          });

          return emit(SignUpSuccessState());
        }
      } on AuthApiException catch (e) {
        return emit(OtpErrorState(e.message));
      } catch (e) {
        return emit(OtpErrorState(e.toString()));
      }
    });

    on<OtpTimerEndedEvent>((event, emit) => emit(OtpTimerEndedState()));

    on<OtpResendRequestedEvent>((event, emit) async {
      emit(OtpResendingState());
      try {
        if (event.otpType == OtpType.recovery) {
          await sbclient.auth.resetPasswordForEmail(event.email);
        } else {
          await sbclient.auth.resend(type: event.otpType, email: event.email);
        }
      } catch (e) {
        print(e.toString());
        return emit(OtpErrorState("An Error Occured!! ${e.toString()}"));
      }
      return emit(OtpResentState());
    });

    on<LoginRequestedEvent>((event, emit) async {
      if (event.email.isEmpty || event.pass.isEmpty) {
        return emit(
          LoginErrorState("Please fill out the required field correctly!!"),
        );
      }
      emit(LoggingInState());

      final AuthResponse resp;

      try {
        resp = await sbclient.auth.signInWithPassword(
          email: event.email,
          password: event.pass,
        );
      } on AuthApiException catch (e) {
        return emit(LoginErrorState(e.message));
      } on AuthException catch (e) {
        return emit(LoginErrorState(e.message));
      } catch (e) {
        return emit(LoginErrorState(e.toString()));
      }

      if (resp.user?.emailConfirmedAt == null) {
        return emit(UnconfirmedEmailState(event.email));
      }

      return emit(LoginSuccessState());
    });

    on<LogoutRequestedEvent>((event, emit) async {
      await sbclient.auth.signOut(scope: SignOutScope.global);
      return emit(LoggedOutState());
    });

    on<PasswordResetEvent>((event, emit) async {
      if (event.email.isEmpty) {
        return emit(
          PassResetErrorState("Email must be provided to reset password."),
        );
      }
      emit(PasswordResetSendingState());
      final resp = await sbclient
          .from("emails")
          .select()
          .eq("email", event.email);
      if (resp.isEmpty) {
        return emit(
          PassResetErrorState("No Account with this email exists!!!"),
        );
      }
      await sbclient.auth.resetPasswordForEmail(event.email);
      return emit(PassResetReqSentState(event.email));
    });

    on<SetPassEvent>((event, emit) async {
      final check1 = isValidPass(event.pass1);
      if (check1 != null) {
        return emit(SetPassErrorState(check1));
      }
      if (event.pass1 != event.pass2) {
        return emit(SetPassErrorState("Passwords do not match!!!"));
      }
      try {
        await sbclient.auth.updateUser(UserAttributes(password: event.pass1));
        await sbclient.auth.signOut(scope: SignOutScope.global);
      } on AuthApiException catch (e) {
        return emit(SetPassErrorState(e.message));
      }
      return emit(SetPassSuccessState());
    });
  }
}
