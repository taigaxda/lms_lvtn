import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/api.dart';

class Thoigianhocbaiscreen extends StatefulWidget {
  final int idKhoaHoc;
  final int idBaiHoc;
  final String tenBaiHoc;
  const Thoigianhocbaiscreen({
    super.key,
    required this.idKhoaHoc,
    required this.idBaiHoc,
    required this.tenBaiHoc,
  });
  @override
  State<Thoigianhocbaiscreen> createState() => _Thoigianhocbaiscreen();
}

class _Thoigianhocbaiscreen extends State<Thoigianhocbaiscreen> {
  bool isLoading = true;
  Map<String, dynamic>? data;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final response = await http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/giangvien/baihoc/thoigianhoc/${widget.idBaiHoc}',
        ),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      final result = jsonDecode(response.body);
      if (response.statusCode == 200 && result['success'] == true) {
        setState(() {
          data = result['data'];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = result['message'] ?? 'Không thể tải dữ liệu';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Lỗi kết nối: $e';
        isLoading = false;
      });
    }
  }

  String _formatTime(int seconds) {
    if (seconds < 60) {
      return '$seconds giây';
    }
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes < 60) {
      return '$minutes phút ${remainingSeconds}s';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '$hours giờ ${remainingMinutes} phút';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'hoan_thanh':
        return Colors.green;
      case 'dang_hoc':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'hoan_thanh':
        return 'Hoàn thành';
      case 'dang_hoc':
        return 'Đang học';
      default:
        return 'Chưa học';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'hoan_thanh':
        return Icons.check_circle;
      case 'dang_hoc':
        return Icons.play_circle;
      default:
        return Icons.circle_outlined;
    }
  }

  List<dynamic> _getFilteredList(int tabIndex) {
    if (data == null) return [];
    final ds = data!['danhSach'] as Map<String, dynamic>;
    switch (tabIndex) {
      case 0:
        final all = <dynamic>[];
        all.addAll(ds['chuaHoc'] ?? []);
        all.addAll(ds['dangHoc'] ?? []);
        all.addAll(ds['hoanThanh'] ?? []);
        return all;
      case 1:
        return ds['chuaHoc'] ?? [];
      case 2:
        return ds['dangHoc'] ?? [];
      case 3:
        return ds['hoanThanh'] ?? [];
      default:
        return [];
    }
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStudentList(List<dynamic> list) {
    if (list.isEmpty) {
      return const Center(
        child: Text('Không có học viên nào'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        final status = item['trangThai'] ?? 'chua_hoc';
        final thoiGian = item['thoiGianHoc'] ?? 0;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(status).withOpacity(0.2),
              child: Icon(
                _getStatusIcon(status),
                color: _getStatusColor(status),
              ),
            ),
            title: Text(
              item['hoTen'] ?? 'Không tên',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tài khoản: ${item['taiKhoan'] ?? ''}'),
                Text(
                  'Email: ${item['email'] ?? ''}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(status),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                if (thoiGian > 0)
                  Text(
                    _formatTime(thoiGian),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  )
                else
                  const Text(
                    'Chưa học',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Thời gian học: ${widget.tenBaiHoc}'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: loadData),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Tất cả'),
              Tab(text: 'Chưa học'),
              Tab(text: 'Đang học'),
              Tab(text: 'Hoàn thành'),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          errorMessage!,
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: loadData,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem(
                                  'Tổng HV',
                                  data!['thongKe']['tongHocVien'].toString(),
                                  Icons.people,
                                  Colors.blue,
                                ),
                                _buildStatItem(
                                  'Đã học',
                                  data!['thongKe']['daHoc'].toString(),
                                  Icons.check_circle,
                                  Colors.green,
                                ),
                                _buildStatItem(
                                  'Chưa học',
                                  data!['thongKe']['chuaHoc'].toString(),
                                  Icons.circle_outlined,
                                  Colors.grey,
                                ),
                              ],
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem(
                                  'Đang học',
                                  data!['thongKe']['dangHoc'].toString(),
                                  Icons.play_circle,
                                  Colors.orange,
                                ),
                                _buildStatItem(
                                  'Hoàn thành',
                                  data!['thongKe']['hoanThanh'].toString(),
                                  Icons.check_circle,
                                  Colors.green,
                                ),
                                _buildStatItem(
                                  'TB thời gian',
                                  _formatTime(data!['thongKe']['thoiGianTrungBinh']),
                                  Icons.timer,
                                  Colors.purple,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildStudentList(_getFilteredList(0)), // Tất cả
                            _buildStudentList(_getFilteredList(1)), // Chưa học
                            _buildStudentList(_getFilteredList(2)), // Đang học
                            _buildStudentList(_getFilteredList(3)), // Hoàn thành
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}