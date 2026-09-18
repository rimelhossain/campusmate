import 'dart:io';

import 'package:campusmate/model/lost_and_found_item.dart';
import 'package:campusmate/model/student.dart';
import 'package:campusmate/utils/validators.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'cm_event.dart';
part 'cm_state.dart';

late Student student;

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
        if (kDebugMode) {
          print(e);
        }
        return emit(SignUpErrorState(e.message));
      } on AuthApiException catch (e) {
        if (kDebugMode) {
          print(e);
        }
        return emit(SignUpErrorState(e.message));
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
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
          await sbclient.from("users").insert({
            "id": sbclient.auth.currentUser!.id,
            "created_at": sbclient.auth.currentUser!.createdAt,
            "name": sbclient.auth.currentUser!.userMetadata!["name"],
            "student_id": sbclient.auth.currentUser!.userMetadata!["sid"],
          });

          student = Student(sbclient.auth.currentUser!.userMetadata!);

          return emit(SignUpSuccessState());
        }
      } on AuthApiException catch (e) {
        if (kDebugMode) {
          print(e);
        }
        return emit(OtpErrorState(e.message));
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
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
        if (kDebugMode) {
          print(e);
        }
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
        if (kDebugMode) {
          print(e);
        }
        return emit(LoginErrorState(e.message));
      } on AuthException catch (e) {
        if (kDebugMode) {
          print(e);
        }
        return emit(LoginErrorState(e.message));
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
        return emit(LoginErrorState(e.toString()));
      }

      if (resp.user?.emailConfirmedAt == null) {
        return emit(UnconfirmedEmailState(event.email));
      }

      student = Student(sbclient.auth.currentUser!.userMetadata!);

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
        if (kDebugMode) {
          print(e);
        }
        return emit(SetPassErrorState(e.message));
      }
      return emit(SetPassSuccessState());
    });

    on<PostTypeSelectedEvent>((event, emit) {
      String type = event.type;
      if (event.type == "lost") {
        type = "found";
      } else {
        type = "lost";
      }
      emit(PostTypeSelectedState(type));
    });
    on<TimePickedEvent>(
      (event, emit) => emit(TimePickedState(event.pickedTime)),
    );

    on<ImagePickedEvent>(
      (event, emit) => emit(PickedImageState(event.pickedImage)),
    );

    on<InputClearEvent>((event, emit) => emit(InputClearedState()));

    on<AddPostEvent>((event, emit) async {
      if ([
        event.title,
        event.description,
        event.location,
      ].any((s) => s.isEmpty)) {
        return emit(
          PostFailedState(
            "Please Fill out the Above informations correctly and try again",
          ),
        );
      }
      emit(PostingState());
      try {
        final insertedRow = await sbclient.from("posts").insert({
          "title": event.title,
          "desc": event.description,
          "location": event.location,
          "author": sbclient.auth.currentUser!.id,
          "lostOrFound": event.type,
        }).select();
        if (event.imageFile != null) {
          await sbclient.storage
              .from("lostAndFound")
              .upload(insertedRow.first['id'], event.imageFile!);
        }
        return emit(PostSuccessState());
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
        return emit(PostFailedState("An Error Occured!!!"));
      }
    });

    on<LoadItemsEvent>((event, emit) async {
      try {
        emit(ItemsLoadingState());
        final resp = await sbclient
            .from("posts")
            .select()
            .order("created_at", ascending: false);
        final items = resp.map((itemData) {
          final List<String> timeString = itemData["time"].split(":");
          return LostAndFoundItem(
            id: itemData["id"],
            createdAt: DateTime.parse(itemData["created_at"]),
            title: itemData["title"],
            description: itemData["desc"],
            isResolved: itemData["isResolved"],
            authorId: itemData["author"],
            type: itemData["lostOrFound"],
            location: itemData["location"],
            time: TimeOfDay(
              hour: int.parse(timeString.first),
              minute: int.parse(timeString[1]),
            ),
            imageProvider: NetworkImage(
              sbclient.storage
                  .from("lostAndFound")
                  .getPublicUrl(itemData["id"]),
            ),
          );
        }).toList();
        return emit(ItemLoadedState(items));
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
        return emit(ItemsLoadFailedState("Unknown Error occured!!!"));
      }
    });

    on<AddResponseEvent>((event, emit) async {
      try {
        await sbclient.from("comments").insert({
          "desc": event.desc,
          "author": sbclient.auth.currentUser!.id,
          "post": event.postId,
        });
        emit(AddResponseSuccessState());
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
        emit(AddResponseErrorState("Error!!!!"));
      }
    });

    on<LoadResponsesEvent>((event, emit) async {
      try {
        final resp = await sbclient
            .from("responses")
            .select("*")
            .eq("pid", event.postId);
        emit(LoadResponsesSuccessState(resp));
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
        emit(LoadResponsesErrorState("Something went wrong"));
      }
    });

    on<ResolvedRequestedEvent>((event, emit) async {
      if (event.post.authorId.compareTo(sbclient.auth.currentUser!.id) != 0) {
        return emit(ResolveErrorState("An Error occured!!"));
      }
      try {
        await event.post.resolve();
        return emit(ResolveSuccessState());
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
        return emit(ResolveErrorState("Unknown Error!!"));
      }
    });
  }
}
