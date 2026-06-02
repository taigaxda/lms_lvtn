import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/api.dart';

class Lambaiktscreen extends StatefulWidget {
  final int idQuiz;

  const Lambaiktscreen({super.key, required this.idQuiz});

  @override
  State<Lambaiktscreen> createState() => _LamBaiKTScreenState();
}

class _LamBaiKTScreenState extends State<Lambaiktscreen> {
  bool isLoading = true;
  Map<String, dynamic>? quiz;
  List questions = [];

  Map<String, String> answers = {};

  final String apiUrl = '${ApiConfig.baseUrl}/hocvien';

  Timer? timer;
  int remainingTime = 0;

  @override
  void initState() {
    super.initState();
    loadQuiz();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> loadQuiz() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt("userId");

    final res = await http.get(
      Uri.parse('$apiUrl/quiz/baikiemtra/${widget.idQuiz}'),
      headers: {
        "Content-Type": "application/json",
        "x-user-id": userId.toString(),
      },
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body)['data'];

      setState(() {
        quiz = data;
        questions = data['questions'];
        remainingTime = (data['thoiGianLamBai'] ?? 0) * 60;
        isLoading = false;
      });

      startTimer();
    }
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remainingTime <= 0) {
        t.cancel();
        autoSubmit();
      } else {
        setState(() {
          remainingTime--;
        });
      }
    });
  }

  String formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  Future<void> submitQuiz() async {
    timer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt("userId");

    final res = await http.post(
      Uri.parse('$apiUrl/quiz/${widget.idQuiz}/nopbai'),
      headers: {
        "Content-Type": "application/json",
        "x-user-id": userId.toString(),
      },
      body: jsonEncode({
        "answers": answers,
      }),
    );

    final data = jsonDecode(res.body);

    if (res.statusCode == 200) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text("Kết quả"),
          content: Text("Điểm: ${data['data']['diem']}"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, true);
              },
              child: const Text("OK"),
            )
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? "Lỗi")),
      );
    }
  }

  void autoSubmit() {
    submitQuiz();
  }

  Widget buildQuestion(Map q) {
    String id = q['idCauHoi'].toString();
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Câu hỏi: ${q['question']}"),
            const SizedBox(height: 10),
            ...['A', 'B', 'C', 'D'].map((key) {
              return RadioListTile(
                title: Text(q[key]),
                value: key,
                groupValue: answers[id],
                onChanged: (val) {
                  setState(() {
                    answers[id] = val!;
                  });
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(quiz?['tenQuiz'] ?? "Đang tải..."),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Center(
              child: Text(
                formatTime(remainingTime),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    children:
                        questions.map((q) => buildQuestion(q)).toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: ElevatedButton(
                    onPressed: submitQuiz,
                    child: const Text("Nộp bài"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                )
              ],
            ),
    );
  }
}