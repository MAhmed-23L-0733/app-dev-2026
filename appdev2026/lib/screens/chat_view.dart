import 'dart:async';

import 'package:flutter/material.dart';
import '../services/ai_chat_service.dart';
import '../widgets/neon_surface.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage(this.text, this.isUser);
}

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final AiChatService _chatService = AiChatService();
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  DateTime? _lastSubmitAt;

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessage(
        "Hey! I'm your AI financial advisor. I can see your live budget. Ask me if you can afford something, or ask me to roast your spending! 💸",
        false,
      ),
    );

    unawaited(_chatService.initializeChat());
    unawaited(_chatService.testConnection());
  }

  Future<void> _sendMessage() async {
    if (_isLoading) {
      return;
    }

    final DateTime now = DateTime.now();
    if (_lastSubmitAt != null &&
        now.difference(_lastSubmitAt!).inMilliseconds < 500) {
      return;
    }

    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _lastSubmitAt = now;

    setState(() {
      _messages.add(ChatMessage(text, true));
      _isLoading = true;
    });

    _controller.clear();

    final response = await _chatService.sendMessage(text);

    if (mounted) {
      setState(() {
        _messages.add(ChatMessage(response, false));
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final primary = Theme.of(context).colorScheme.primary;

    // NEW: Wrapped in a Scaffold since it's a standalone screen now!
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('AI Financial Advisor'),
        backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.9),
      ),
      body: NeonBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return Align(
                      alignment: msg.isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: msg.isUser
                              ? primary
                              : Theme.of(
                                  context,
                                ).colorScheme.surface.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(20),
                          border: msg.isUser
                              ? null
                              : Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                ),
                        ),
                        child: Text(
                          msg.text,
                          style: TextStyle(
                            color: msg.isUser ? Colors.white : onSurface,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),

              Padding(
                // Removed the huge bottom padding since there's no bottom nav bar here anymore
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                          decoration: InputDecoration(
                            hintText: 'Ask your advisor...',
                            hintStyle: TextStyle(
                              color: onSurface.withOpacity(0.5),
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.send_rounded, color: primary),
                        onPressed: _isLoading ? null : _sendMessage,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
