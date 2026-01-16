import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/config.dart';

class EmailAssistantScreen extends StatefulWidget {
  const EmailAssistantScreen({super.key});

  @override
  EmailAssistantScreenState createState() => EmailAssistantScreenState();
}

class EmailAssistantScreenState extends State<EmailAssistantScreen> {
  final TextEditingController _emailPromptController = TextEditingController();
  bool _isGenerating = false;
  String _generatedContent = '';
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _emailPromptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> generateEmailContent() async {
    if (_emailPromptController.text.isEmpty) return;

    setState(() {
      _isGenerating = true;
      _generatedContent = '';
    });

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.openaiBaseUrl),  // Using the secure endpoint from ApiConfig
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': 'You are a professional email assistant. Generate a well-structured email based on the following request:\n\n${_emailPromptController.text}'}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final generatedText = data['candidates'][0]['content']['parts'][0]['text'];
        setState(() {
          _generatedContent = generatedText;
        });
      } else {
        setState(() {
          _generatedContent = 'Error: Failed to generate email content. Status code: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _generatedContent = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isGenerating = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Email Assistant'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.blueGrey.shade800,
        iconTheme: IconThemeData(color: Colors.blueGrey.shade800),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    InputCard(
                      controller: _emailPromptController,
                      onGeneratePressed: generateEmailContent,
                      isGenerating: _isGenerating,
                    ),
                    const SizedBox(height: 20),
                    if (_generatedContent.isNotEmpty)
                      ResultCard(content: _generatedContent),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InputCard extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onGeneratePressed;
  final bool isGenerating;

  const InputCard({
    super.key,
    required this.controller,
    required this.onGeneratePressed,
    required this.isGenerating,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  FontAwesomeIcons.solidEnvelope,
                  color: Colors.blueGrey.shade800,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Email Request',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Describe the email you want to generate...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Colors.grey.withAlpha(50),
                  ),
                ),
                filled: true,
                fillColor: Colors.grey.withAlpha(15),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isGenerating ? null : onGeneratePressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                icon: isGenerating
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
                    : const Icon(FontAwesomeIcons.wandMagicSparkles, size: 16),
                label: Text(
                  isGenerating ? 'Generating...' : 'Generate Email',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ResultCard extends StatelessWidget {
  final String content;

  const ResultCard({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Row(
        children: [
        Icon(
        FontAwesomeIcons.solidFileLines,
          color: Colors.blueGrey.shade800,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          'Generated Email',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey.shade800,
          ),
        ),
        ],
      ),
      const SizedBox(height: 12),
      Container(
        decoration: BoxDecoration(
          color: Colors.grey.withAlpha(15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey.withAlpha(50),
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: double.infinity,
          child: MarkdownBody(
            data: content,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.blueGrey.shade800,
              ),
              h1: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey.shade900,
              ),
              h2: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey.shade800,
              ),
              h3: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey.shade700,
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton.icon(
            onPressed: () {
              // Implement copy functionality
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blueGrey.shade800,
              side: BorderSide(color: Colors.blueGrey.shade400),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: Icon(FontAwesomeIcons.copy, size: 14, color: Colors.blueGrey.shade800),
            label: Text('Copy', style: TextStyle(color: Colors.blueGrey.shade800))),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                // Implement save functionality
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(FontAwesomeIcons.floppyDisk, size: 14),
              label: const Text('Save Draft'),
            ),
            ],
          ),
        ],
      ),
    ),
    );
  }
}