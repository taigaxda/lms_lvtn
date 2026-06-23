import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/hocvien/menuUI/hocVienMenuBar.dart';
import 'package:frontend/api.dart';
import 'package:frontend/hocvien/lophoc/chiTietLopHocHV.dart';
import 'package:frontend/hocvien/lophoc/danhSachBaiKTScreen.dart';

class ChuaHTHocVienScreen extends StatefulWidget {
  const ChuaHTHocVienScreen({super.key});

  @override
  State<ChuaHTHocVienScreen> createState() => _ChuaHTHocVienScreenState();
}

class _ChuaHTHocVienScreenState extends State<ChuaHTHocVienScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;

  List khoaHocs = [];
  List quizChuaLam = [];

  bool isLoading = true;

  final String apiBaiHoc = '${ApiConfig.baseUrl}/hocvien/baihoc/chuahoc';
  final String apiQuiz = '${ApiConfig.baseUrl}/hocvien/quiz/chualam';

  String hoTen = "";
  String vaiTro = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    loadUserInfo();
    fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        hoTen = prefs.getString("hoTen") ?? "";
        vaiTro = prefs.getString("vaiTro") ?? "";
      });
    }
  }

  Future<void> fetchData() async {
    try {
      setState(() => isLoading = true);
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null || token.isEmpty) {
        throw Exception("Chưa đăng nhập");
      }

      // ✅ Gọi API bài học
      final resBaiHoc = await http.get(
        Uri.parse(apiBaiHoc),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      // ✅ Gọi API quiz (xử lý lỗi riêng)
      try {
        final resQuiz = await http.get(
          Uri.parse(apiQuiz),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
        );
        
        if (resQuiz.statusCode == 200) {
          final dataQuiz = json.decode(resQuiz.body);
          if (mounted) {
            setState(() {
              quizChuaLam = dataQuiz["data"] ?? [];
            });
          }
        } else {
          print("⚠️ Lỗi quiz: ${resQuiz.statusCode}");
          if (mounted) {
            setState(() {
              quizChuaLam = [];
            });
          }
        }
      } catch (e) {
        print("⚠️ Lỗi quiz: $e");
        if (mounted) {
          setState(() {
            quizChuaLam = [];
          });
        }
      }

      // ✅ Xử lý bài học
      if (resBaiHoc.statusCode == 200) {
        final dataBH = json.decode(resBaiHoc.body);
        if (mounted) {
          setState(() {
            khoaHocs = dataBH["data"] ?? [];
            isLoading = false;
          });
        }
      } else {
        throw Exception("Lỗi load bài học: ${resBaiHoc.statusCode}");
      }
      
    } catch (e) {
      print("❌ Lỗi fetch: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi tải dữ liệu: $e")),
        );
        setState(() => isLoading = false);
      }
    }
  }

  Widget _buildEmpty(String text, {String? subText}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subText ?? "Hãy tiếp tục học tập nhé! 💪",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBaiHocItem(Map bh, int idKhoaHoc) {
    final progress = (bh['progress'] != null && bh['progress'].isNotEmpty)
        ? bh['progress'][0]
        : null;

    final trangThai = progress?['trangThai'] ?? 'chua_hoc';

    Color color;
    String statusText;
    IconData iconData;
    
    switch (trangThai) {
      case "dang_hoc":
        color = Colors.orange;
        statusText = "Đang học";
        iconData = Icons.play_circle;
        break;
      case "hoan_thanh":
        color = Colors.green;
        statusText = "Đã học";
        iconData = Icons.check_circle;
        break;
      default:
        color = Colors.grey;
        statusText = "Chưa học";
        iconData = Icons.play_circle_outline;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(iconData, color: color),
      ),
      title: Text(
        bh['tenBaiHoc'] ?? '',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          statusText,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChiTietLopHocHVScreen(idKhoaHoc: idKhoaHoc),
          ),
        );
      },
    );
  }

  Widget _buildKhoaHocCard(Map kh) {
    final baihocs = kh['baihoc'] as List? ?? [];
    if (baihocs.isEmpty) return const SizedBox.shrink();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.blueAccent],
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.school, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    kh['tenKhoaHoc'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${baihocs.length} bài',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: baihocs
                .map((bh) => _buildBaiHocItem(bh, kh['idKhoaHoc']))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizItem(Map quiz, int idKhoaHoc) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.red.withOpacity(0.1),
        child: const Icon(Icons.quiz, color: Colors.red),
      ),
      title: Text(
        quiz['tenQuiz'] ?? '',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Row(
        children: [
          const Icon(Icons.timer, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Text(
            "${quiz['thoiGianLamBai'] ?? 0} phút",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Text(
            _formatDate(quiz['ngayDenHan']),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Danhsachbaiktscreen(idKhoaHoc: idKhoaHoc),
          ),
        );
      },
    );
  }
  
  Widget _buildQuizCard(Map kh) {
    final quizzes = kh['quizzes'] as List? ?? [];
    if (quizzes.isEmpty) return const SizedBox.shrink();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              gradient: LinearGradient(
                colors: [Colors.red, Colors.redAccent],
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.quiz, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    kh['tenKhoaHoc'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${quizzes.length} quiz',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: quizzes
                .map((q) => _buildQuizItem(q, kh['idKhoaHoc']))
                .toList(),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? date) {
    if (date == null) return "Không rõ";
    final d = DateTime.tryParse(date);
    if (d == null) return "Không rõ";
    return "${d.day}/${d.month}/${d.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chưa hoàn thành"),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Bài học"),
            Tab(text: "Bài kiểm tra"),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      drawer: Hocvienmenubar(hoTen: hoTen, vaiTro: vaiTro),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                khoaHocs.isEmpty
                    ? _buildEmpty("Không còn bài học nào chưa hoàn thành!")
                    : RefreshIndicator(
                        onRefresh: fetchData,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: khoaHocs.length,
                          itemBuilder: (context, index) {
                            return _buildKhoaHocCard(khoaHocs[index]);
                          },
                        ),
                      ),
                quizChuaLam.isEmpty
                    ? _buildEmpty("Không còn bài kiểm tra nào chưa làm!")
                    : RefreshIndicator(
                        onRefresh: fetchData,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: quizChuaLam.length,
                          itemBuilder: (context, index) {
                            return _buildQuizCard(quizChuaLam[index]);
                          },
                        ),
                      ),
              ],
            ),
    );
  }
}