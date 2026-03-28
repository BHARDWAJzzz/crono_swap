import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/ai_assistant_service.dart';
import '../providers/auth_providers.dart';

class AssistantOverlay extends ConsumerStatefulWidget {
  const AssistantOverlay({super.key});

  @override
  ConsumerState<AssistantOverlay> createState() => _AssistantOverlayState();
}

class _AssistantOverlayState extends ConsumerState<AssistantOverlay> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  late AiAssistantService _aiService;

  @override
  void initState() {
    super.initState();
    _aiService = AiAssistantService();
    // Initialize with user context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(userDataProvider).value;
      if (user != null) {
        _aiService.startSession(user);
        setState(() {
          _messages.add(ChatMessage(
            text: "Hi ${user.name}! I'm Crono Assistant, your AI mentor. How can I help you with your skill exchange today?",
            isAi: true,
          ));
        });
      }
    });
  }

  void _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    setState(() {
      _messages.add(ChatMessage(text: text, isAi: false));
      _isTyping = true;
    });

    _scrollToBottom();

    String aiResponse = "";
    try {
      final stream = _aiService.sendMessageStream(text);
      
      // Add empty message for stream updates
      setState(() {
        _messages.add(ChatMessage(text: "", isAi: true));
      });

      await for (final chunk in stream) {
        aiResponse += chunk;
        setState(() {
          _messages.last = ChatMessage(text: aiResponse, isAi: true);
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('AI Error: $e');
      setState(() {
        _messages.add(ChatMessage(text: "Sorry, I had trouble connecting. Please check your internet or refresh the chat.", isAi: true));
      });
    } finally {
      setState(() {
        _isTyping = false;
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -5)),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.auto_awesome_rounded, color: theme.colorScheme.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Crono Assistant', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text('AI-Powered Mentor • Alpha', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),

          // Message List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(24),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildMessageTile(_messages[index]),
            ),
          ),

          // Input
          Container(
            padding: EdgeInsets.fromLTRB(20, 10, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _handleSend(),
                    style: GoogleFonts.outfit(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Ask your mentor...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _handleSend,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageTile(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: message.isAi ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (message.isAi) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
              child: const Icon(Icons.auto_awesome_rounded, size: 14, color: Colors.blue),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: message.isAi ? Colors.grey.shade100 : Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: Radius.circular(message.isAi ? 0 : 20),
                  bottomRight: Radius.circular(message.isAi ? 20 : 0),
                ),
              ),
              child: Text(
                message.text,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  height: 1.5,
                  color: message.isAi ? Colors.black87 : Colors.white,
                ),
              ),
            ),
          ),
          if (!message.isAi) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
              child: const Icon(Icons.person_rounded, size: 14, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isAi;
  ChatMessage({required this.text, required this.isAi});
}
