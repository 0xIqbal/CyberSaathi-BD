import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_service.dart';
import '../../data/models/health_answer.dart';
import '../../data/models/health_article.dart';
import '../../data/repositories/health_repository.dart';

final healthRepositoryProvider = Provider<HealthRepository>(
  (ref) => HealthRepository(ApiService()),
);

final healthTtsProvider = Provider<FlutterTts>((ref) {
  final tts = FlutterTts();
  ref.onDispose(tts.stop);
  return tts;
});

final healthProvider =
    NotifierProvider<HealthNotifier, HealthState>(HealthNotifier.new);

class HealthChatMessage {
  const HealthChatMessage({
    required this.text,
    required this.isUser,
    this.answer,
  });

  final String text;
  final bool isUser;
  final HealthAnswer? answer;
}

class HealthState {
  const HealthState({
    this.topics = const [],
    this.articles = const [],
    this.filteredArticles = const [],
    this.selectedArticle,
    this.answer,
    this.messages = const [],
    this.isLoading = false,
    this.isAsking = false,
    this.isSpeaking = false,
    this.activeCategory,
    this.errorMessage,
  });

  final List<String> topics;
  final List<HealthArticle> articles;
  final List<HealthArticle> filteredArticles;
  final HealthArticle? selectedArticle;
  final HealthAnswer? answer;
  final List<HealthChatMessage> messages;
  final bool isLoading;
  final bool isAsking;
  final bool isSpeaking;
  final String? activeCategory;
  final String? errorMessage;

  HealthState copyWith({
    List<String>? topics,
    List<HealthArticle>? articles,
    List<HealthArticle>? filteredArticles,
    HealthArticle? selectedArticle,
    HealthAnswer? answer,
    List<HealthChatMessage>? messages,
    bool? isLoading,
    bool? isAsking,
    bool? isSpeaking,
    String? activeCategory,
    String? errorMessage,
    bool clearAnswer = false,
    bool clearError = false,
  }) {
    return HealthState(
      topics: topics ?? this.topics,
      articles: articles ?? this.articles,
      filteredArticles: filteredArticles ?? this.filteredArticles,
      selectedArticle: selectedArticle ?? this.selectedArticle,
      answer: clearAnswer ? null : answer ?? this.answer,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isAsking: isAsking ?? this.isAsking,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      activeCategory: activeCategory ?? this.activeCategory,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class HealthNotifier extends Notifier<HealthState> {
  @override
  HealthState build() => const HealthState();

  HealthRepository get _repository => ref.read(healthRepositoryProvider);

  Future<void> loadHome() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final topics = await _repository.getTopics();
      final articles = await _repository.getArticles();
      state = state.copyWith(
        topics: topics,
        articles: articles,
        filteredArticles: articles,
        isLoading: false,
      );
    } on ApiException catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'স্বাস্থ্য তথ্য লোড করা যায়নি।',
      );
    }
  }

  void filterArticles(String query) {
    final value = query.trim().toLowerCase();
    final filtered = value.isEmpty
        ? state.articles
        : state.articles.where((article) {
            final searchable = [
              article.titleBn,
              article.titleEn,
              article.summaryBn,
              article.summaryEn,
              article.category,
              ...article.keywords,
            ].join(' ').toLowerCase();
            return searchable.contains(value);
          }).toList(growable: false);
    state = state.copyWith(filteredArticles: filtered);
  }

  void selectCategory(String? category) {
    final filtered = category == null || category.isEmpty
        ? state.articles
        : state.articles
            .where((article) => article.category == category)
            .toList(growable: false);
    state = state.copyWith(
      activeCategory: category,
      filteredArticles: filtered,
    );
  }

  Future<void> loadArticle(String slug) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      state = state.copyWith(
        selectedArticle: await _repository.getArticleDetail(slug),
        isLoading: false,
      );
    } on ApiException catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'এই স্বাস্থ্য নিবন্ধটি লোড করা যায়নি।',
      );
    }
  }

  Future<void> askQuestion(String question) async {
    final trimmedQuestion = question.trim();
    if (trimmedQuestion.isEmpty) {
      state = state.copyWith(errorMessage: 'আপনার প্রশ্নটি লিখুন।');
      return;
    }
    state = state.copyWith(
      isAsking: true,
      clearAnswer: true,
      clearError: true,
      messages: [
        ...state.messages,
        HealthChatMessage(text: trimmedQuestion, isUser: true),
      ],
    );
    try {
      final answer = await _repository.askQuestion(trimmedQuestion);
      state = state.copyWith(
        answer: answer,
        messages: [
          ...state.messages,
          HealthChatMessage(text: answer.answer, isUser: false, answer: answer),
        ],
        isAsking: false,
      );
    } on ApiException catch (error) {
      state = state.copyWith(isAsking: false, errorMessage: error.message);
    } catch (_) {
      state = state.copyWith(
        isAsking: false,
        errorMessage: 'উত্তর তৈরি করা যায়নি। আবার চেষ্টা করুন।',
      );
    }
  }

  Future<void> speakAnswer() async {
    final answer = state.answer?.answer;
    if (answer == null || answer.isEmpty) return;
    final tts = ref.read(healthTtsProvider);
    if (state.isSpeaking) {
      await tts.stop();
      state = state.copyWith(isSpeaking: false);
      return;
    }
    await tts.setLanguage('bn-BD');
    await tts.setSpeechRate(0.45);
    tts.setCompletionHandler(
      () => state = state.copyWith(isSpeaking: false),
    );
    state = state.copyWith(isSpeaking: true);
    await tts.speak(answer);
  }

  Future<void> stopSpeaking() async {
    await ref.read(healthTtsProvider).stop();
    state = state.copyWith(isSpeaking: false);
  }
}
