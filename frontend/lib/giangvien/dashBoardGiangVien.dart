import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:frontend/api.dart';
import 'package:frontend/giangvien/menuUI/giangVienMenuBar.dart';

class DashboardGVScreen extends StatefulWidget {
  const DashboardGVScreen({super.key});

  @override
  State<DashboardGVScreen> createState() => _DashboardGVScreenState();
}

class _DashboardGVScreenState extends State<DashboardGVScreen> {
  Map<String, dynamic> overview = {};
  List recentClasses = [];
  List topClasses = [];
  List progressStats = [];
  List upcomingDeadlines = [];
  List quizzesWithoutResults = [];
  Map<String, dynamic> avgScores = {};

  bool isLoading = true;

  final String apiUrl = '${ApiConfig.baseUrl}/giangvien/lophoc/dashboard';

  String hoTen = "";
  String vaiTro = "";

  @override
  void initState() {
    super.initState();
    loadUserInfo();
    fetchDashboard();
  }

  Future<void> loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      hoTen = prefs.getString("hoTen") ?? "";
      vaiTro = prefs.getString("vaiTro") ?? "";
    });
  }

  Future<void> fetchDashboard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          overview = data["overview"] ?? {};
          recentClasses = data["recentClasses"] ?? [];
          topClasses = data["topClasses"] ?? [];
          progressStats = data["progressStats"] ?? [];
          upcomingDeadlines = data["upcomingDeadlines"] ?? [];
          quizzesWithoutResults = data["quizzesWithoutResults"] ?? [];
          avgScores = data["avgScores"] ?? {};
          isLoading = false;
        });
      } else {
        throw Exception("Lỗi load dashboard: ${response.statusCode}");
      }
    } catch (e) {
      print("Lỗi fetch dashboard: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildStatCard(
    String title,
    dynamic value,
    IconData icon, {
    Color? color,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: color != null
                ? [color, color.withOpacity(0.7)]
                : [Colors.blue, Colors.lightBlueAccent],
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 10),
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(title, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget buildPieChart() {
    if (progressStats.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text("Chưa có dữ liệu tiến độ"),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: progressStats.map((data) {
            final value = (data['count'] as int).toDouble();
            final status = data['trangThai'];
            Color color;
            String label;
            switch (status) {
              case 'hoan_thanh':
                color = Colors.green;
                label = "Đã học";
                break;
              case 'dang_hoc':
                color = Colors.orange;
                label = "Đang học";
                break;
              case 'chua_hoc':
                color = Colors.blue;
                label = "Chưa học";
                break;
              default:
                color = Colors.grey;
                label = status;
            }

            return PieChartSectionData(
              value: value,
              color: color,
              title: "$label\n${value.toInt()}",
              radius: 60,
              titleStyle: const TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget buildClassItem(Map c) {
    return ListTile(
      leading: const Icon(Icons.class_),
      title: Text(c['tenKhoaHoc'] ?? ''),
      subtitle: Text(
        "Code: ${c['code'] ?? ''} • ${c['totalStudents'] ?? 0} HV",
      ),
    );
  }

  Widget buildDeadlineItem(Map deadline) {
    final hanNop = DateTime.tryParse(deadline['hanNop'] ?? '');
    final conLai = hanNop != null
        ? hanNop.difference(DateTime.now()).inDays
        : 0;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: conLai <= 1
            ? Colors.red.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        child: Icon(
          Icons.assignment,
          color: conLai <= 1 ? Colors.red : Colors.orange,
        ),
      ),
      title: Text(
        deadline['tieuDe'] ?? '',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        "${deadline['tenKhoaHoc'] ?? ''} • Còn $conLai ngày",
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Text(
        "${deadline['totalSubmissions'] ?? 0} bài nộp",
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }

  Widget buildQuizItem(Map quiz) {
    return ListTile(
      leading: const Icon(Icons.quiz, color: Colors.purple),
      title: Text(
        quiz['tenQuiz'] ?? '',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(quiz['tenKhoaHoc'] ?? ''),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard Giảng Viên"),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        foregroundColor: Colors.white,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchDashboard,
          ),
        ],
      ),
      drawer: GiangVienMenuBar(hoTen: hoTen, vaiTro: vaiTro),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchDashboard,
              child: ListView(
                children: [
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      buildStatCard(
                        "Lớp học",
                        overview['totalClasses'] ?? 0,
                        Icons.class_,
                      ),
                      buildStatCard(
                        "Học viên",
                        overview['totalStudents'] ?? 0,
                        Icons.people,
                      ),
                    ],
                  ),

                  Row(
                    children: [
                      buildStatCard(
                        "Bài học",
                        overview['totalLessons'] ?? 0,
                        Icons.menu_book,
                      ),
                      buildStatCard(
                        "Quiz",
                        overview['totalQuizzes'] ?? 0,
                        Icons.quiz,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      buildStatCard(
                        "Bài tập",
                        overview['totalAssignments'] ?? 0,
                        Icons.assignment,
                        color: Colors.purple,
                      ),
                      buildStatCard(
                        "Chưa chấm",
                        overview['pendingSubmissions'] ?? 0,
                        Icons.pending,
                        color: Colors.orange,
                      ),
                    ],
                  ),

                  buildSectionTitle("Tiến độ học tập"),
                  Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        buildPieChart(),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 16,
                          children: [
                            _buildLegendItem(Colors.blue, "Chưa học"),
                            _buildLegendItem(Colors.orange, "Đang học"),
                            _buildLegendItem(Colors.green, "Đã học"),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (avgScores.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.assessment,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Thống kê điểm bài tập",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildScoreItem(
                                  "Điểm TB",
                                  avgScores['avg']?.toStringAsFixed(1) ?? '0',
                                  Colors.blue,
                                ),
                                _buildScoreItem(
                                  "Cao nhất",
                                  avgScores['max']?.toStringAsFixed(1) ?? '0',
                                  Colors.green,
                                ),
                                _buildScoreItem(
                                  "Thấp nhất",
                                  avgScores['min']?.toStringAsFixed(1) ?? '0',
                                  Colors.red,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Chỉ tính trên các bài tập đã chấm điểm",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (recentClasses.isNotEmpty) ...[
                    buildSectionTitle("Lớp học mới"),
                    ...recentClasses.map((c) => buildClassItem(c)).toList(),
                  ],

                  if (upcomingDeadlines.isNotEmpty) ...[
                    buildSectionTitle("Bài tập sắp hết hạn"),
                    ...upcomingDeadlines
                        .map((d) => buildDeadlineItem(d))
                        .toList(),
                  ],

                  if (quizzesWithoutResults.isNotEmpty) ...[
                    buildSectionTitle("Quiz chưa có ai làm"),
                    ...quizzesWithoutResults
                        .map((q) => buildQuizItem(q))
                        .toList(),
                  ],

                  if (topClasses.isNotEmpty) ...[
                    buildSectionTitle("Lớp đông nhất"),
                    ...topClasses
                        .map(
                          (c) => ListTile(
                            leading: const Icon(Icons.emoji_events),
                            title: Text(c['tenKhoaHoc'] ?? ''),
                            trailing: Text(
                              "${c['totalStudents'] ?? 0} học viên",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildScoreItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
