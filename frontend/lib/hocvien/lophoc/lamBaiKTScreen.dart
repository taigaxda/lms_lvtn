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
  String? errorMessage;

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
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final res = await http.get(
        Uri.parse('$apiUrl/quiz/baikiemtra/${widget.idQuiz}'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'];
        if (data['questions'] == null || data['questions'].isEmpty) {
          setState(() {
            errorMessage =
                "Bài kiểm tra chưa có câu hỏi. Vui lòng quay lại sau.";
            isLoading = false;
          });
          return;
        }
        setState(() {
          quiz = data;
          questions = data['questions'];
          isLoading = false;
          errorMessage = null;
        });

        if (data['thoiGianLamBai'] != null) {
          remainingTime = data['thoiGianLamBai'] * 60;
          startTimer();
        } else {
          remainingTime = -1;
        }
      } else {
        final data = jsonDecode(res.body);
        setState(() {
          errorMessage = data['message'] ?? 'Không thể tải bài kiểm tra';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Lỗi kết nối server. Vui lòng thử lại.';
        isLoading = false;
      });
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
    final token = prefs.getString("token");

    List formattedAnswers = answers.entries.map((e) {
      return {"idCauHoi": int.parse(e.key), "idDapAn": int.parse(e.value)};
    }).toList();
    final res = await http.post(
      Uri.parse('$apiUrl/quiz/${widget.idQuiz}/nopbai'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"answers": formattedAnswers}),
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
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(data['message'] ?? "Lỗi")));
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
            Text("Câu hỏi: ${q['cauHoi']}"),
            const SizedBox(height: 10),
            ...q['answers'].map<Widget>((a) {
              return RadioListTile(
                title: Text(a['noiDung']),
                value: a['idDapAn'].toString(),
                groupValue: answers[id],
                onChanged: (value) {
                  setState(() {
                    answers[id] = value!;
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
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : remainingTime == -1
                  ? const Text("Không giới hạn")
                  : Text(formatTime(remainingTime)),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage !=
                null // ✅ Kiểm tra errorMessage
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      errorMessage!,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text("Quay lại"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : questions.isEmpty
          ? const Center(
              child: Text(
                "Bài kiểm tra không có câu hỏi",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 80),
                    children: questions.map((q) => buildQuestion(q)).toList(),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Đã trả lời: ${answers.length}/${questions.length}",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: submitQuiz,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(120, 45),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text("Nộp bài"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
