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

  Future<void> loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      hoTen = prefs.getString("hoTen") ?? "";
      vaiTro = prefs.getString("vaiTro") ?? "";
    });
  }

  Future<void> fetchData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt("userId");

      final resBaiHoc = await http.get(
        Uri.parse(apiBaiHoc),
        headers: {
          "Content-Type": "application/json",
          "x-user-id": userId?.toString() ?? "",
        },
      );

      final resQuiz = await http.get(
        Uri.parse(apiQuiz),
        headers: {
          "Content-Type": "application/json",
          "x-user-id": userId?.toString() ?? "",
        },
      );

      if (resBaiHoc.statusCode == 200 && resQuiz.statusCode == 200) {
        final dataBH = json.decode(resBaiHoc.body);
        final dataQuiz = json.decode(resQuiz.body);
        setState(() {
          khoaHocs = dataBH["data"] ?? [];
          quizChuaLam = dataQuiz["data"] ?? [];
          isLoading = false;
        });
      } else {
        throw Exception("Lỗi load API");
      }
    } catch (e) {
      print("Lỗi fetch: $e");
      setState(() => isLoading = false);
    }
  }

  Widget _buildEmpty(String text) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildBaiHocItem(Map bh, int idKhoaHoc) {
    final progress = (bh['progress'] != null && bh['progress'].isNotEmpty)
        ? bh['progress'][0]
        : null;

    final trangThai = progress?['trangThai'] ?? 'chua_hoc';

    Color color = trangThai == "dang_hoc"
        ? Colors.orange
        : Colors.grey;

    return ListTile(
      leading: Icon(Icons.play_circle, color: color),
      title: Text(bh['tenBaiHoc'] ?? ''),
      subtitle: Text("Trạng thái: $trangThai"),
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
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.blue.shade300],
              ),
            ),
            child: Text(
              kh['tenKhoaHoc'] ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Column(
            children: (kh['baihoc'] as List)
                .map((bh) => _buildBaiHocItem(bh, kh['idKhoaHoc']))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizItem(Map quiz,int idKhoaHoc) {
    return ListTile(
      leading: const Icon(Icons.quiz, color: Colors.red),
      title: Text(quiz['tenQuiz'] ?? ''),
      subtitle: Text("Thời gian: ${quiz['thoiGianLamBai']} phút"),
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
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              gradient: LinearGradient(
                colors: [Colors.red, Colors.red.shade300],
              ),
            ),
            child: Text(
              kh['tenKhoaHoc'] ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Column(
            children: (kh['quizzes'] as List)
                .map((q) => _buildQuizItem(q,kh['idKhoaHoc']))
                .toList(),
          ),
        ],
      ),
    );
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
          tabs: [
            Tab(text: "Bài học",),
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
                    ? _buildEmpty("Không còn bài chưa học")
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: khoaHocs.length,
                        itemBuilder: (context, index) {
                          return _buildKhoaHocCard(khoaHocs[index]);
                        },
                      ),

                quizChuaLam.isEmpty
                    ? _buildEmpty("Không còn bài kiểm tra nào để làm")
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: quizChuaLam.length,
                        itemBuilder: (context, index) {
                          return _buildQuizCard(quizChuaLam[index]);
                        },
                      ),
              ],
            ),
    );
  }
}