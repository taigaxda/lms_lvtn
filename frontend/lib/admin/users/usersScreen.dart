import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'addUserScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/admin/menuUI/adminMenuBar.dart';
import 'package:frontend/api.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  List users = [];
  bool isLoading = true;

  final String apiUrl = "${ApiConfig.baseUrl}/admin/nguoidung";
  String hoTen = "";
  String vaiTro = "";
  int totalUsers = 0;
  int lockedUsers = 0;
  int adminCount = 0;
  int giangVienCount = 0;
  int hocVienCount = 0;

  @override
  void initState() {
    super.initState();
    loadUserInfo();
    fetchUsers();
  }

  Future<void> loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      hoTen = prefs.getString("hoTen") ?? "";
      vaiTro = prefs.getString("vaiTro") ?? "";
    });
  }

  Future<void> fetchUsers() async {
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
        int total = data.length;
        int locked = 0;
        int admin = 0;
        int gv = 0;
        int hv = 0;
        for (var u in data) {
          if (u['trangThai'] == false) locked++;
          switch (u['vaiTro']) {
            case 'admin':
              admin++;
              break;
            case 'giangvien':
              gv++;
              break;
            default:
              hv++;
          }
        }
        setState(() {
          users = data;
          isLoading = false;
          totalUsers = total;
          lockedUsers = locked;
          adminCount = admin;
          giangVienCount = gv;
          hocVienCount = hv;
        });
      } else {
        print(response.body); 
        throw Exception('Lỗi load data');
      }
    } catch (e) {
      print(e);
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> timKiemUsers(String keyword) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final response = await http.get(
        Uri.parse('$apiUrl/search?taiKhoan=$keyword'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          users = json.decode(response.body);
        });
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> openAddUserScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddUserScreen()),
    );
    if (result == true) {
      fetchUsers();
    }
  }

  Future<void> xoaUser(int id, {bool force = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final url = force ? '$apiUrl/$id?force=true' : '$apiUrl/$id';
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      final data = json.decode(response.body);
      if (data['requireConfirm'] == true) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Xác nhận xóa"),
            content: Text(data['message']),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Hủy"),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await xoaUser(id, force: true);
                },
                child: const Text("Xóa"),
              ),
            ],
          ),
        );
        return;
      }
      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Xóa thành công")));
        fetchUsers();
      } else {
        throw Exception(data['message'] ?? "Xóa thất bại");
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Có lỗi xảy ra")));
    }
  }

  Future<void> openUpdateUser(Map<String, dynamic> user) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddUserScreen(user: user)),
    );
    if (result == true) {
      fetchUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: openAddUserScreen,
        child: const Icon(Icons.add,color: Colors.white,),
        backgroundColor: Colors.blue,
      ),
      appBar: AppBar(title: const Text('Danh sách User'),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              openAddUserScreen();
            },
          ),
        ], 
      ),
      drawer: AdminMenuBar(hoTen: hoTen, vaiTro: vaiTro),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ExpansionTile(
                      title: const Text(
                        "Thống kê người dùng",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _buildStat("Tổng", users.length, Colors.blue),
                              _buildStat(
                                "Bị khóa",
                                users
                                    .where((u) => u['trangThai'] == false)
                                    .length,
                                Colors.red,
                              ),
                              _buildStat(
                                "Admin",
                                users
                                    .where((u) => u['vaiTro'] == 'admin')
                                    .length,
                                Colors.black,
                              ),
                              _buildStat(
                                "GV",
                                users
                                    .where((u) => u['vaiTro'] == 'giangvien')
                                    .length,
                                Colors.orange,
                              ),
                              _buildStat(
                                "HV",
                                users
                                    .where((u) => u['vaiTro'] == 'hocvien')
                                    .length,
                                Colors.green,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm theo tài khoản...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                fetchUsers();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      if (value.isEmpty) {
                        fetchUsers();
                      } else {
                        timKiemUsers(value);
                      }
                    },
                  ),
                ),

                Expanded(
                  child: ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.blue,
                                child: Text(
                                  user['hoTen'] != null &&
                                          user['hoTen'].isNotEmpty
                                      ? user['hoTen'][0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          user['hoTen'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: user['trangThai'] == true
                                                ? Colors.green
                                                : Colors.red,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            user['trangThai'] == true
                                                ? 'Hoạt động'
                                                : 'Khóa',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 4),
                                    Text('${user['taiKhoan'] ?? ''}'),
                                    Text('${user['email'] ?? ''}'),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${user['vaiTro'] ?? 'hocvien'}',
                                      style: const TextStyle(
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Column(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () {
                                      openUpdateUser(user);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      xoaUser(user['idNguoiDung']);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStat(String label, int value, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            "$value",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
