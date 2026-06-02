import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/api.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key, this.user});
  final Map<String, dynamic>? user;

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final TextEditingController hoTenController = TextEditingController();
  final TextEditingController taiKhoanController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController matKhauController = TextEditingController();

  bool trangThai = true;
  String vaiTro = 'hocvien';
  bool get isEdit => widget.user != null;

  final String apiUrl = "${ApiConfig.baseUrl}/admin/nguoidung";

  Future<void> addUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      body: json.encode({
        'hoTen': hoTenController.text,
        'taiKhoan': taiKhoanController.text,
        'email': emailController.text,
        'matKhau': matKhauController.text,
        'trangThai': trangThai,
        'vaiTro': vaiTro,
      }),
    );
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(data["message"] ?? "Thêm user thất bại")));
    }
  }

  Future<void> updateUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final respone = await http.put(
      Uri.parse('$apiUrl/${widget.user!['idNguoiDung']}'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      body: json.encode({
        'hoTen': hoTenController.text,
        'email': emailController.text,
        'trangThai': trangThai,
        'vaiTro': vaiTro,
        if(matKhauController.text.isNotEmpty)
          'matKhau': matKhauController.text,
      }),
    );
    final data = jsonDecode(respone.body);
    if (respone.statusCode == 200) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(data["message"] ?? "Cập nhật thất bại")));
    }
  }

  @override
  void initState() {
    super.initState();

    if (widget.user != null) {
      hoTenController.text = widget.user!['hoTen'] ?? '';
      taiKhoanController.text = widget.user!['taiKhoan'] ?? '';
      emailController.text = widget.user!['email'] ?? '';
      matKhauController.text = '';
      trangThai = widget.user!['trangThai'] ?? true;
      vaiTro = widget.user!['vaiTro'] ?? 'hocvien';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Sửa User' : 'Thêm User'),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: ListView(
          children: [
            TextField(
              controller: hoTenController,
              decoration: const InputDecoration(labelText: 'Họ tên'),
            ),
            TextField(
              controller: taiKhoanController,
              decoration: const InputDecoration(labelText: 'Tài khoản'),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: matKhauController,
              decoration: InputDecoration(labelText: 'Mật khẩu', hintText: isEdit ? 'Để trống nếu không đổi mật khẩu' : 'Nhập mật khẩu'),
              obscureText: true,
            ),

            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              value: vaiTro,
              items: const [
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
                DropdownMenuItem(value: 'hocvien', child: Text('Học viên')),
                DropdownMenuItem(value: 'giangvien', child: Text('Giảng viên')),
              ],
              onChanged: (value) {
                setState(() {
                  vaiTro = value!;
                });
              },
              decoration: const InputDecoration(labelText: 'Vai trò'),
            ),

            const SizedBox(height: 10),
            SwitchListTile(
              title: const Text('Hoạt động'),
              value: trangThai,
              onChanged: (value) {
                setState(() {
                  trangThai = value;
                });
              },
              activeColor: Colors.green,
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                if (isEdit) {
                  updateUser();
                } else {
                  addUser();
                }
              },
              child: Text(isEdit ? 'Cập nhật' : 'Thêm User',style: TextStyle(color: Colors.white),),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),

            ),
          ],
        ),
      ),
    );
  }
}
