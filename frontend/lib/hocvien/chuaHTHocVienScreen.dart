import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/hocvien/menuUI/hocVienMenuBar.dart';
import 'package:frontend/api.dart';
import 'package:frontend/hocvien/lophoc/chiTietLopHocHV.dart';
import 'package:frontend/hocvien/lophoc/danhSachBaiKTScreen.dart';
import 'package:frontend/hocvien/lophoc/baitap/dsBaiTapHVScreen.dart';
import './lophoc/hocBaiScreen.dart';
import './lophoc/baitap/chiTietBaiTapHVScreen.dart';
import './lophoc/lamBaiKTScreen.dart';

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
  List baiTapChuaNop = [];

  bool isLoading = true;

  final String apiBaiHoc = '${ApiConfig.baseUrl}/hocvien/baihoc/chuahoc';
  final String apiQuiz = '${ApiConfig.baseUrl}/hocvien/quiz/chualam';
  final String apiBaiTap = '${ApiConfig.baseUrl}/hocvien/baitap/chuanop';

  String hoTen = "";
  String vaiTro = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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

      final resBaiHoc = await http.get(
        Uri.parse(apiBaiHoc),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

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
          print("Lỗi quiz: ${resQuiz.statusCode}");
          if (mounted) {
            setState(() {
              quizChuaLam = [];
            });
          }
        }
      } catch (e) {
        print("Lỗi quiz: $e");
        if (mounted) {
          setState(() {
            quizChuaLam = [];
          });
        }
      }

      if (resBaiHoc.statusCode == 200) {
        final dataBH = json.decode(resBaiHoc.body);
        if (mounted) {
          setState(() {
            khoaHocs = dataBH["data"] ?? [];
          });
        }
      } else {
        throw Exception("Lỗi load bài học: ${resBaiHoc.statusCode}");
      }

      try {
        final resBaiTap = await http.get(
          Uri.parse(apiBaiTap),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
        );

        if (resBaiTap.statusCode == 200) {
          final dataBaiTap = json.decode(resBaiTap.body);
          if (mounted) {
            setState(() {
              baiTapChuaNop = dataBaiTap["data"] ?? [];
              isLoading = false;
            });
          }
        } else {
          print("Lỗi bài tập: ${resBaiTap.statusCode}");
          if (mounted) {
            setState(() {
              baiTapChuaNop = [];
              isLoading = false;
            });
          }
        }
      } catch (e) {
        print("Lỗi bài tập: $e");
        if (mounted) {
          setState(() {
            baiTapChuaNop = [];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Lỗi fetch: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Lỗi tải dữ liệu: $e")));
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
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            subText ?? "Hãy tiếp tục học tập nhé!",
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildBaiTapItem(Map baiTap, String tenKhoaHoc, int idKhoaHoc) {
    final isQuaHan = baiTap['isQuaHan'] ?? false;
    final conLai = baiTap['conLai'] ?? 0;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isQuaHan
            ? Colors.red.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        child: Icon(
          isQuaHan ? Icons.warning : Icons.assignment,
          color: isQuaHan ? Colors.red : Colors.orange,
        ),
      ),
      title: Text(
        baiTap['tieuDe'] ?? '',
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isQuaHan ? Colors.red : null,
        ),
      ),
      subtitle: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isQuaHan
                  ? Colors.red.withOpacity(0.1)
                  : conLai <= 1
                  ? Colors.orange.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isQuaHan
                  ? 'Quá hạn'
                  : conLai <= 1
                  ? 'Sắp hết hạn'
                  : 'Còn $conLai ngày',
              style: TextStyle(
                fontSize: 10,
                color: isQuaHan
                    ? Colors.red
                    : conLai <= 1
                    ? Colors.orange
                    : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.access_time, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Text(
            _formatDate(baiTap['hanNop']),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ChiTietBaiTapHVScreen(idAssignment: baiTap['idAssignment']),
          ),
        );
      },
    );
  }

  Widget _buildBaiTapCard(Map kh) {
    final assignments = kh['assignments'] as List? ?? [];
    if (assignments.isEmpty) return const SizedBox.shrink();

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
                colors: [Colors.orange, Colors.orangeAccent],
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.assignment, color: Colors.white),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${assignments.length} bài tập',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: assignments
                .map(
                  (baiTap) => _buildBaiTapItem(
                    baiTap,
                    kh['tenKhoaHoc'] ?? '',
                    kh['idKhoaHoc'],
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBaiTapList() {
    if (baiTapChuaNop.isEmpty) {
      return _buildEmpty(
        "Không có bài tập nào chưa nộp!",
        subText: "Bạn đã hoàn thành tất cả bài tập 🎉",
      );
    }

    int totalBaiTap = 0;
    int soBaiQuaHan = 0;
    for (var kh in baiTapChuaNop) {
      final assignments = kh['assignments'] as List? ?? [];
      totalBaiTap += assignments.length;
      for (var baiTap in assignments) {
        if (baiTap['isQuaHan'] == true) {
          soBaiQuaHan++;
        }
      }
    }

    return RefreshIndicator(
      onRefresh: fetchData,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: baiTapChuaNop.length,
        itemBuilder: (context, index) {
          return _buildBaiTapCard(baiTapChuaNop[index]);
        },
      ),
    );
  }

  Widget _buildBaiHocItem(Map bh, int idKhoaHoc) {
    final progressList = bh['progress'] as List? ?? [];
    final progress = progressList.isNotEmpty ? progressList[0] : null;

    final trangThai = progress?['trangThai'] ?? 'chua_hoc';
    final laVideo = bh['videoUrl'] != null  && bh['videoUrl'].toString().isNotEmpty; 
    final laTaiLieu = bh['taiLieuUrl'] != null  && bh['taiLieuUrl'].toString().isNotEmpty;

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
        if(laVideo){
          iconData = Icons.play_circle_outline;
        }
        else{
          iconData = Icons.description_outlined;
        }
    }

    final isDangHoc = trangThai == 'dang_hoc';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(iconData, color: color),
      ),
      title: Text(
        bh['tenBaiHoc'] ?? '',
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDangHoc ? Colors.orange.shade700 : null,
        ),
      ),
      subtitle: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$statusText',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8,),
          if (laVideo)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.videocam, size: 12, color: Colors.blue),
                SizedBox(width: 2),
                Text(
                  'Video',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        if (laTaiLieu && !laVideo)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.description, size: 12, color: Colors.green),
                SizedBox(width: 2),
                Text(
                  'Tài liệu',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (isDangHoc) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Tiếp tục',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${baihocs.length} bài',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
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

  bool quizQuaHan(String? ngayDenHan) {
    if (ngayDenHan == null) return false;
    final hanNop = DateTime.tryParse(ngayDenHan);
    if (hanNop == null) return false;
    return DateTime.now().isAfter(hanNop);
  }

  Widget _buildQuizItem(Map quiz, int idKhoaHoc) {
    final daQuaHan = quizQuaHan(quiz['ngayDenHan']);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: daQuaHan
            ? Colors.red.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        child: Icon(
          daQuaHan ? Icons.lock : Icons.quiz,
          color: daQuaHan ? Colors.grey : Colors.red,
        ),
      ),
      title: Text(
        quiz['tenQuiz'] ?? '',
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: daQuaHan ? Colors.grey : null,
        ),
      ),
      subtitle: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              daQuaHan ? 'Quá hạn' : '${quiz['thoiGianLamBai'] ?? 0} phút',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Text(
            _formatDate(quiz['ngayDenHan']),
            style: TextStyle(
              fontSize: 12,
              color: daQuaHan ? Colors.red : Colors.grey,
            ),
          ),
        ],
      ),
      trailing: Icon(daQuaHan ? Icons.lock : Icons.arrow_forward_ios, size: 16),
      onTap: () {
        daQuaHan
            ? null
            : Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Lambaiktscreen(idQuiz: quiz['idQuiz']),
                ),
              );
      },
      tileColor: daQuaHan ? Colors.grey.shade50 : null,
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
              gradient: LinearGradient(colors: [Colors.red, Colors.redAccent]),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${quizzes.length} quiz',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
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
    return "${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}";
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
            Tab(text: "Bài tập"),
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
                _buildBaiTapList(),
              ],
            ),
    );
  }
}
