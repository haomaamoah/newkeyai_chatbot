import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../core/config.dart';

class ChatInVoiceScreen extends StatefulWidget {
  const ChatInVoiceScreen({super.key});

  @override
  ChatInVoiceScreenState createState() => ChatInVoiceScreenState();
}

class ChatInVoiceScreenState extends State<ChatInVoiceScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();

  // Speech recognition
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _recognizedText = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initializeChat();
  }

  void _initializeChat() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'bot',
            'text':
                '👋 Hello! I\'m your voice-enabled AI assistant.\n\n'
                'You can either type your message or tap the mic button to speak.',
            'isSpecial': true,
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _startListening() async {
    if (_isLoading) return;

    if (!_isListening) {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        _showErrorSnackbar('Microphone permission denied');
        return;
      }

      bool available = await _speech.initialize(
        onStatus: (status) {
          if (mounted) {
            setState(() {
              if (status == 'done') {
                _isListening = false;
                if (_recognizedText.isNotEmpty) {
                  _textController.text = _recognizedText;
                  _recognizedText = '';
                }
              }
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _isListening = false;
              _showErrorSnackbar('Speech recognition error: $error');
            });
          }
        },
      );

      if (!mounted) return;

      if (available) {
        setState(() => _isListening = true);
        await _speech.listen(
          onResult: (result) {
            if (mounted) {
              setState(() {
                _recognizedText = result.recognizedWords;
              });
            }
          },
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 5),
          localeId: 'en_US',
          listenOptions: stt.SpeechListenOptions(cancelOnError: true, partialResults: true),
        );
      } else {
        setState(() => _isListening = false);
        _showErrorSnackbar('Speech recognition not available');
      }
    } else {
      setState(() => _isListening = false);
      await _speech.stop();
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final userMessage = text.trim();
    _inputFocusNode.unfocus();

    if (mounted) {
      setState(() {
        _messages.add({'role': 'user', 'text': userMessage});
        _textController.clear();
        _isLoading = true;
      });
    }
    _scrollToBottom();

    try {
      await _fetchAIResponse(userMessage);
    } catch (e) {
      _handleError(e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      _scrollToBottom(delayMilliseconds: 100);
    }
  }

  Future<void> _fetchAIResponse(String prompt) async {
    if (prompt.trim().isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.openaiBaseUrl),  // Using the secure endpoint from ApiConfig
        headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              "contents": [
                {
                  "parts": [
                    {"text": prompt},
                  ],
                },
              ],
              "generationConfig": {"temperature": 0.3, "topP": 0.95, "maxOutputTokens": 2000},
            }),
          )
          .timeout(const Duration(seconds: 60));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        String text = "I couldn't generate a response. Please try again.";

        if (jsonResponse["candidates"] != null &&
            jsonResponse["candidates"].isNotEmpty &&
            jsonResponse["candidates"][0]["content"]["parts"][0]["text"] != null) {
          text = jsonResponse["candidates"][0]["content"]["parts"][0]["text"];
        }

        setState(() {
          _messages.add({"role": "bot", "text": text.trim()});
        });
      } else {
        throw Exception("API Error ${response.statusCode}: ${response.body}");
      }
    } on SocketException {
      throw Exception("No internet connection");
    } on TimeoutException {
      throw Exception("Request timed out");
    }
  }

  void _handleError(dynamic e) {
    String errorMessage = 'An error occurred. Please try again.';
    if (e is SocketException) {
      errorMessage = 'No internet connection. Please check your network.';
    } else if (e is TimeoutException) {
      errorMessage = 'Request timed out. Please try again.';
    } else if (e.toString().contains("API Error")) {
      errorMessage = 'Error: ${e.toString().replaceFirst("Exception: ", "")}';
    }

    if (mounted) {
      setState(() {
        _messages.add({'role': 'bot', 'text': errorMessage, 'isSpecial': true});
      });
    }
  }

  void _scrollToBottom({int delayMilliseconds = 300}) {
    Future.delayed(Duration(milliseconds: delayMilliseconds), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuad,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Voice Chat Assistant',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 22),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[800]!, Colors.blue[600]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isUserMessage = message['role'] == 'user';

                        return _buildMessageBubble(
                          text: message['text']!,
                          isUser: isUserMessage,
                          isSpecial: message['isSpecial'] ?? false,
                        );
                      },
                    ),
            ),
            if (_isLoading) _buildTypingIndicator(),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic, size: 80, color: Colors.blue[600]),
            const SizedBox(height: 20),
            Text(
              'Start chatting with your voice!',
              style: TextStyle(fontSize: 18, color: Colors.grey[800], fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Tap the microphone button below to start speaking',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildExampleChip('Tell me about yourself'),
                _buildExampleChip('What can you do?'),
                _buildExampleChip('How does this work?'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleChip(String text) {
    return ActionChip(
      label: Text(text),
      onPressed: () => _sendMessage(text),
      backgroundColor: Colors.blue[50],
      labelStyle: TextStyle(color: Colors.blue[800]),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.blue[200]!),
      ),
    );
  }

  Widget _buildMessageBubble({required String text, required bool isUser, bool isSpecial = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: Colors.blue[800]!.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(18)),
              child: Icon(Icons.auto_awesome, color: Colors.blue[800], size: 20),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: isUser ? Colors.blue[800] : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20.0),
                  topRight: const Radius.circular(20.0),
                  bottomLeft: Radius.circular(isUser ? 20.0 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20.0),
                ),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: isSpecial
                  ? Text(text, style: TextStyle(color: isUser ? Colors.white : Colors.grey[800], fontSize: 16.0, height: 1.4))
                  : MarkdownBody(
                      data: text,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(color: isUser ? Colors.white : Colors.grey[800], fontSize: 16.0, height: 1.4),
                        strong: TextStyle(color: isUser ? Colors.white : Colors.blue[800], fontWeight: FontWeight.bold),
                        em: TextStyle(color: isUser ? Colors.white : Colors.blue[800], fontStyle: FontStyle.italic),
                        listBullet: TextStyle(color: isUser ? Colors.white : Colors.grey[800], fontSize: 16.0),
                        h1: TextStyle(color: isUser ? Colors.white : Colors.blue[800], fontSize: 22, fontWeight: FontWeight.bold),
                        h2: TextStyle(color: isUser ? Colors.white : Colors.blue[800], fontSize: 20, fontWeight: FontWeight.bold),
                        h3: TextStyle(color: isUser ? Colors.white : Colors.blue[800], fontSize: 18, fontWeight: FontWeight.bold),
                        code: TextStyle(
                          backgroundColor: isUser ? Colors.black.withValues(alpha:0.2) : Colors.grey[200],
                          color: isUser ? Colors.white : Colors.grey[800],
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                      ),
                    ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: Colors.blue[800], borderRadius: BorderRadius.circular(18)),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.1), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                _buildTypingDot(delay: 0, color: Colors.blue[800]!),
                _buildTypingDot(delay: 200, color: Colors.blue[800]!),
                _buildTypingDot(delay: 400, color: Colors.blue[800]!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot({required int delay, required Color color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: Color.fromARGB(
            delay == 0 ? 255 : (0.3 * 255).round(),
            (color.r * 255).round() & 0xff,
            (color.g * 255).round() & 0xff,
            (color.b * 255).round() & 0xff,
          ),
          borderRadius: BorderRadius.circular(5),
        ),

      ),
    );
  }

  Widget _buildInputArea() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        margin: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.0),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Mic button with proper alignment
            SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: AvatarGlow(
                  animate: _isListening,
                  glowColor: Colors.blue[800]!,
                  endRadius: 24.0,
                  duration: const Duration(milliseconds: 2000),
                  repeat: true,
                  child: IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening ? Colors.blue[800] : Colors.grey[600],
                      size: 24,
                    ),
                    onPressed: _isLoading ? null : _startListening,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ),
            ),

            // Text field with proper alignment
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: TextField(
                  controller: _textController,
                  focusNode: _inputFocusNode,
                  decoration: const InputDecoration(
                    hintText: 'Type or speak your message...',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14.0),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _isLoading ? null : (text) => _sendMessage(text),
                  minLines: 1,
                  maxLines: 5,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),

            // Send button with proper alignment
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _textController.text.trim().isEmpty
                  ? const SizedBox(width: 48, height: 48)
                  : SizedBox(
                      width: 48,
                      height: 48,
                      child: Center(
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.blue),
                          onPressed: _isLoading ? null : () => _sendMessage(_textController.text),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
