import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

class OpenAIService {
  static Future<String> chat(String prompt) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.openaiBaseUrl}/chat/completions"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${ApiConfig.openaiApiKey}",
      },
      body: jsonEncode({
        "model": ApiConfig.model,
        "messages": [
          {"role": "user", "content": prompt}
        ],
        "temperature": 0.7,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("OpenAI error: ${response.body}");
    }

    final data = jsonDecode(response.body);
    return data["choices"][0]["message"]["content"];
  }
}
