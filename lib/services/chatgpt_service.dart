import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatGPTService {
  final String _apiKey = 'YOUR_OPENAI_API_KEY';

  Future<String> getPersonalizedQuest(
      List<String> userResponses, int streak) async {
    final url = 'https://api.openai.com/v1/chat/completions';

    // Construct the prompt
    String prompt = '''
You are an assistant that creates personalized daily quests for users based on their goals. Generate a quest that helps the user improve themselves, considering their responses and current streak of $streak days.

User Responses:
1. ${userResponses[0]}
2. ${userResponses[1]}
3. ${userResponses[2]}

Provide the quest in one or two sentences.
''';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini', // Use the appropriate model you have access to
        'messages': [
          {'role': 'system', 'content': 'You are a helpful assistant.'},
          {'role': 'user', 'content': prompt},
        ],
        'max_tokens': 150,
      }),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      String quest = data['choices'][0]['message']['content'].trim();
      return quest;
    } else {
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('Failed to load quest');
    }
  }
}
