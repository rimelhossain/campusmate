import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_events.dart';

class AppState {
  const AppState({this.user, this.isRestoring = true, this.hasUsedEmail = false, this.isBusy = false, this.lastUsedEmail, this.profile, this.action, this.actionStatus = AppActionStatus.idle, this.errorMessage, this.themeMode = ThemeMode.light, this.marketplacePosts = const [], this.marketplaceComments = const [], this.commentsForPostId, this.lostFoundPosts = const [], this.lostFoundResponses = const [], this.lostFoundResponsesForPostId, this.studyHelpPosts = const [], this.studyHelpChats = const [], this.studyHelpMessages = const [], this.studyHelpOpenedChat, this.studyHelpMessagesForChatId, this.freshersFaqs = const [], this.freshersQuestions = const [], this.freshersAnswers = const [], this.freshersQuestion, this.freshersAnswersForQuestionId, this.quizCourseName, this.quizTopicName, this.quizQuestions = const [], this.quizAnswers = const []});
  final User? user;
  final bool isRestoring, hasUsedEmail, isBusy;
  final String? lastUsedEmail;
  final Map<String, dynamic>? profile;
  final AppAction? action;
  final AppActionStatus actionStatus;
  final String? errorMessage;
  final ThemeMode themeMode;
  final List<Map<String, dynamic>> marketplacePosts;
  final List<Map<String, dynamic>> marketplaceComments;
  final String? commentsForPostId;
  final List<Map<String, dynamic>> lostFoundPosts;
  final List<Map<String, dynamic>> lostFoundResponses;
  final String? lostFoundResponsesForPostId;
  final List<Map<String, dynamic>> studyHelpPosts;
  final List<Map<String, dynamic>> studyHelpChats;
  final List<Map<String, dynamic>> studyHelpMessages;
  final Map<String, dynamic>? studyHelpOpenedChat;
  final String? studyHelpMessagesForChatId;
  final List<Map<String, dynamic>> freshersFaqs;
  final List<Map<String, dynamic>> freshersQuestions;
  final List<Map<String, dynamic>> freshersAnswers;
  final Map<String, dynamic>? freshersQuestion;
  final String? freshersAnswersForQuestionId;
  final String? quizCourseName;
  final String? quizTopicName;
  final List<Map<String, dynamic>> quizQuestions;
  final List<int?> quizAnswers;
  AppState copyWith({User? user, bool clearUser = false, bool? isRestoring, bool? hasUsedEmail, bool? isBusy, String? lastUsedEmail, Map<String, dynamic>? profile, AppAction? action, AppActionStatus? actionStatus, String? errorMessage, ThemeMode? themeMode, bool clearProfile = false, bool clearAction = false, bool clearError = false, List<Map<String, dynamic>>? marketplacePosts, List<Map<String, dynamic>>? marketplaceComments, String? commentsForPostId, bool clearCommentsForPost = false, List<Map<String, dynamic>>? lostFoundPosts, List<Map<String, dynamic>>? lostFoundResponses, String? lostFoundResponsesForPostId, bool clearLostFoundResponsesForPost = false, List<Map<String, dynamic>>? studyHelpPosts, List<Map<String, dynamic>>? studyHelpChats, List<Map<String, dynamic>>? studyHelpMessages, Map<String, dynamic>? studyHelpOpenedChat, bool clearStudyHelpOpenedChat = false, String? studyHelpMessagesForChatId, bool clearStudyHelpMessagesForChat = false, List<Map<String, dynamic>>? freshersFaqs, List<Map<String, dynamic>>? freshersQuestions, List<Map<String, dynamic>>? freshersAnswers, Map<String, dynamic>? freshersQuestion, bool clearFreshersQuestion = false, String? freshersAnswersForQuestionId, String? quizCourseName, String? quizTopicName, List<Map<String, dynamic>>? quizQuestions, List<int?>? quizAnswers, bool clearQuizSession = false}) => AppState(
    user: clearUser ? null : user ?? this.user,
    isRestoring: isRestoring ?? this.isRestoring,
    hasUsedEmail: hasUsedEmail ?? this.hasUsedEmail,
    isBusy: isBusy ?? this.isBusy,
    lastUsedEmail: lastUsedEmail ?? this.lastUsedEmail,
    profile: clearProfile ? null : profile ?? this.profile,
    action: clearAction ? null : action ?? this.action,
    actionStatus: actionStatus ?? this.actionStatus,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    themeMode: themeMode ?? this.themeMode,
    marketplacePosts: marketplacePosts ?? this.marketplacePosts,
    marketplaceComments: marketplaceComments ?? this.marketplaceComments,
    commentsForPostId: clearCommentsForPost ? null : commentsForPostId ?? this.commentsForPostId,
    lostFoundPosts: lostFoundPosts ?? this.lostFoundPosts,
    lostFoundResponses: lostFoundResponses ?? this.lostFoundResponses,
    lostFoundResponsesForPostId: clearLostFoundResponsesForPost ? null : lostFoundResponsesForPostId ?? this.lostFoundResponsesForPostId,
    studyHelpPosts: studyHelpPosts ?? this.studyHelpPosts,
    studyHelpChats: studyHelpChats ?? this.studyHelpChats,
    studyHelpMessages: studyHelpMessages ?? this.studyHelpMessages,
    studyHelpOpenedChat: clearStudyHelpOpenedChat ? null : studyHelpOpenedChat ?? this.studyHelpOpenedChat,
    studyHelpMessagesForChatId: clearStudyHelpMessagesForChat ? null : studyHelpMessagesForChatId ?? this.studyHelpMessagesForChatId,
    freshersFaqs: freshersFaqs ?? this.freshersFaqs,
    freshersQuestions: freshersQuestions ?? this.freshersQuestions,
    freshersAnswers: freshersAnswers ?? this.freshersAnswers,
    freshersQuestion: clearFreshersQuestion ? null : freshersQuestion ?? this.freshersQuestion,
    freshersAnswersForQuestionId: freshersAnswersForQuestionId ?? this.freshersAnswersForQuestionId,
    quizCourseName: clearQuizSession ? null : quizCourseName ?? this.quizCourseName,
    quizTopicName: clearQuizSession ? null : quizTopicName ?? this.quizTopicName,
    quizQuestions: clearQuizSession ? const [] : quizQuestions ?? this.quizQuestions,
    quizAnswers: clearQuizSession ? const [] : quizAnswers ?? this.quizAnswers,
  );
}
