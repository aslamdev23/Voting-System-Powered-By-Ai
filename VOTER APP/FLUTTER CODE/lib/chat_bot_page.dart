import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ChatBotPage extends StatefulWidget {
  const ChatBotPage({super.key});

  @override
  _ChatBotPageState createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _chatMessages = [];
  late final GenerativeModel _model;
  static const String _geminiApiKey =
      'AIzaSyC6oyNXPxQpQWUjDkEys3C9cNox5dzU5vk'; // Same API key as MainPage

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(model: 'gemini-1.5-pro', apiKey: _geminiApiKey);
  }

  Future<void> _askGemini(String question) async {
    setState(() {
      _chatMessages.add({'sender': 'user', 'message': question});
    });

    try {
      final prompt = '''
        You are a voting assistant for the Election Commission of India. Answer the following question related to voting: $question
        If the question is unrelated to voting, respond with: "I can only assist with voting-related queries."
      ''';
      final response = await _model.generateContent([Content.text(prompt)]);
      setState(() {
        _chatMessages.add({
          'sender': 'bot',
          'message': response.text ?? 'No response from Gemini.'
        });
      });
    } catch (e) {
      setState(() {
        _chatMessages.add({'sender': 'bot', 'message': 'Error: $e'});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade900, Colors.blue.shade300],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            // Header with Logo
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/chatbot_logo.png',
                        height: 24,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/chat.png',
                            height: 24,
                            color: Colors.white,
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Voting Assistant',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Image.asset(
                      'assets/close.png',
                      height: 24,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Default Questions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Wrap(
                spacing: 8.0,
                children: [
                  _buildDefaultQuestionChip('How to register as a voter?'),
                  _buildDefaultQuestionChip(
                      'What are the eligibility criteria?'),
                  _buildDefaultQuestionChip('How to check my voter status?'),
                  _buildDefaultQuestionChip('What documents are required?'),
                ],
              ),
            ),
            // Chat Messages
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _chatMessages.length,
                itemBuilder: (context, index) {
                  final message = _chatMessages[index];
                  final isUser = message['sender'] == 'user';
                  return Align(
                    alignment:
                        isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 5.0),
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: isUser
                            ? Colors.white
                            : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Text(
                        message['message']!,
                        style: TextStyle(
                          color: isUser ? Colors.black87 : Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Input Field
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Ask a question...',
                        hintStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: Image.asset(
                      'assets/send.png',
                      height: 24,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      if (_chatController.text.isNotEmpty) {
                        _askGemini(_chatController.text);
                        _chatController.clear();
                        // Dismiss the keyboard after sending the message
                        FocusManager.instance.primaryFocus?.unfocus();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultQuestionChip(String question) {
    return GestureDetector(
      onTap: () => _askGemini(question),
      child: Chip(
        label: Text(
          question,
          style: const TextStyle(color: Colors.black, fontSize: 12),
        ),
        backgroundColor: Colors.white.withOpacity(0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
      ),
    );
  }
}
