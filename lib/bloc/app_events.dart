import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AppEvent {}
class RestoreSessionRequested extends AppEvent {}
class SessionChanged extends AppEvent { SessionChanged(this.user); final User? user; }
class SignInRequested extends AppEvent { SignInRequested(this.email, this.password); final String email, password; }
class SignUpRequested extends AppEvent {
  SignUpRequested({required this.email, required this.password, required this.fullName, required this.studentId});
  final String email, password, fullName, studentId;
}
class VerifySignupOtpRequested extends AppEvent { VerifySignupOtpRequested(this.email, this.token); final String email, token; }
class ResendSignupOtpRequested extends AppEvent { ResendSignupOtpRequested(this.email); final String email; }
class PasswordResetOtpRequested extends AppEvent { PasswordResetOtpRequested(this.email); final String email; }
class PasswordRecoveryOtpResent extends AppEvent { PasswordRecoveryOtpResent(this.email); final String email; }
class PasswordRecoveryOtpVerified extends AppEvent { PasswordRecoveryOtpVerified({required this.email, required this.token}); final String email, token; }
class RecoveryPasswordUpdated extends AppEvent { RecoveryPasswordUpdated(this.password); final String password; }
class ProfileLoadRequested extends AppEvent {}
class ProfileUpdateRequested extends AppEvent {
  ProfileUpdateRequested({required this.fullName, required this.studentId, required this.avatarPath});
  final String fullName, studentId;
  final String? avatarPath;
}
class SignOutRequested extends AppEvent {}
class ThemeModeChanged extends AppEvent {
  ThemeModeChanged(this.themeMode);
  final ThemeMode themeMode;
}
class MarketplacePostsLoadRequested extends AppEvent {}
class MarketplacePostCreateRequested extends AppEvent {
  MarketplacePostCreateRequested({
    required this.title,
    required this.category,
    required this.description,
    required this.price,
    required this.isPriceFixed,
    required this.images,
  });
  final String title, category, description;
  final double price;
  final bool isPriceFixed;
  final List<XFile> images;
}
class MarketplacePostSoldOutChanged extends AppEvent {
  MarketplacePostSoldOutChanged({
    required this.postId,
    required this.isSoldOut,
  });
  final String postId;
  final bool isSoldOut;
}
class MarketplaceCommentsLoadRequested extends AppEvent {
  MarketplaceCommentsLoadRequested(this.postId);
  final String postId;
}
class MarketplaceCommentCreateRequested extends AppEvent {
  MarketplaceCommentCreateRequested({required this.postId, required this.body});
  final String postId;
  final String body;
}
class LostFoundPostsLoadRequested extends AppEvent {}
class LostFoundPostCreateRequested extends AppEvent {
  LostFoundPostCreateRequested({required this.title, required this.postType, required this.description, required this.location, required this.occurredAt, required this.images});
  final String title, postType, description, location;
  final DateTime occurredAt;
  final List<XFile> images;
}
class LostFoundPostResolvedChanged extends AppEvent {
  LostFoundPostResolvedChanged({required this.postId, required this.isResolved});
  final String postId;
  final bool isResolved;
}
class LostFoundResponsesLoadRequested extends AppEvent {
  LostFoundResponsesLoadRequested(this.postId);
  final String postId;
}
class LostFoundResponseCreateRequested extends AppEvent {
  LostFoundResponseCreateRequested({required this.postId, required this.body});
  final String postId, body;
}
class StudyHelpPostsLoadRequested extends AppEvent {}
class StudyHelpPostCreateRequested extends AppEvent {
  StudyHelpPostCreateRequested({required this.courseName, required this.topicName, required this.description, required this.images});
  final String courseName, topicName, description;
  final List<XFile> images;
}
class StudyHelpPostSolvedRequested extends AppEvent {
  StudyHelpPostSolvedRequested(this.postId);
  final String postId;
}
class StudyHelpChatsLoadRequested extends AppEvent {}
class StudyHelpChatOpenRequested extends AppEvent {
  StudyHelpChatOpenRequested(this.postId);
  final String postId;
}
class StudyHelpChatMessagesWatchRequested extends AppEvent {
  StudyHelpChatMessagesWatchRequested(this.chatId);
  final String chatId;
}
class StudyHelpChatMessagesReceived extends AppEvent {
  StudyHelpChatMessagesReceived({required this.chatId, required this.messages});
  final String chatId;
  final List<Map<String, dynamic>> messages;
}
class StudyHelpChatMessagesFailed extends AppEvent {
  StudyHelpChatMessagesFailed({required this.chatId, required this.error});
  final String chatId;
  final Object error;
}
class StudyHelpChatMessagesStopRequested extends AppEvent {}
class StudyHelpMessageSendRequested extends AppEvent {
  StudyHelpMessageSendRequested({required this.chatId, required this.body, this.image});
  final String chatId, body;
  final XFile? image;
}
class StudyHelpChatCloseRequested extends AppEvent {
  StudyHelpChatCloseRequested(this.chatId);
  final String chatId;
}
class AiQuizGenerateRequested extends AppEvent {
  AiQuizGenerateRequested({required this.courseName, required this.topicName});
  final String courseName;
  final String topicName;
}
class AiQuizAnswerSelected extends AppEvent {
  AiQuizAnswerSelected({required this.questionIndex, required this.optionIndex});
  final int questionIndex;
  final int optionIndex;
}
class AiQuizSessionCleared extends AppEvent {}
class FreshersFaqsLoadRequested extends AppEvent {}
class FreshersQuestionsLoadRequested extends AppEvent {}
class FreshersQuestionCreateRequested extends AppEvent {
  FreshersQuestionCreateRequested({required this.question, required this.images});
  final String question;
  final List<XFile> images;
}
class FreshersAnswersLoadRequested extends AppEvent {
  FreshersAnswersLoadRequested(this.questionId);
  final String questionId;
}
class FreshersAnswerCreateRequested extends AppEvent {
  FreshersAnswerCreateRequested({required this.questionId, required this.body});
  final String questionId;
  final String body;
}
class FreshersBestAnswerChangedRequested extends AppEvent {
  FreshersBestAnswerChangedRequested({required this.questionId, required this.answerId});
  final String questionId;
  final String? answerId;
}
enum AppAction { signIn, signUp, verifyOtp, resendOtp, requestPasswordReset, resendPasswordRecoveryOtp, verifyPasswordRecoveryOtp, updatePassword, loadProfile, updateProfile, signOut, loadMarketplacePosts, createMarketplacePost, updateMarketplacePost, loadMarketplaceComments, createMarketplaceComment, loadLostFoundPosts, createLostFoundPost, updateLostFoundPost, loadLostFoundResponses, createLostFoundResponse, loadStudyHelpPosts, createStudyHelpPost, updateStudyHelpPost, loadStudyHelpChats, openStudyHelpChat, loadStudyHelpMessages, sendStudyHelpMessage, closeStudyHelpChat, generateAiQuiz, loadFreshersFaqs, loadFreshersQuestions, createFreshersQuestion, loadFreshersAnswers, createFreshersAnswer, setFreshersBestAnswer }
enum AppActionStatus { idle, pending, success, failure }
