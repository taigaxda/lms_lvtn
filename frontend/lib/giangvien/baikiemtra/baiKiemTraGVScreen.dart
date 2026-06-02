import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/api.dart';
import 'package:frontend/giangvien/menuUI/giangVienMenuBar.dart';
import 'package:frontend/giangvien/baikiemtra/addBaiKiemTraGVScreen.dart';
import 'cauHoiGVScreen.dart';

class Baikiemtragvscreen extends StatefulWidget {
  final int idKhoaHoc;
  const Baikiemtragvscreen({super.key, required this.idKhoaHoc});

  @override
  State<Baikiemtragvscreen> createState() => _BaikiemtragvscreenState();
}

class _BaikiemtragvscreenState extends State<Baikiemtragvscreen> {
  List quizzes = [];
  bool isLoading = true;
  String hoTen = "";
  String vaiTro = "";

  final String apiUrl = '${ApiConfig.baseUrl}/giangvien/quiz';

  @override
  void initState() {
    super.initState();
    loadUserInfo();
    fetchQuiz();
  }

  Future<void> loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      hoTen = prefs.getString("hoTen") ?? "";
      vaiTro = prefs.getString("vaiTro") ?? "";
    });
  }

  Future<void> fetchQuiz() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt("userId");

      final res = await http.get(
        Uri.parse('$apiUrl/${widget.idKhoaHoc}'),
        headers: {
          "Content-Type": "application/json",
          "x-user-id": userId.toString(),
        },
      );
      final data = jsonDecode(res.body);
      if (data["success"]) {
        setState(() {
          quizzes = data["data"];
        });
      }
    } catch (e) {
      debugPrint("Lỗi fetch quiz: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> deleteQuiz(int idQuiz) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt("userId");
    final res = await http.delete(
      Uri.parse('$apiUrl/$idQuiz'),
      headers: {
        "Content-Type": "application/json",
        "x-user-id": userId.toString(),
      },
    );
    final data = jsonDecode(res.body);

    if (data["success"]) {
      fetchQuiz();
    }
  }

  void confirmDelete(int idQuiz) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Xác nhận"),
        content: const Text("Bạn có chắc muốn xoá bài kiểm tra?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Huỷ"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              deleteQuiz(idQuiz);
            },
            child: const Text("Xoá"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Màu nền xám nhạt cho sang
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: false,
        title: const Text("Quản lý bài kiểm tra", style: TextStyle()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      drawer: GiangVienMenuBar(hoTen: hoTen, vaiTro: vaiTro),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  AddBaiKiemTraGVScreen(idKhoaHoc: widget.idKhoaHoc),
            ),
          );
          fetchQuiz();
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Thêm Quiz", style: TextStyle(color: Colors.white)),
      ),
      body: RefreshIndicator(
        onRefresh: fetchQuiz,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Danh sách bài kiểm tra",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Colors.white70,
                                size: 16,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                "Lớp hiện tại có ${quizzes.length} bài kiểm tra",
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                    sliver: quizzes.isEmpty
                        ? const SliverToBoxAdapter(
                            child: Center(
                              child: Padding(
                                padding: EdgeInsets.only(top: 50),
                                child: Text(
                                  "Chưa có bài kiểm tra nào",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final quiz = quizzes[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(12),
                                  leading: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.assignment_turned_in,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  title: Text(
                                    quiz["tenQuiz"] ?? "Không tên",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.timer_outlined,
                                          size: 14,
                                          color: Colors.grey,
                                        ),
                                        Text("${quiz["thoiGianLamBai"] ?? 0}m"),

                                        const Icon(
                                          Icons.help_outline,
                                          size: 14,
                                          color: Colors.grey,
                                        ),
                                        Text(
                                          "${quiz["quiz_questions"]?.length ?? 0} câu",
                                        ),

                                        const Text(
                                          "Nhấn xem chi tiết",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.arrow_forward_ios,
                                          size: 12,
                                          color: Colors.blue,
                                        ),
                                      ],
                                    ),
                                  ),
                                  trailing: Wrap(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit_note,
                                          color: Colors.orange,
                                          size: 28,
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  Cauhoigvscreen(quiz: quiz),
                                            ),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.redAccent,
                                        ),
                                        onPressed: () =>
                                            confirmDelete(quiz["idQuiz"]),
                                      ),
                                    ],
                                  ),
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AddBaiKiemTraGVScreen(
                                          quiz: quiz,
                                          idKhoaHoc: widget.idKhoaHoc,
                                        ),
                                      ),
                                    );
                                    fetchQuiz();
                                  },
                                ),
                              );
                            }, childCount: quizzes.length),
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
