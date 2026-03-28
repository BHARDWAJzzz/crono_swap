import 'package:google_generative_ai/google_generative_ai.dart' as ai;
import '../../features/skill_exchange/domain/entities/user.dart';

/// Service to handle interactions with the Google Gemini AI.
/// Provides personalized help and mentoring advice for Crono Swap users.
class AiAssistantService {
  // IMPORTANT: For production, this should be an environment variable
  // or a secure remote config value.
  static const String _apiKey = 'AIzaSyCTA5MGuHDoYjeILWoAlxnG_8ILu2sXs-k';
  
  final ai.GenerativeModel _model;
  ai.ChatSession? _chat;

  AiAssistantService()
      : _model = ai.GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: _apiKey,
          systemInstruction: ai.Content.system(
            'You are "Crono Assistant", the official AI mentor for Crono Swap. '
            'Crono Swap is a skill-exchange platform where 1 hour of help = 1 credit. '
            'Your goal is to help users find matches, understand the rules, and grow their skills. '
            'Be encouraging, professional, and concise. '
            'If a user asks to learn something, recommend they check the "Explore" or "Quests" tabs. '
            'If they ask about credits, explain the 1-for-1 time exchange rule.'
          ),
        );

  /// Start a new chat session with user context
  void startSession(AppUser user) {
    final context = 'Current User: ${user.name}. '
        'Interests: ${user.interests.join(", ")}. '
        'Skills Offered: ${user.skillIds.length} skills. '
        'Time Balance: ${user.timeBalance} credits. '
        'Level: ${user.level} (${user.levelTitle}).';
    
    _chat = _model.startChat(history: [
      ai.Content.text('System Context: $context'),
      ai.Content.model([ai.TextPart('Understood. I am ready to help ${user.name} with their skill exchange journey.')]),
    ]);
  }

  /// Send a message to the AI and get a response
  Stream<String> sendMessageStream(String message) async* {
    if (_chat == null) throw Exception('Chat session not started. Call startSession first.');
    
    final response = _chat!.sendMessageStream(ai.Content.text(message));
    
    await for (final chunk in response) {
      if (chunk.text != null) {
        yield chunk.text!;
      }
    }
  }
}
