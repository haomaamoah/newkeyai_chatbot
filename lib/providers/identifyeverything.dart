import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../core/config.dart';

class IdentificationMessage {
  final String role;
  final String text;
  final DateTime timestamp;
  final List<String> reactions;
  final File? image;

  IdentificationMessage({
    required this.role,
    required this.text,
    this.image,
    DateTime? timestamp,
    List<String>? reactions,
  })  : timestamp = timestamp ?? DateTime.now(),
        reactions = reactions ?? <String>[];

  factory IdentificationMessage.fromMap(Map<String, dynamic> map) {
    return IdentificationMessage(
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

class IdentifyEverythingProvider extends ChangeNotifier {
  final TextEditingController textController = TextEditingController();
  final List<IdentificationMessage> messages = [];
  bool isLoading = false;
  bool isTyping = false;
  final ImagePicker picker = ImagePicker();
  File? _selectedImage;
  String? _imagePath;
  final Map<int, File?> _messageImages = {};

  File? getImageForMessage(int index) => _messageImages[index];
  File? get selectedImage => _selectedImage;
  String? get imagePath => _imagePath;

  IdentifyEverythingProvider() {
    // Initial bot message
    messages.add(IdentificationMessage(
      role: 'bot',
      text: 'Hi there! 👋\nI\'m your AI Identification Assistant. Show me any object or describe what you want to identify!',
    ));
  }

  // Format response text with headings, details, etc.
  String _formatResponse(String text) {
    // Format headings (all caps with colon)
    text = text.replaceAllMapped(
      RegExp(r'(?:\n|^)([A-Z][A-Z\s]+:)(?=\s|$)'),
          (match) => '\nHEADING:${match.group(1)}',
    );

    // Format key details
    text = text.replaceAllMapped(
      RegExp(r'(\n\s*-\s)'),
          (match) => '\nDETAIL:${match.group(1)}',
    );

    // Format interesting facts
    text = text.replaceAllMapped(
      RegExp(r'(\n\s*•\s)'),
          (match) => '\nFACT:${match.group(1)}',
    );

    return text;
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = IdentificationMessage(
      role: 'user',
      text: text.trim(),
    );

    textController.clear();
    messages.add(userMessage);
    notifyListeners();

    isLoading = true;
    isTyping = true;
    notifyListeners();

    // Simulate typing delay
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      await fetchAIResponse(text.trim());
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

      messages.add(IdentificationMessage(
        role: 'bot',
        text: errorMessage,
      ));
    } finally {
      isLoading = false;
      isTyping = false;
      notifyListeners();
    }
  }

  Future<void> pickImageFromCamera() async {
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (image == null) return;
    _imagePath = image.path;
    await _processImage(File(image.path));
  }

  Future<void> pickImageFromGallery() async {
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (image == null) return;
    _imagePath = image.path;
    await _processImage(File(image.path));
  }

  Future<void> _processImage(File imageFile) async {
    final userMessageIndex = messages.length;
    _messageImages[userMessageIndex] = imageFile;
    _selectedImage = imageFile;
    isLoading = true;
    notifyListeners();

    messages.add(
      IdentificationMessage(
        role: 'user',
        text: '[Image]',
        image: imageFile,
      ),
    );
    notifyListeners();

    try {
      final String identificationResult = await identifyImage(imageFile);
      messages.add(IdentificationMessage(
        role: 'bot',
        text: identificationResult.trim(),
      ));
    } catch (e) {
      messages.add(IdentificationMessage(
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

  Future<String> identifyImage(File image) async {
    final extractedText = await extractTextFromImage(image);

    final response = await http.post(
      ApiConfig.openaiBaseUrl as Uri,  // Using the secure endpoint from ApiConfig
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [{
          "parts": [{
            "text": "You are an expert identification assistant. Analyze this image content and provide:\n\n"
                "Image contains text: $extractedText\n\n"
                "1) Clear identification of the main subject\n"
                "2) Key characteristics (size, color, shape, etc.)\n"
                "3) Interesting facts or context if relevant\n"
                "4) Format response with clear headings and bullet points\n"
                "5) If uncertain, mention possible alternatives"
          }]
        }],
      }),
    ).timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final text = jsonResponse['candidates'][0]['content']['parts'][0]['text'] as String;
      return _formatResponse(text);
    } else {
      throw Exception("Failed to identify image: ${response.statusCode}");
    }
  }

  Future<void> fetchAIResponse(String prompt) async {
    if (prompt.trim().isEmpty) {
      messages.add(IdentificationMessage(
        role: 'bot',
        text: "Please provide a description of what you want to identify.",
      ));
      notifyListeners();
      return;
    }

    try {
      final response = await http.post(
        ApiConfig.openaiBaseUrl as Uri,  // Using the secure endpoint from ApiConfig
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [{
            "parts": [{
              "text": "You are 'Identify Everything AI', a friendly identification assistant. "
                  "Format responses clearly using:\n"
                  "1. SECTION HEADINGS: ALL CAPS with colon (e.g., \"IDENTIFICATION:\", \"KEY DETAILS:\")\n"
                  "2. DETAILS: Prefix with \"- \"\n"
                  "3. INTERESTING FACTS: Prefix with \"• \"\n"
                  "4. Keep explanations clear and concise\n\n"
                  "User request: $prompt"
            }]
          }],
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        String text = jsonResponse['candidates'][0]['content']['parts'][0]['text'] as String;
        text = _formatResponse(text);

        messages.add(IdentificationMessage(
          role: 'bot',
          text: text,
        ));
      } else {
        throw Exception("API Error ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      messages.add(IdentificationMessage(
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

  void clearImage() {
    _selectedImage = null;
    _imagePath = null;
    notifyListeners();
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }
}