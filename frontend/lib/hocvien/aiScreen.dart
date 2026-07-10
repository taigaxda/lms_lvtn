import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/api.dart';

class Aiscreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _AiscreenState();
  }
}

class _AiscreenState extends State<Aiscreen> {
  List<String> suggestions = [];
  List<Map<String, String>> chat = [];
  bool isLoading = false;
  TextEditingController _cauHoiController = TextEditingController();
  final String api = '${ApiConfig.baseUrl}/hocvien/ai';
  @override
  void initState() {
    super.initState();
    fetchSuggestions();
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  Future<void> fetchSuggestions() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$api/dexuat'),
      headers: {"Authorization": "Bearer $token"},
    );
    final data = jsonDecode(response.body);
    setState(() {
      suggestions = List<String>.from(data["data"].map((q) => q["question"]));
    });
  }

  Future<void> datCauHoi(String cauHoi) async {
    final token = await getToken();
    setState(() {
      isLoading = true;
      chat.add({"role": "user", "text": cauHoi});
    });
    final response = await http.post(
      Uri.parse('$api/ask'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"question": cauHoi}),
    );
    final data = jsonDecode(response.body);
    setState(() {
      chat.add({"role": "ai", "text": data["data"]["answer"]});
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text("Trợ lý AI"),
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          if (suggestions.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb,
                        color: Colors.amber.shade700,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Câu hỏi gợi ý:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: suggestions.map((q) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            label: Text(q),
                            onPressed: isLoading ? null : () => datCauHoi(q),
                            backgroundColor: Colors.blue.shade50,
                            side: const BorderSide(color: Colors.blue),
                            labelStyle: const TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          Divider(),

          Expanded(
            child: ListView(
              padding: EdgeInsets.all(10),
              children: chat.map((msg) {
                bool isUser = msg["role"] == "user";

                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 5),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      msg["text"] ?? "",
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          if (isLoading)
            Padding(
              padding: EdgeInsets.all(10),
              child: CircularProgressIndicator(),
            ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cauHoiController,
                    decoration: InputDecoration(
                      hintText: "Nhập câu hỏi...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        datCauHoi(value);
                        _cauHoiController.clear();
                      }
                    },
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blue),
                  onPressed: () {
                    String text = _cauHoiController.text.trim();
                    if (text.isNotEmpty) {
                      datCauHoi(text);
                      _cauHoiController.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
