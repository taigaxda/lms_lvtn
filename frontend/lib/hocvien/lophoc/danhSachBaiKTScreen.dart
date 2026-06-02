import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/hocvien/lophoc/lamBaiKTScreen.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/api.dart';
import 'package:frontend/hocvien/menuUI/hocVienMenuBar.dart';
import 'package:frontend/hocvien/lophoc/hocBaiScreen.dart';

class Danhsachbaiktscreen extends StatefulWidget {
  final int idKhoaHoc;

  const Danhsachbaiktscreen({super.key, required this.idKhoaHoc});

  @override
  State<Danhsachbaiktscreen> createState() => _DanhsachbaiktscreenState();
}

class _DanhsachbaiktscreenState extends State<Danhsachbaiktscreen> {
  List quizzes = [];
  bool isLoading = true;

  final String apiUrl = '${ApiConfig.baseUrl}/hocvien';

  @override
  void initState() {
    super.initState();
    loadQuiz();
  }

  Future<void> loadQuiz() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt("userId");

    final res = await http.get(
      Uri.parse('$apiUrl/quiz/dsquiz/${widget.idKhoaHoc}'),
      headers: {
        "Content-Type": "application/json",
        "x-user-id": userId.toString(),
      },
    );
    if (res.statusCode == 200) {
      quizzes = json.decode(res.body)['data'];
    }
    setState(() => isLoading = false);
  }

  Future<void> openLamBaiKTScreen(Map q) async {
    if (q['daLam']) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Đã làm rồi")));
      return;
    }
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => Lambaiktscreen(idQuiz: q['idQuiz'])),
    );
    if (result == true) {
      await loadQuiz();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Bài kiểm tra",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Thống kê bài kiểm tra",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text("Tổng bài kiểm tra: ${quizzes.length}"),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: quizzes.length,
                    itemBuilder: (context, index) {
                      final q = quizzes[index];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: CircleAvatar(
                            backgroundColor: Colors.purple.withOpacity(0.1),
                            child: const Icon(Icons.quiz, color: Colors.purple),
                          ),
                          title: Text(
                            q['tenQuiz'] ?? "",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),

                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: q['daLam']
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  q['daLam']
                                      ? "Đã làm - Điểm: ${q['diem'] ?? 0}"
                                      : "Chưa làm",
                                  style: TextStyle(
                                    color: q['daLam']
                                        ? Colors.green
                                        : Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 6),

                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text("${q['thoiGianLamBai'] ?? 0} phút"),
                                ],
                              ),

                              const SizedBox(height: 6),

                              const Text(
                                "Nhấn vào để làm bài",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blueGrey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),

                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),

                          onTap: () => openLamBaiKTScreen(q),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
