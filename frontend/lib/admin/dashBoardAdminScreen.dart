import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:frontend/api.dart';
import 'package:frontend/admin/menuUI/adminMenuBar.dart';

class DashboardAdminScreen extends StatefulWidget {
  const DashboardAdminScreen({super.key});

  @override
  State<DashboardAdminScreen> createState() => _DashboardAdminScreenState();
}

class _DashboardAdminScreenState extends State<DashboardAdminScreen> {
  Map<String, dynamic> overview = {};
  List topClasses = [];
  List recentUsers = [];
  List recentClasses = [];
  List recentSubmissions = [];
  List userRoleStats = [];
  List systemProgress = [];
  Map<String, dynamic> avgScores = {};
  List quizStats = [];
  bool isLoading = true;

  final String apiUrl = '${ApiConfig.baseUrl}/admin/lophoc/dashboard';

  String hoTen = "";
  String vaiTro = "";

  @override
  void initState() {
    super.initState();
    loadUserInfo();
    fetchAdminDashboard();
  }

  Future<void> loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      hoTen = prefs.getString("hoTen") ?? "";
      vaiTro = prefs.getString("vaiTro") ?? "";
    });
  }

  Future<void> fetchAdminDashboard() async {
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
          topClasses = data["topClasses"] ?? [];
          recentUsers = data["recentUsers"] ?? [];
          recentClasses = data["recentClasses"] ?? [];
          recentSubmissions = data["recentSubmissions"] ?? [];
          userRoleStats = data["userRoleStats"] ?? [];
          systemProgress = data["systemProgress"] ?? [];
          avgScores = data["avgScores"] ?? {};
          quizStats = data["quizStats"] ?? [];
          isLoading = false;
        });
      } else {
        throw Exception("Lỗi load dashboard admin: ${response.statusCode}");
      }
    } catch (e) {
      print("Lỗi Admin Dash: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildStatCard(String title, dynamic value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildRolePieChart() {
    if (userRoleStats.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text("Không có dữ liệu"),
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: userRoleStats.map((data) {
            final value = (data['_count'] as int).toDouble();
            final role = data['vaiTro'];

            Color color;
            String label;
            switch (role) {
              case 'admin':
                color = Colors.redAccent;
                label = "Admin";
                break;
              case 'giangvien':
                color = Colors.blue;
                label = "Giảng viên";
                break;
              case 'hocvien':
                color = Colors.green;
                label = "Học viên";
                break;
              default:
                color = Colors.grey;
                label = role;
            }

            return PieChartSectionData(
              value: value,
              color: color,
              title: "$label\n${value.toInt()}",
              radius: 60,
              titleStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget buildProgressPieChart() {
    if (systemProgress.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text("Chưa có dữ liệu tiến độ"),
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: systemProgress.map((data) {
            final value = (data['_count'] as int).toDouble();
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
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
        ),
      ),
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
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard Admin"),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchAdminDashboard,
          ),
        ],
      ),
      drawer: AdminMenuBar(hoTen: hoTen, vaiTro: vaiTro),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchAdminDashboard,
              child: ListView(
                padding: const EdgeInsets.all(8),
                children: [
                  Row(
                    children: [
                      buildStatCard(
                        "Người dùng",
                        overview['totalUsers'] ?? 0,
                        Icons.people,
                        Colors.blue,
                      ),
                      buildStatCard(
                        "Lớp học",
                        overview['totalClasses'] ?? 0,
                        Icons.menu_book,
                        Colors.orange,
                      ),
                    ],
                  ),
                  
                  Row(
                    children: [
                      buildStatCard(
                        "Học viên",
                        overview['totalStudents'] ?? 0,
                        Icons.school,
                        Colors.green,
                      ),
                      buildStatCard(
                        "Giảng viên",
                        overview['totalTeachers'] ?? 0,
                        Icons.person_pin,
                        Colors.purple,
                      ),
                    ],
                  ),
                  
                  Row(
                    children: [
                      buildStatCard(
                        "Bài học",
                        overview['totalLessons'] ?? 0,
                        Icons.library_books,
                        Colors.teal,
                      ),
                      buildStatCard(
                        "Bài tập",
                        overview['totalAssignments'] ?? 0,
                        Icons.assignment,
                        Colors.indigo,
                      ),
                    ],
                  ),
                  
                  Row(
                    children: [
                      buildStatCard(
                        "Quiz",
                        overview['totalQuizzes'] ?? 0,
                        Icons.quiz,
                        Colors.deepPurple,
                      ),
                      buildStatCard(
                        "Bài nộp",
                        overview['totalSubmissions'] ?? 0,
                        Icons.upload_file,
                        Colors.cyan,
                      ),
                    ],
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                    child: Text(
                      "Phân bổ vai trò",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: buildRolePieChart(),
                    ),
                  ),
                  if (avgScores.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.assessment, color: Colors.blue, size: 20),
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
                                  "Trung bình",
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
                          ],
                        ),
                      ),
                    ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                    child: Text(
                      "Lớp học nổi bật",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...topClasses.map(
                    (c) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.star, color: Colors.amber),
                        title: Text(c['tenKhoaHoc'] ?? ''),
                        subtitle: Text("GV: ${c['giangVien'] ?? 'Chưa phân công'}"),
                        trailing: Text(
                          "${c['totalStudents'] ?? 0} HV",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ),
                  ).toList(),
                  if (recentClasses.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                          child: Text(
                            "Lớp học mới nhất",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        ...recentClasses.map(
                          (c) => Card(
                            child: ListTile(
                              leading: const Icon(Icons.class_, color: Colors.blue),
                              title: Text(c['tenKhoaHoc'] ?? ''),
                              subtitle: Text("GV: ${c['giangVien'] ?? 'Chưa phân công'}"),
                              trailing: Text(
                                "${c['totalStudents'] ?? 0} HV",
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ),
                          ),
                        ).toList(),
                      ],
                    ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                    child: Text(
                      "Người dùng mới nhất",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...recentUsers.map(
                    (u) => Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          child: Text(
                            (u['hoTen'] ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(u['hoTen'] ?? ''),
                        subtitle: Text("${u['email'] ?? ''} • [${u['vaiTro'] ?? ''}]"),
                        trailing: Text(
                          "#${u['idNguoiDung'] ?? ''}",
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ),
                    ),
                  ).toList(),
                ],
              ),
            ),
    );
  }

  String _formatDate(String? date) {
    if (date == null) return "";
    final d = DateTime.tryParse(date);
    if (d == null) return "";
    return "${d.day}/${d.month}/${d.year}";
  }
}