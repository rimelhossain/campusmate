import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_events.dart';
import 'app_states.dart';
import '../utils/push_notification_service.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc(this._client, this._preferences) : super(const AppState()) {
    on<RestoreSessionRequested>(_restoreSession);
    on<SessionChanged>((event, emit) => emit(state.copyWith(user: event.user, clearUser: event.user == null)));
    on<SignInRequested>(_signIn);
    on<SignUpRequested>(_signUp);
    on<VerifySignupOtpRequested>(_verifyOtp);
    on<ResendSignupOtpRequested>(_resendOtp);
    on<PasswordResetOtpRequested>(_requestPasswordReset);
    on<PasswordRecoveryOtpResent>(_resendPasswordRecoveryOtp);
    on<PasswordRecoveryOtpVerified>(_verifyPasswordRecoveryOtp);
    on<RecoveryPasswordUpdated>(_updateRecoveryPassword);
    on<ProfileLoadRequested>(_loadProfile);
    on<ProfileUpdateRequested>(_updateProfile);
    on<SignOutRequested>(_signOut);
    on<ThemeModeChanged>(_changeThemeMode);
    on<MarketplacePostsLoadRequested>(_loadMarketplacePosts);
    on<MarketplacePostCreateRequested>(_createMarketplacePost);
    on<MarketplacePostSoldOutChanged>(_changeMarketplacePostSoldStatus);
    on<MarketplaceCommentsLoadRequested>(_loadMarketplaceComments);
    on<MarketplaceCommentCreateRequested>(_createMarketplaceComment);
    on<LostFoundPostsLoadRequested>(_loadLostFoundPosts);
    on<LostFoundPostCreateRequested>(_createLostFoundPost);
    on<LostFoundPostResolvedChanged>(_changeLostFoundResolved);
    on<LostFoundResponsesLoadRequested>(_loadLostFoundResponses);
    on<LostFoundResponseCreateRequested>(_createLostFoundResponse);
    on<StudyHelpPostsLoadRequested>(_loadStudyHelpPosts);
    on<StudyHelpPostCreateRequested>(_createStudyHelpPost);
    on<StudyHelpPostSolvedRequested>(_solveStudyHelpPost);
    on<StudyHelpChatsLoadRequested>(_loadStudyHelpChats);
    on<StudyHelpChatOpenRequested>(_openStudyHelpChat);
    on<StudyHelpChatMessagesWatchRequested>(_watchStudyHelpMessages);
    on<StudyHelpChatMessagesReceived>(_studyHelpMessagesReceived);
    on<StudyHelpChatMessagesFailed>(_studyHelpMessagesFailed);
    on<StudyHelpChatMessagesStopRequested>((event, emit) async {
      await _studyHelpMessageSubscription?.cancel();
      _studyHelpMessageSubscription = null;
      emit(state.copyWith(clearStudyHelpMessagesForChat: true));
    });
    on<StudyHelpMessageSendRequested>(_sendStudyHelpMessage);
    on<StudyHelpChatCloseRequested>(_closeStudyHelpChat);
    on<AiQuizGenerateRequested>(_generateAiQuiz);
    on<AiQuizAnswerSelected>((event, emit) {
      if (event.questionIndex < 0 ||
          event.questionIndex >= state.quizAnswers.length ||
          event.optionIndex < 0 ||
          event.optionIndex >= 4) {
        return;
      }
      final answers = List<int?>.from(state.quizAnswers);
      answers[event.questionIndex] = event.optionIndex;
      emit(state.copyWith(quizAnswers: answers, clearError: true));
    });
    on<AiQuizSessionCleared>((event, emit) =>
        emit(state.copyWith(clearQuizSession: true, clearError: true)));
    on<FreshersFaqsLoadRequested>(_loadFreshersFaqs);
    on<FreshersQuestionsLoadRequested>(_loadFreshersQuestions);
    on<FreshersQuestionCreateRequested>(_createFreshersQuestion);
    on<FreshersAnswersLoadRequested>(_loadFreshersAnswers);
    on<FreshersAnswerCreateRequested>(_createFreshersAnswer);
    on<FreshersBestAnswerChangedRequested>(_changeFreshersBestAnswer);
  }
  final SupabaseClient _client;
  final SharedPreferences _preferences;
  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _studyHelpMessageSubscription;

  Future<void> _restoreSession(RestoreSessionRequested event, Emitter<AppState> emit) async {
    final emails = _preferences.getStringList('used_emails') ?? const <String>[];
    final savedThemeMode = _preferences.getString('theme_mode');
    final themeMode = ThemeMode.values.where((mode) => mode.name == savedThemeMode).firstOrNull ?? ThemeMode.light;
    emit(state.copyWith(user: _client.auth.currentUser, isRestoring: false, hasUsedEmail: emails.isNotEmpty, lastUsedEmail: emails.isEmpty ? null : emails.last, themeMode: themeMode));
    await _authSubscription?.cancel();
    _authSubscription = _client.auth.onAuthStateChange.listen((data) => add(SessionChanged(data.session?.user)));
  }
  Future<void> _changeThemeMode(ThemeModeChanged event, Emitter<AppState> emit) async {
    emit(state.copyWith(themeMode: event.themeMode));
    await _preferences.setString('theme_mode', event.themeMode.name);
  }
  Future<void> _rememberEmail(String email, Emitter<AppState> emit) async {
    final emails = _preferences.getStringList('used_emails') ?? <String>[];
    final normalized = email.trim().toLowerCase();
    if (!emails.contains(normalized)) emails.add(normalized);
    await _preferences.setStringList('used_emails', emails);
    emit(state.copyWith(hasUsedEmail: true, lastUsedEmail: normalized));
  }
  Future<void> _signIn(SignInRequested event, Emitter<AppState> emit) async {
    _begin(emit, AppAction.signIn);
    try {
      final response = await _client.auth.signInWithPassword(email: event.email.trim(), password: event.password);
      if (response.user?.emailConfirmedAt == null) { await _client.auth.signOut(); throw const AuthException('Verify your email with the code we sent before signing in.'); }
      await _rememberEmail(event.email, emit);
      _succeed(emit, AppAction.signIn, user: response.user);
    } catch (error) { _fail(emit, AppAction.signIn, error); }
  }
  Future<void> _signUp(SignUpRequested event, Emitter<AppState> emit) async {
    _begin(emit, AppAction.signUp);
    try {
      final response = await _client.auth.signUp(
        email: event.email.trim(),
        password: event.password,
        data: {
          'full_name': event.fullName.trim(),
          'student_id': event.studentId.trim(),
        },
      );
      if (response.user?.identities?.isEmpty ?? false) {
        _fail(
          emit,
          AppAction.signUp,
          const AuthException('Account already Exists'),
        );
        return;
      }
      await _rememberEmail(event.email, emit);
      _succeed(emit, AppAction.signUp);
    } catch (error) {
      final isExistingAccount = error is AuthException &&
          (error.message.toLowerCase().contains('already registered') ||
              error.message.toLowerCase().contains('already exists') ||
              error.message.toLowerCase().contains('already in use'));
      _fail(
        emit,
        AppAction.signUp,
        isExistingAccount
            ? const AuthException('Account already Exists')
            : error,
      );
    }
  }
  Future<void> _verifyOtp(VerifySignupOtpRequested event, Emitter<AppState> emit) async {
    _begin(emit, AppAction.verifyOtp);
    try {
      final response = await _client.auth.verifyOTP(email: event.email.trim(), token: event.token.trim(), type: OtpType.signup);
      _succeed(emit, AppAction.verifyOtp, user: response.user);
    } catch (error) { _fail(emit, AppAction.verifyOtp, error); }
  }
  Future<void> _resendOtp(ResendSignupOtpRequested event, Emitter<AppState> emit) async {
    _begin(emit, AppAction.resendOtp);
    try { await _client.auth.resend(type: OtpType.signup, email: event.email.trim()); _succeed(emit, AppAction.resendOtp); }
    catch (error) { _fail(emit, AppAction.resendOtp, error); }
  }
  Future<void> _requestPasswordReset(
    PasswordResetOtpRequested event,
    Emitter<AppState> emit,
  ) async {
    _begin(emit, AppAction.requestPasswordReset);
    try {
      await _client.auth.resetPasswordForEmail(event.email.trim());
      _succeed(emit, AppAction.requestPasswordReset);
    } catch (error) {
      _fail(emit, AppAction.requestPasswordReset, error);
    }
  }

  Future<void> _resendPasswordRecoveryOtp(
    PasswordRecoveryOtpResent event,
    Emitter<AppState> emit,
  ) async {
    _begin(emit, AppAction.resendPasswordRecoveryOtp);
    try {
      await _client.auth.resetPasswordForEmail(event.email.trim());
      _succeed(emit, AppAction.resendPasswordRecoveryOtp);
    } catch (error) {
      _fail(emit, AppAction.resendPasswordRecoveryOtp, error);
    }
  }

  Future<void> _verifyPasswordRecoveryOtp(
    PasswordRecoveryOtpVerified event,
    Emitter<AppState> emit,
  ) async {
    _begin(emit, AppAction.verifyPasswordRecoveryOtp);
    try {
      final response = await _client.auth.verifyOTP(
        email: event.email.trim(),
        token: event.token.trim(),
        type: OtpType.recovery,
      );
      _succeed(
        emit,
        AppAction.verifyPasswordRecoveryOtp,
        user: response.user,
      );
    } catch (error) {
      _fail(emit, AppAction.verifyPasswordRecoveryOtp, error);
    }
  }

  Future<void> _updateRecoveryPassword(
    RecoveryPasswordUpdated event,
    Emitter<AppState> emit,
  ) async {
    _begin(emit, AppAction.updatePassword);
    try {
      await _client.auth.updateUser(UserAttributes(password: event.password));
      await _client.auth.signOut(scope: SignOutScope.global);
      _succeed(emit, AppAction.updatePassword, clearUser: true);
    } catch (error) {
      _fail(emit, AppAction.updatePassword, error);
    }
  }
  Future<void> _loadProfile(ProfileLoadRequested event, Emitter<AppState> emit) async {
    _begin(emit, AppAction.loadProfile);
    try {
      final user = _client.auth.currentUser;
      final row = user == null ? null : await _client.from('campusmate_profiles').select().eq('user_id', user.id).maybeSingle();
      emit(state.copyWith(profile: row, clearProfile: row == null, isBusy: false, action: AppAction.loadProfile, actionStatus: AppActionStatus.success, clearError: true));
    } catch (error) { _fail(emit, AppAction.loadProfile, error); }
  }
  Future<void> _updateProfile(ProfileUpdateRequested event, Emitter<AppState> emit) async {
    _begin(emit, AppAction.updateProfile);
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw const AuthException('Your session has expired. Please sign in again.');
      await _client.from('campusmate_profiles').update({'full_name': event.fullName.trim(), 'student_id': event.studentId.trim(), 'avatar_path': event.avatarPath, 'updated_at': DateTime.now().toIso8601String()}).eq('user_id', user.id);
      await _client.auth.updateUser(UserAttributes(data: {'full_name': event.fullName.trim(), if (event.avatarPath != null) 'avatar_path': event.avatarPath}));
      final row = await _client.from('campusmate_profiles').select().eq('user_id', user.id).maybeSingle();
      _succeed(emit, AppAction.updateProfile, user: _client.auth.currentUser, profile: row);
    } catch (error) { _fail(emit, AppAction.updateProfile, error); }
  }
  Future<void> _signOut(SignOutRequested event, Emitter<AppState> emit) async {
    _begin(emit, AppAction.signOut);
    try {
      try {
        await PushNotificationService.unregisterCurrentDevice();
      } catch (_) {
        // A temporary network failure should not prevent signing out.
      }
      await _client.auth.signOut(scope: SignOutScope.global);
      _succeed(emit, AppAction.signOut, clearUser: true);
    }
    catch (error) { _fail(emit, AppAction.signOut, error); }
  }
  Future<void> _loadMarketplacePosts(MarketplacePostsLoadRequested event, Emitter<AppState> emit) async {
    _begin(emit, AppAction.loadMarketplacePosts);
    try {
      final rows = await _client.from('marketplace_posts').select().order('created_at', ascending: false);
      emit(state.copyWith(marketplacePosts: List<Map<String, dynamic>>.from(rows), isBusy: false, action: AppAction.loadMarketplacePosts, actionStatus: AppActionStatus.success, clearError: true));
    } catch (error) {
      _fail(emit, AppAction.loadMarketplacePosts, error);
    }
  }
  Future<void> _createMarketplacePost(MarketplacePostCreateRequested event, Emitter<AppState> emit) async {
    _begin(emit, AppAction.createMarketplacePost);
    final uploadedPaths = <String>[];
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw const AuthException('Please sign in before posting an item.');
      final postKey = DateTime.now().microsecondsSinceEpoch.toString();
      final storage = _client.storage.from('marketplace-images');
      for (var index = 0; index < event.images.length; index++) {
        final image = event.images[index];
        final extension = image.name.contains('.') ? image.name.split('.').last.toLowerCase() : 'jpg';
        final path = '${user.id}/$postKey-$index.$extension';
        await storage.upload(path, File(image.path), fileOptions: const FileOptions(upsert: false));
        uploadedPaths.add(path);
      }
      await _client.from('marketplace_posts').insert({
        'seller_id': user.id,
        'seller_name': (user.userMetadata?['full_name'] as String?)?.trim() ?? 'UIU student',
        'title': event.title.trim(),
        'category': event.category,
        'description': event.description.trim(),
        'price_bdt': event.price,
        'is_price_fixed': event.isPriceFixed,
        'image_paths': uploadedPaths,
      });
      emit(state.copyWith(isBusy: false, action: AppAction.createMarketplacePost, actionStatus: AppActionStatus.success, clearError: true));
    } catch (error) {
      _fail(emit, AppAction.createMarketplacePost, error);
      if (uploadedPaths.isNotEmpty) {
        try { await _client.storage.from('marketplace-images').remove(uploadedPaths); } catch (_) {}
      }
    }
  }
  Future<void> _changeMarketplacePostSoldStatus(MarketplacePostSoldOutChanged event, Emitter<AppState> emit) async {
    _begin(emit, AppAction.updateMarketplacePost);
    try {
      final updatedRow = await _client
          .from('marketplace_posts')
          .update({
            'is_sold_out': event.isSoldOut,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', event.postId)
          .select()
          .maybeSingle();
      if (updatedRow == null) {
        throw const AuthException('You can only update your own listings.');
      }
      final updatedPost = Map<String, dynamic>.from(updatedRow);
      final updatedPosts = state.marketplacePosts
          .map((post) => post['id'] == event.postId ? updatedPost : post)
          .toList(growable: false);
      emit(state.copyWith(
        marketplacePosts: updatedPosts,
        isBusy: false,
        action: AppAction.updateMarketplacePost,
        actionStatus: AppActionStatus.success,
        clearError: true,
      ));
    } catch (error) {
      _fail(emit, AppAction.updateMarketplacePost, error);
    }
  }
  Future<void> _loadMarketplaceComments(MarketplaceCommentsLoadRequested event, Emitter<AppState> emit) async {
    _begin(emit, AppAction.loadMarketplaceComments);
    try {
      final rows = await _client
          .from('marketplace_comments')
          .select()
          .eq('post_id', event.postId)
          .order('created_at');
      emit(state.copyWith(
        marketplaceComments: List<Map<String, dynamic>>.from(rows),
        commentsForPostId: event.postId,
        isBusy: false,
        action: AppAction.loadMarketplaceComments,
        actionStatus: AppActionStatus.success,
        clearError: true,
      ));
    } catch (error) {
      _fail(emit, AppAction.loadMarketplaceComments, error);
    }
  }
  Future<void> _createMarketplaceComment(MarketplaceCommentCreateRequested event, Emitter<AppState> emit) async {
    _begin(emit, AppAction.createMarketplaceComment);
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw const AuthException('Please sign in to respond.');
      final displayName = (user.userMetadata?['full_name'] as String?)?.trim();
      final row = await _client.from('marketplace_comments').insert({
        'post_id': event.postId,
        'user_id': user.id,
        'user_name': displayName == null || displayName.isEmpty
            ? 'UIU student'
            : displayName,
        'body': event.body.trim(),
      }).select().single();
      final comments = state.commentsForPostId == event.postId
          ? [...state.marketplaceComments, Map<String, dynamic>.from(row)]
          : state.marketplaceComments;
      emit(state.copyWith(
        marketplaceComments: comments,
        isBusy: false,
        action: AppAction.createMarketplaceComment,
        actionStatus: AppActionStatus.success,
        clearError: true,
      ));
    } catch (error) {
      _fail(emit, AppAction.createMarketplaceComment, error);
    }
  }
  Future<void> _loadLostFoundPosts(LostFoundPostsLoadRequested event, Emitter<AppState> emit) async {
    _begin(emit, AppAction.loadLostFoundPosts);
    try {
      final rows = await _client.from('lost_found_posts').select().order('created_at', ascending: false);
      emit(state.copyWith(lostFoundPosts: List<Map<String, dynamic>>.from(rows), isBusy: false, action: AppAction.loadLostFoundPosts, actionStatus: AppActionStatus.success, clearError: true));
    } catch (error) { _fail(emit, AppAction.loadLostFoundPosts, error); }
  }
  Future<void> _createLostFoundPost(LostFoundPostCreateRequested event, Emitter<AppState> emit) async {
    _begin(emit, AppAction.createLostFoundPost);
    final uploadedPaths = <String>[];
    final cleanupPaths = <String>[];
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw const AuthException('Please sign in before posting.');
      final postKey = DateTime.now().microsecondsSinceEpoch.toString();
      final storage = _client.storage.from('lost-found-images');
      String? authorAvatarPath;
      final profileAvatarPath = await _client.from('campusmate_profiles').select('avatar_path').eq('user_id', user.id).maybeSingle();
      final privateAvatarPath = profileAvatarPath?['avatar_path'] as String?;
      if (privateAvatarPath != null && privateAvatarPath.isNotEmpty) {
        try {
          final extension = privateAvatarPath.contains('.') ? privateAvatarPath.split('.').last.toLowerCase() : 'jpg';
          final avatarCopy = '${user.id}/$postKey-avatar.$extension';
          final avatarBytes = await _client.storage.from('profile-avatars').download(privateAvatarPath);
          final contentType = switch (extension) { 'png' => 'image/png', 'webp' => 'image/webp', _ => 'image/jpeg' };
          await storage.uploadBinary(avatarCopy, avatarBytes, fileOptions: FileOptions(contentType: contentType, upsert: false));
          authorAvatarPath = avatarCopy;
          cleanupPaths.add(avatarCopy);
        } catch (_) {
          // Keep the post available even if an existing profile photo cannot be copied.
        }
      }
      for (var index = 0; index < event.images.length; index++) {
        final image = event.images[index];
        final extension = image.name.contains('.') ? image.name.split('.').last.toLowerCase() : 'jpg';
        final path = '${user.id}/$postKey-$index.$extension';
        await storage.upload(path, File(image.path), fileOptions: const FileOptions(upsert: false));
        uploadedPaths.add(path);
        cleanupPaths.add(path);
      }
      await _client.from('lost_found_posts').insert({
        'author_id': user.id,
        'author_avatar_path': authorAvatarPath,
        'title': event.title.trim(),
        'post_type': event.postType,
        'description': event.description.trim(),
        'location': event.location.trim(),
        'occurred_at': event.occurredAt.toUtc().toIso8601String(),
        'image_paths': uploadedPaths,
      });
      emit(state.copyWith(isBusy: false, action: AppAction.createLostFoundPost, actionStatus: AppActionStatus.success, clearError: true));
    } catch (error) {
      _fail(emit, AppAction.createLostFoundPost, error);
      if (cleanupPaths.isNotEmpty) {
        try { await _client.storage.from('lost-found-images').remove(cleanupPaths); } catch (_) {}
      }
    }
  }
  Future<void> _changeLostFoundResolved(LostFoundPostResolvedChanged event, Emitter<AppState> emit) async {
    _begin(emit, AppAction.updateLostFoundPost);
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw const AuthException('Your session has expired. Please sign in again.');
      final row = await _client.from('lost_found_posts').update({'is_resolved': event.isResolved, 'updated_at': DateTime.now().toUtc().toIso8601String()}).eq('id', event.postId).eq('author_id', user.id).select().maybeSingle();
      if (row == null) throw const AuthException('Only the post author can mark this post resolved.');
      final updated = Map<String, dynamic>.from(row);
      emit(state.copyWith(lostFoundPosts: state.lostFoundPosts.map((post) => post['id'] == event.postId ? updated : post).toList(growable: false), isBusy: false, action: AppAction.updateLostFoundPost, actionStatus: AppActionStatus.success, clearError: true));
    } catch (error) { _fail(emit, AppAction.updateLostFoundPost, error); }
  }
  Future<void> _loadLostFoundResponses(LostFoundResponsesLoadRequested event, Emitter<AppState> emit) async {
    _begin(emit, AppAction.loadLostFoundResponses);
    try {
      final rows = await _client.from('lost_found_responses').select().eq('post_id', event.postId).order('created_at');
      emit(state.copyWith(lostFoundResponses: List<Map<String, dynamic>>.from(rows), lostFoundResponsesForPostId: event.postId, isBusy: false, action: AppAction.loadLostFoundResponses, actionStatus: AppActionStatus.success, clearError: true));
    } catch (error) { _fail(emit, AppAction.loadLostFoundResponses, error); }
  }
  Future<void> _createLostFoundResponse(LostFoundResponseCreateRequested event, Emitter<AppState> emit) async {
    _begin(emit, AppAction.createLostFoundResponse);
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw const AuthException('Please sign in to respond.');
      final displayName = (user.userMetadata?['full_name'] as String?)?.trim();
      final row = await _client.from('lost_found_responses').insert({'post_id': event.postId, 'user_id': user.id, 'user_name': displayName == null || displayName.isEmpty ? 'UIU student' : displayName, 'body': event.body.trim()}).select().single();
      final responses = state.lostFoundResponsesForPostId == event.postId ? [...state.lostFoundResponses, Map<String, dynamic>.from(row)] : state.lostFoundResponses;
      emit(state.copyWith(lostFoundResponses: responses, isBusy: false, action: AppAction.createLostFoundResponse, actionStatus: AppActionStatus.success, clearError: true));
    } catch (error) { _fail(emit, AppAction.createLostFoundResponse, error); }
  }
  Future<void> _loadStudyHelpPosts(StudyHelpPostsLoadRequested event, Emitter<AppState> emit) async {
    _begin(emit, AppAction.loadStudyHelpPosts);
    try {
      final rows = await _client.from('study_help_posts').select().order('created_at', ascending: false);
      emit(state.copyWith(studyHelpPosts: List<Map<String, dynamic>>.from(rows), isBusy: false, action: AppAction.loadStudyHelpPosts, actionStatus: AppActionStatus.success, clearError: true));
    } catch (error) { _fail(emit, AppAction.loadStudyHelpPosts, error); }
  }

  Future<void> _createStudyHelpPost(StudyHelpPostCreateRequested event, Emitter<AppState> emit) async {
    _begin(emit, AppAction.createStudyHelpPost);
    final imagePaths = <String>[];
    final cleanupPaths = <String>[];
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw const AuthException('Please sign in before asking for help.');
      final postKey = DateTime.now().microsecondsSinceEpoch.toString();
      final storage = _client.storage.from('study-help-media');
      String? authorAvatarPath;
      final profile = await _client.from('campusmate_profiles').select('avatar_path').eq('user_id', user.id).maybeSingle();
      final privateAvatarPath = profile?['avatar_path'] as String?;
      if (privateAvatarPath != null && privateAvatarPath.isNotEmpty) {
        try {
          final extension = privateAvatarPath.contains('.') ? privateAvatarPath.split('.').last.toLowerCase() : 'jpg';
          final path = '${user.id}/$postKey-avatar.$extension';
          final bytes = await _client.storage.from('profile-avatars').download(privateAvatarPath);
          await storage.uploadBinary(path, bytes, fileOptions: FileOptions(contentType: _imageContentType(extension), upsert: false));
          authorAvatarPath = path;
          cleanupPaths.add(path);
        } catch (_) {
          // The avatar is optional; do not block a help post if it cannot be copied.
        }
      }
      for (var index = 0; index < event.images.length; index++) {
        final image = event.images[index];
        final extension = image.name.contains('.') ? image.name.split('.').last.toLowerCase() : 'jpg';
        final path = '${user.id}/$postKey-$index.$extension';
        await storage.upload(path, File(image.path), fileOptions: const FileOptions(upsert: false));
        imagePaths.add(path);
        cleanupPaths.add(path);
      }
      await _client.from('study_help_posts').insert({
        'author_id': user.id,
        'author_avatar_path': authorAvatarPath,
        'course_name': event.courseName.trim(),
        'topic_name': event.topicName.trim(),
        'description': event.description.trim(),
        'image_paths': imagePaths,
      });
      emit(state.copyWith(isBusy: false, action: AppAction.createStudyHelpPost, actionStatus: AppActionStatus.success, clearError: true));
    } catch (error) {
      _fail(emit, AppAction.createStudyHelpPost, error);
      if (cleanupPaths.isNotEmpty) {
        try { await _client.storage.from('study-help-media').remove(cleanupPaths); } catch (_) {}
      }
    }
  }

  Future<void> _solveStudyHelpPost(StudyHelpPostSolvedRequested event, Emitter<AppState> emit) async {
    _begin(emit, AppAction.updateStudyHelpPost);
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw const AuthException('Your session has expired. Please sign in again.');
      final row = await _client.from('study_help_posts').update({'is_solved': true, 'updated_at': DateTime.now().toUtc().toIso8601String()}).eq('id', event.postId).eq('author_id', user.id).select().maybeSingle();
      if (row == null) throw const AuthException('Only the post author can mark it solved.');
      final updated = Map<String, dynamic>.from(row);
      emit(state.copyWith(studyHelpPosts: state.studyHelpPosts.map((post) => post['id'] == event.postId ? updated : post).toList(growable: false), isBusy: false, action: AppAction.updateStudyHelpPost, actionStatus: AppActionStatus.success, clearError: true));
    } catch (error) { _fail(emit, AppAction.updateStudyHelpPost, error); }
  }

  Future<void> _loadStudyHelpChats(StudyHelpChatsLoadRequested event, Emitter<AppState> emit) async {
    _begin(emit, AppAction.loadStudyHelpChats);
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw const AuthException('Please sign in to view chats.');
      final chatRows = await _client.from('study_help_chats').select().order('updated_at', ascending: false);
      final chats = List<Map<String, dynamic>>.from(chatRows);
      if (chats.isEmpty) {
        emit(state.copyWith(studyHelpChats: const [], isBusy: false, action: AppAction.loadStudyHelpChats, actionStatus: AppActionStatus.success, clearError: true));
        return;
      }
      final chatIds = chats.map((chat) => chat['id'] as String).toList(growable: false);
      final postIds = chats.map((chat) => chat['post_id'] as String).toSet().toList(growable: false);
      final messageRows = await _client.from('study_help_messages').select().inFilter('chat_id', chatIds).order('created_at', ascending: false);
      final postRows = await _client.from('study_help_posts').select().inFilter('id', postIds);
      final latestMessages = <String, Map<String, dynamic>>{};
      for (final message in List<Map<String, dynamic>>.from(messageRows)) {
        latestMessages.putIfAbsent(message['chat_id'] as String, () => message);
      }
      final postsById = {for (final post in List<Map<String, dynamic>>.from(postRows)) post['id'] as String: post};
      final enrichedChats = chats.map((chat) {
        final isAuthor = chat['author_id'] == user.id;
        final last = latestMessages[chat['id'] as String];
        final kind = last?['message_kind'] as String?;
        final lastMessage = kind == 'post_preview'
            ? 'Study help · ${last?['preview_topic'] ?? 'Post'}'
            : kind == 'image'
                ? '📷 Image'
                : last?['body'] as String? ?? 'Start the conversation';
        return {
          ...chat,
          'other_user_name': isAuthor ? chat['responder_name'] : chat['author_name'],
          'other_student_id': isAuthor ? chat['responder_student_id'] : chat['author_student_id'],
          'other_avatar_path': isAuthor ? chat['responder_avatar_path'] : chat['author_avatar_path'],
          'last_message_preview': lastMessage,
          'last_message_at': last?['created_at'],
          'post_details': postsById[chat['post_id'] as String],
        };
      }).toList(growable: false);
      emit(state.copyWith(studyHelpChats: enrichedChats, isBusy: false, action: AppAction.loadStudyHelpChats, actionStatus: AppActionStatus.success, clearError: true));
    } catch (error) { _fail(emit, AppAction.loadStudyHelpChats, error); }
  }

  Future<void> _openStudyHelpChat(StudyHelpChatOpenRequested event, Emitter<AppState> emit) async {
    _begin(emit, AppAction.openStudyHelpChat);
    emit(state.copyWith(clearStudyHelpOpenedChat: true));
    String? avatarCopyPath;
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw const AuthException('Please sign in to respond.');
      final profile = await _client.from('campusmate_profiles').select('avatar_path').eq('user_id', user.id).maybeSingle();
      final privateAvatarPath = profile?['avatar_path'] as String?;
      if (privateAvatarPath != null && privateAvatarPath.isNotEmpty) {
        try {
          final extension = privateAvatarPath.contains('.') ? privateAvatarPath.split('.').last.toLowerCase() : 'jpg';
          avatarCopyPath = '${user.id}/chat-avatars/${DateTime.now().microsecondsSinceEpoch}.$extension';
          final bytes = await _client.storage.from('profile-avatars').download(privateAvatarPath);
          await _client.storage.from('study-help-media').uploadBinary(avatarCopyPath, bytes, fileOptions: FileOptions(contentType: _imageContentType(extension), upsert: false));
        } catch (_) { avatarCopyPath = null; }
      }
      final chatId = await _client.rpc('open_study_help_chat', params: {
        'post_id_input': event.postId,
        'responder_avatar_path_input': avatarCopyPath,
      });
      final chatRow = await _client.from('study_help_chats').select().eq('id', chatId.toString()).single();
      final postRow = await _client.from('study_help_posts').select().eq('id', event.postId).single();
      final chat = {...Map<String, dynamic>.from(chatRow), 'post_details': Map<String, dynamic>.from(postRow)};
      if (avatarCopyPath != null && chat['responder_avatar_path'] != avatarCopyPath) {
        try { await _client.storage.from('study-help-media').remove([avatarCopyPath]); } catch (_) {}
        avatarCopyPath = null;
      }
      emit(state.copyWith(studyHelpOpenedChat: chat, isBusy: false, action: AppAction.openStudyHelpChat, actionStatus: AppActionStatus.success, clearError: true));
    } catch (error) {
      if (avatarCopyPath != null) {
        try { await _client.storage.from('study-help-media').remove([avatarCopyPath]); } catch (_) {}
      }
      _fail(emit, AppAction.openStudyHelpChat, error);
    }
  }

  Future<void> _watchStudyHelpMessages(StudyHelpChatMessagesWatchRequested event, Emitter<AppState> emit) async {
    await _studyHelpMessageSubscription?.cancel();
    emit(state.copyWith(studyHelpMessages: const [], studyHelpMessagesForChatId: event.chatId, isBusy: false, action: AppAction.loadStudyHelpMessages, actionStatus: AppActionStatus.pending, clearError: true));
    _studyHelpMessageSubscription = _client.from('study_help_messages').stream(primaryKey: ['id']).eq('chat_id', event.chatId).order('created_at', ascending: false).listen(
      (rows) => add(StudyHelpChatMessagesReceived(chatId: event.chatId, messages: rows)),
      onError: (Object error) => add(StudyHelpChatMessagesFailed(chatId: event.chatId, error: error)),
    );
  }

  void _studyHelpMessagesReceived(StudyHelpChatMessagesReceived event, Emitter<AppState> emit) {
    if (state.studyHelpMessagesForChatId != event.chatId) return;
    emit(state.copyWith(studyHelpMessages: event.messages, isBusy: false, action: AppAction.loadStudyHelpMessages, actionStatus: AppActionStatus.success, clearError: true));
  }

  void _studyHelpMessagesFailed(StudyHelpChatMessagesFailed event, Emitter<AppState> emit) {
    if (state.studyHelpMessagesForChatId == event.chatId) _fail(emit, AppAction.loadStudyHelpMessages, event.error);
  }

  Future<void> _sendStudyHelpMessage(StudyHelpMessageSendRequested event, Emitter<AppState> emit) async {
    _begin(emit, AppAction.sendStudyHelpMessage);
    String? imagePath;
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw const AuthException('Please sign in to send messages.');
      final body = event.body.trim();
      if (event.image == null && body.isEmpty) throw const FormatException('Write a message or attach a photo.');
      if (event.image != null) {
        final image = event.image!;
        final extension = image.name.contains('.') ? image.name.split('.').last.toLowerCase() : 'jpg';
        imagePath = '${user.id}/${event.chatId}/${DateTime.now().microsecondsSinceEpoch}.$extension';
        await _client.storage.from('study-help-media').upload(imagePath, File(image.path), fileOptions: FileOptions(contentType: _imageContentType(extension), upsert: false));
      }
      final row = await _client.from('study_help_messages').insert({
        'chat_id': event.chatId,
        'sender_id': user.id,
        'message_kind': imagePath == null ? 'text' : 'image',
        'body': body.isEmpty ? null : body,
        'attachment_path': imagePath,
      }).select().single();
      final messages = state.studyHelpMessagesForChatId == event.chatId
          ? [Map<String, dynamic>.from(row), ...state.studyHelpMessages.where((message) => message['id'] != row['id'])]
          : state.studyHelpMessages;
      emit(state.copyWith(studyHelpMessages: messages, isBusy: false, action: AppAction.sendStudyHelpMessage, actionStatus: AppActionStatus.success, clearError: true));
    } catch (error) {
      if (imagePath != null) {
        try { await _client.storage.from('study-help-media').remove([imagePath]); } catch (_) {}
      }
      _fail(emit, AppAction.sendStudyHelpMessage, error);
    }
  }

  Future<void> _closeStudyHelpChat(StudyHelpChatCloseRequested event, Emitter<AppState> emit) async {
    _begin(emit, AppAction.closeStudyHelpChat);
    try {
      await _client.rpc('close_study_help_chat', params: {'chat_id_input': event.chatId});
      emit(state.copyWith(studyHelpChats: state.studyHelpChats.where((chat) => chat['id'] != event.chatId).toList(growable: false), isBusy: false, action: AppAction.closeStudyHelpChat, actionStatus: AppActionStatus.success, clearError: true));
    } catch (error) { _fail(emit, AppAction.closeStudyHelpChat, error); }
  }

  Future<void> _loadFreshersFaqs(
    FreshersFaqsLoadRequested event,
    Emitter<AppState> emit,
  ) async {
    _begin(emit, AppAction.loadFreshersFaqs);
    try {
      final rows = await _client
          .from('freshers_faqs')
          .select('id,question,answer,display_order')
          .eq('is_active', true)
          .order('display_order')
          .order('created_at');
      emit(state.copyWith(
        freshersFaqs: List<Map<String, dynamic>>.from(rows),
        isBusy: false,
        action: AppAction.loadFreshersFaqs,
        actionStatus: AppActionStatus.success,
        clearError: true,
      ));
    } catch (error) {
      _fail(emit, AppAction.loadFreshersFaqs, error);
    }
  }

  Future<void> _loadFreshersQuestions(
    FreshersQuestionsLoadRequested event,
    Emitter<AppState> emit,
  ) async {
    _begin(emit, AppAction.loadFreshersQuestions);
    try {
      final rows = await _client
          .from('freshers_questions')
          .select()
          .order('created_at', ascending: false);
      emit(state.copyWith(
        freshersQuestions: List<Map<String, dynamic>>.from(rows),
        isBusy: false,
        action: AppAction.loadFreshersQuestions,
        actionStatus: AppActionStatus.success,
        clearError: true,
      ));
    } catch (error) {
      _fail(emit, AppAction.loadFreshersQuestions, error);
    }
  }

  Future<String?> _copyFreshersAvatar(
    String userId,
    String key,
    List<String> cleanupPaths,
  ) async {
    try {
      final profile = await _client
          .from('campusmate_profiles')
          .select('avatar_path')
          .eq('user_id', userId)
          .maybeSingle();
      final privatePath = profile?['avatar_path'] as String?;
      if (privatePath == null || privatePath.isEmpty) return null;

      final extension = privatePath.contains('.')
          ? privatePath.split('.').last.toLowerCase()
          : 'jpg';
      final path = '$userId/$key-avatar.$extension';
      final bytes = await _client.storage
          .from('profile-avatars')
          .download(privatePath);
      await _client.storage.from('freshers-media').uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: _imageContentType(extension),
              upsert: false,
            ),
          );
      cleanupPaths.add(path);
      return path;
    } catch (_) {
      return null;
    }
  }

  Future<void> _createFreshersQuestion(
    FreshersQuestionCreateRequested event,
    Emitter<AppState> emit,
  ) async {
    _begin(emit, AppAction.createFreshersQuestion);
    final uploadedPaths = <String>[];
    final cleanupPaths = <String>[];
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw const AuthException('Please sign in before asking a question.');
      }
      final key = DateTime.now().microsecondsSinceEpoch.toString();
      final avatarPath =
          await _copyFreshersAvatar(user.id, key, cleanupPaths);
      final storage = _client.storage.from('freshers-media');
      for (var index = 0; index < event.images.length; index++) {
        final image = event.images[index];
        final extension = image.name.contains('.')
            ? image.name.split('.').last.toLowerCase()
            : 'jpg';
        final path = '${user.id}/$key-$index.$extension';
        await storage.upload(
          path,
          File(image.path),
          fileOptions: const FileOptions(upsert: false),
        );
        uploadedPaths.add(path);
        cleanupPaths.add(path);
      }

      final row = await _client.from('freshers_questions').insert({
        'author_id': user.id,
        'author_avatar_path': avatarPath,
        'question': event.question.trim(),
        'image_paths': uploadedPaths,
      }).select().single();
      emit(state.copyWith(
        freshersQuestions: [
          Map<String, dynamic>.from(row),
          ...state.freshersQuestions,
        ],
        isBusy: false,
        action: AppAction.createFreshersQuestion,
        actionStatus: AppActionStatus.success,
        clearError: true,
      ));
    } catch (error) {
      _fail(emit, AppAction.createFreshersQuestion, error);
      if (cleanupPaths.isNotEmpty) {
        try {
          await _client.storage.from('freshers-media').remove(cleanupPaths);
        } catch (_) {}
      }
    }
  }

  Future<void> _loadFreshersAnswers(
    FreshersAnswersLoadRequested event,
    Emitter<AppState> emit,
  ) async {
    _begin(emit, AppAction.loadFreshersAnswers);
    try {
      final questionRow = await _client
          .from('freshers_questions')
          .select()
          .eq('id', event.questionId)
          .single();
      final answerRows = await _client
          .from('freshers_answers')
          .select()
          .eq('question_id', event.questionId)
          .order('created_at');
      final question = Map<String, dynamic>.from(questionRow);
      emit(state.copyWith(
        freshersQuestion: question,
        freshersAnswers: List<Map<String, dynamic>>.from(answerRows),
        freshersAnswersForQuestionId: event.questionId,
        isBusy: false,
        action: AppAction.loadFreshersAnswers,
        actionStatus: AppActionStatus.success,
        clearError: true,
      ));
    } catch (error) {
      _fail(emit, AppAction.loadFreshersAnswers, error);
    }
  }

  Future<void> _createFreshersAnswer(
    FreshersAnswerCreateRequested event,
    Emitter<AppState> emit,
  ) async {
    _begin(emit, AppAction.createFreshersAnswer);
    final cleanupPaths = <String>[];
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw const AuthException('Please sign in to answer.');
      }
      final key = DateTime.now().microsecondsSinceEpoch.toString();
      final avatarPath =
          await _copyFreshersAvatar(user.id, key, cleanupPaths);
      final row = await _client.from('freshers_answers').insert({
        'question_id': event.questionId,
        'author_id': user.id,
        'author_avatar_path': avatarPath,
        'body': event.body.trim(),
      }).select().single();
      final answers = state.freshersAnswersForQuestionId == event.questionId
          ? [...state.freshersAnswers, Map<String, dynamic>.from(row)]
          : state.freshersAnswers;
      emit(state.copyWith(
        freshersAnswers: answers,
        isBusy: false,
        action: AppAction.createFreshersAnswer,
        actionStatus: AppActionStatus.success,
        clearError: true,
      ));
    } catch (error) {
      _fail(emit, AppAction.createFreshersAnswer, error);
      if (cleanupPaths.isNotEmpty) {
        try {
          await _client.storage.from('freshers-media').remove(cleanupPaths);
        } catch (_) {}
      }
    }
  }

  Future<void> _changeFreshersBestAnswer(
    FreshersBestAnswerChangedRequested event,
    Emitter<AppState> emit,
  ) async {
    _begin(emit, AppAction.setFreshersBestAnswer);
    try {
      await _client.rpc('set_freshers_best_answer', params: {
        'question_id_input': event.questionId,
        'answer_id_input': event.answerId,
      });
      final row = await _client
          .from('freshers_questions')
          .select()
          .eq('id', event.questionId)
          .single();
      final question = Map<String, dynamic>.from(row);
      emit(state.copyWith(
        freshersQuestion: question,
        freshersQuestions: state.freshersQuestions
            .map((item) => item['id'] == event.questionId ? question : item)
            .toList(growable: false),
        isBusy: false,
        action: AppAction.setFreshersBestAnswer,
        actionStatus: AppActionStatus.success,
        clearError: true,
      ));
    } catch (error) {
      _fail(emit, AppAction.setFreshersBestAnswer, error);
    }
  }

  String _imageContentType(String extension) => switch (extension) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };

  Future<void> _generateAiQuiz(
    AiQuizGenerateRequested event,
    Emitter<AppState> emit,
  ) async {
    _begin(emit, AppAction.generateAiQuiz);
    try {
      if (_client.auth.currentUser == null) {
        throw const AuthException('Please sign in to generate a quiz.');
      }
      final courseName = event.courseName.trim();
      final topicName = event.topicName.trim();
      if (courseName.isEmpty || topicName.isEmpty) {
        throw const FormatException('Enter both a course and a topic.');
      }
      final response = await _client.functions.invoke(
        'generate-ai-quiz',
        body: {'courseName': courseName, 'topicName': topicName},
      );
      final payload = response.data;
      if (payload is! Map || payload['questions'] is! List) {
        throw const FormatException(
            'The quiz generator returned an unexpected response. Please try again.');
      }
      final rawQuestions = payload['questions'] as List;
      if (rawQuestions.length < 10 || rawQuestions.length > 20) {
        throw const FormatException(
            'The quiz generator returned an invalid number of questions. Please try again.');
      }
      final questions = <Map<String, dynamic>>[];
      for (final rawQuestion in rawQuestions) {
        if (rawQuestion is! Map) {
          throw const FormatException(
              'The quiz generator returned an invalid question. Please try again.');
        }
        final questionText = rawQuestion['question'];
        final rawOptions = rawQuestion['options'];
        final correctIndex = rawQuestion['correctIndex'];
        if (questionText is! String ||
            questionText.trim().isEmpty ||
            rawOptions is! List ||
            rawOptions.length != 4 ||
            rawOptions.any((option) => option is! String) ||
            correctIndex is! int ||
            correctIndex < 0 ||
            correctIndex > 3) {
          throw const FormatException(
              'The quiz generator returned incomplete questions. Please try again.');
        }
        questions.add({
          'question': questionText.trim(),
          'options': rawOptions.cast<String>(),
          'correctIndex': correctIndex,
        });
      }
      emit(state.copyWith(
        quizCourseName: courseName,
        quizTopicName: topicName,
        quizQuestions: questions,
        quizAnswers: List<int?>.filled(questions.length, null),
        isBusy: false,
        action: AppAction.generateAiQuiz,
        actionStatus: AppActionStatus.success,
        clearError: true,
      ));
    } catch (error) {
      _fail(emit, AppAction.generateAiQuiz, error);
    }
  }

  void _begin(Emitter<AppState> emit, AppAction action) => emit(state.copyWith(isBusy: true, action: action, actionStatus: AppActionStatus.pending, clearError: true));
  void _succeed(Emitter<AppState> emit, AppAction action, {User? user, bool clearUser = false, Map<String, dynamic>? profile}) => emit(state.copyWith(isBusy: false, action: action, actionStatus: AppActionStatus.success, user: user, clearUser: clearUser, profile: profile, clearError: true));
  void _fail(Emitter<AppState> emit, AppAction action, Object error) => emit(state.copyWith(isBusy: false, action: action, actionStatus: AppActionStatus.failure, errorMessage: error is AuthException ? error.message : error.toString().replaceFirst('Exception: ', '')));
  @override
  Future<void> close() async { await _authSubscription?.cancel(); await _studyHelpMessageSubscription?.cancel(); await super.close(); }
}
