import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../core/config.dart';

class ChatMessage {
  final String role;
  final String text;
  final DateTime timestamp;
  final List<String> reactions;

  ChatMessage({
    required this.role,
    required this.text,
    DateTime? timestamp,
    List<String>? reactions,
  })  : timestamp = timestamp ?? DateTime.now(),
        reactions = reactions ?? <String>[];

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      role: map['role'] as String,
      text: map['text'] as String,
      timestamp: map['timestamp'] as DateTime?,
      reactions: List<String>.from(map['reactions'] ?? <String>[]),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'text': text,
      'timestamp': timestamp,
      'reactions': reactions,
    };
  }
}

class HomeworkSolutionProvider extends ChangeNotifier {
  final TextEditingController textController = TextEditingController();
  final List<ChatMessage> messages = [];
  bool isLoading = false;
  bool isTyping = false;
  final ImagePicker picker = ImagePicker();

  HomeworkSolutionProvider() {
    messages.add(ChatMessage(
      role: 'bot',
      text: 'Hi there! 👋\nI\'m your AI Homework Assistant. Ask me any question or scan your homework for instant help!',
    ));
  }

  String _formatResponse(String text) {
    text = text.replaceAllMapped(
      RegExp(r'(?:\n|^)([A-Z][A-Z\s]+:)(?=\s|$)'),
          (match) => '\nHEADING:${match.group(1)}',
    );
    text = text.replaceAllMapped(
      RegExp(r'(\n\s*\d+\.\s)'),
          (match) => '\nSTEP:${match.group(1)}',
    );
    text = text.replaceAllMapped(
      RegExp(r'(\n\s*[A-Za-z]+\s*=\s*.+)'),
          (match) => '\nFORMULA:${match.group(1)}',
    );
    text = text.replaceAllMapped(
      RegExp(r'(\n\s*•\s)'),
          (match) => '\nPOINT:${match.group(1)}',
    );
    return text;
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      role: 'user',
      text: text.trim(),
    );

    textController.clear();
    messages.add(userMessage);
    notifyListeners();

    isLoading = true;
    isTyping = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));

    try {
      await fetchOpenAIResponse(text.trim());
    } catch (e) {
      String errorMessage = 'An unexpected error occurred.';
      if (e is SocketException) {
        errorMessage = 'Network Error: Please check your connection.';
      } else if (e is TimeoutException) {
        errorMessage = 'Request Timeout: Please try again later.';
      } else if (e.toString().contains("API Error")) {
        errorMessage = 'API Error: ${e.toString().replaceFirst("Exception: ", "")}';
      } else {
        errorMessage = 'Error: ${e.toString().replaceFirst("Exception: ", "")}';
      }

      messages.add(ChatMessage(
        role: 'bot',
        text: errorMessage,
      ));
    } finally {
      isLoading = false;
      isTyping = false;
      notifyListeners();
    }
  }

  Future<void> pickImage() async {
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (image == null) return;

    isLoading = true;
    notifyListeners();

    messages.add(ChatMessage(
      role: 'user',
      text: '[Scanning Image...]',
    ));
    notifyListeners();

    try {
      final String extractedText = await extractTextFromImage(File(image.path));

      if (messages.isNotEmpty && messages.last.text == '[Scanning Image...]') {
        messages.removeLast();
      }

      if (extractedText.trim().isNotEmpty) {
        final imageQuestion = 'Question from image:\n"${extractedText.trim()}"';
        await sendMessage(imageQuestion);
      } else {
        messages.add(ChatMessage(
          role: 'bot',
          text: 'Could not extract text from the image. Please try again or type your question.',
        ));
      }
    } catch (e) {
      if (messages.isNotEmpty && messages.last.text == '[Scanning Image...]') {
        messages.removeLast();
      }
      messages.add(ChatMessage(
        role: 'bot',
        text: 'Error processing image: ${e.toString().replaceFirst("Exception: ", "")}',
      ));
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String> extractTextFromImage(File image) async {
    final textRecognizer = TextRecognizer();
    final inputImage = InputImage.fromFile(image);
    final recognizedText = await textRecognizer.processImage(inputImage);

    String result = '';
    for (final block in recognizedText.blocks) {
      result += '${block.text}\n';
    }

    textRecognizer.close();
    return result.trim();
  }

  Future<void> fetchOpenAIResponse(String prompt) async {
    if (prompt.trim().isEmpty || prompt.trim() == 'Question from image:\n""') {
      messages.add(ChatMessage(
        role: 'bot',
        text: "The extracted text was empty. Please type your question or try scanning again.",
      ));
      notifyListeners();
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.openaiBaseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.openaiApiKey}',
        },
        body: jsonEncode({
          "model": ApiConfig.model,
          "messages": [
            {
              "role": "system",
              "content":
              "You are 'Quizard AI', a friendly homework helper. Format responses clearly using:\n"
                  "1. SECTION HEADINGS: ALL CAPS with colon\n"
                  "2. STEPS: Numbered steps\n"
                  "3. FORMULAS: On separate lines\n"
                  "4. KEY POINTS: Prefix with •\n"
                  "5. Clear and concise explanations"
            },
            {
              "role": "user",
              "content": prompt
            }
          ],
          "temperature": 0.6,
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        String text =
        jsonResponse['choices'][0]['message']['content'] as String;

        text = _formatResponse(text);

        messages.add(ChatMessage(
          role: 'bot',
          text: text,
        ));
      } else {
        throw Exception("API Error ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      messages.add(ChatMessage(
        role: 'bot',
        text: "Error: ${e.toString().replaceFirst("Exception: ", "")}",
      ));
    } finally {
      notifyListeners();
    }
  }


  void addReaction(int index, String emoji) {
    if (index >= 0 && index < messages.length) {
      messages[index].reactions.add(emoji);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }
}