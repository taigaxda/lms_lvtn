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
      final userId = prefs.getInt("userId");

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "x-user-id": userId != null ? userId.toString() : "",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          overview = data["overview"] ?? {};
          recentClasses = data["recentClasses"] ?? [];
          topClasses = data["topClasses"] ?? [];
          progressStats = data["progressStats"] ?? [];
          isLoading = false;
        });
      } else {
        throw Exception("Lỗi load dashboard");
      }
    } catch (e) {
      print(e);
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildStatCard(String title, dynamic value, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.blue, Colors.lightBlueAccent],
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
      padding: const EdgeInsets.all(10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget buildPieChart() {
    if (progressStats.isEmpty) {
      return const Center(child: Text("Không có dữ liệu"));
    }

    return SizedBox(
      height: 220,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: progressStats.map((data) {
            final value = (data['_count'] as int).toDouble();
            final status = data['trangThai'];
            Color color;
            switch (status) {
              case 'hoan_thanh':
                color = Colors.green;
                break;
              case 'dang_hoc':
                color = Colors.orange;
                break;
              case 'chua_hoc':
                color = Colors.blue;
                break;
              default:
                color = Colors.grey;
            }

            return PieChartSectionData(
              value: value,
              color: color,
              title: "$status\n${value.toInt()}",
              radius: 60,
              titleStyle: const TextStyle(
                fontSize: 12,
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
      title: Text(c['tenKhoaHoc']),
      subtitle: Text("Code: ${c['code'] ?? ''}"),
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

                  buildSectionTitle("Biểu đồ tiến độ"),
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
                    child: buildPieChart(),
                  ),

                  buildSectionTitle("Lớp học mới"),
                  ...recentClasses.map((c) => buildClassItem(c)).toList(),

                  buildSectionTitle("Lớp đông nhất"),
                  ...topClasses.map(
                    (c) => ListTile(
                      title: Text(c['tenKhoaHoc']),
                      trailing: Text("${c['totalStudents']} HV"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
