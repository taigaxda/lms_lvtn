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
  List userRoleStats = [];
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
          userRoleStats = data["userRoleStats"] ?? [];
          isLoading = false;
        });
      } else {
        throw Exception("Lỗi load dashboard admin");
      }
    } catch (e) {
      print("Lỗi Admin Dash: $e");
      setState(){
        isLoading = false;
      };
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
                fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
            ),
            Text(title, 
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.center,
            )
          ],
        ),
      ),
    );
  }

  Widget buildRolePieChart() {
    if (userRoleStats.isEmpty) return const Center(child: Text("Không có dữ liệu"));

    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: userRoleStats.map((data) {
            final value = (data['_count'] as int).toDouble();
            final role = data['vaiTro'];

            Color color;
            switch (role) {
              case 'admin': color = Colors.redAccent; break;
              case 'giangvien': color = Colors.blue; break;
              case 'hocvien': color = Colors.green; break;
              default: color = Colors.grey;
            }

            return PieChartSectionData(
              value: value,
              color: color,
              title: "$role\n${value.toInt()}",
              radius: 60,
              titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard Admin"),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        foregroundColor: Colors.white,
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
                      buildStatCard("Người dùng", overview['totalUsers'] ?? 0, Icons.people, Colors.blue),
                      buildStatCard("Khóa học", overview['totalClasses'] ?? 0, Icons.menu_book, Colors.orange),
                    ],
                  ),
                  Row(
                    children: [
                      buildStatCard("Học viên", overview['totalStudents'] ?? 0, Icons.school, Colors.green),
                      buildStatCard("Giảng viên", overview['totalTeachers'] ?? 0, Icons.person_pin, Colors.purple),
                    ],
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                    child: Text("Phân bổ vai trò", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: buildRolePieChart(),
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                    child: Text("Người dùng mới nhất", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  ...recentUsers.map((u) => Card(
                    child: ListTile(
                      leading: CircleAvatar(child: Text(u['hoTen'][0].toUpperCase())),
                      title: Text(u['hoTen']),
                      subtitle: Text("${u['email']} - [${u['vaiTro']}]"),
                    ),
                  )).toList(),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                    child: Text("Khóa học nổi bật", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  ...topClasses.map((c) => ListTile(
                    leading: const Icon(Icons.star, color: Colors.amber),
                    title: Text(c['tenKhoaHoc']),
                    subtitle: Text("GV: ${c['giangVien']}"),
                    trailing: Text("${c['totalStudents']} HV", style: const TextStyle(fontWeight: FontWeight.bold)),
                  )).toList(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}