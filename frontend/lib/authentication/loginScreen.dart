import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/authentication/dangKyScreen.dart';
import 'package:frontend/api.dart';

class Loginscreen extends StatefulWidget {
  const Loginscreen({super.key});

  @override
  State<Loginscreen> createState() => _LoginscreenState();
}

class _LoginscreenState extends State<Loginscreen> {
  final TextEditingController _taiKhoanController = TextEditingController();
  final TextEditingController _matKhauController = TextEditingController();

  bool _isLoading = false;

  final String apiUrl = "${ApiConfig.baseUrl}/auth/login";

  final List<Map<String, String>> taiKhoanMau = [
    {"taiKhoan": "danhlcjwt", "matKhau": "2912004"},
    {"taiKhoan": "danhhv", "matKhau": "123456"},
    {"taiKhoan": "aaa", "matKhau": "123"},
  ];

  String? selectedUser;

  Future<void> dangNhap() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "taiKhoan": _taiKhoanController.text.trim(),
          "matKhau": _matKhauController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["success"]) {
        final user = data["user"];
        final token = data["token"];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", token);
        await prefs.setInt("userId", user["id"]);
        await prefs.setString("hoTen", user["hoTen"]);
        await prefs.setString("vaiTro", user["vaiTro"]);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Chào ${user["hoTen"]} 👋")),
        );

        if (user["vaiTro"] == "admin") {
          Navigator.pushReplacementNamed(context, "/admin");
        } else if (user["vaiTro"] == "hocvien") {
          Navigator.pushReplacementNamed(context, "/hocvien");
        } else {
          Navigator.pushReplacementNamed(context, "/giangvien");
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Đăng nhập thất bại")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lỗi kết nối server")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _taiKhoanController.dispose();
    _matKhauController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng nhập'),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _taiKhoanController,
              decoration: InputDecoration(
                labelText: "Tài khoản",
                border: const OutlineInputBorder(),
                suffixIcon: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    hint: const Text("Chọn"),
                    value: selectedUser,
                    items: taiKhoanMau.map((user) {
                      return DropdownMenuItem<String>(
                        value: user["taiKhoan"],
                        child: Text(user["taiKhoan"]!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedUser = value;
                        final user = taiKhoanMau.firstWhere(
                          (u) => u["taiKhoan"] == value,
                        );
                        _taiKhoanController.text = user["taiKhoan"]!;
                        _matKhauController.text = user["matKhau"]!;
                      });
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),
            TextField(
              controller: _matKhauController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Mật khẩu",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : dangNhap,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Đăng nhập",style: TextStyle(color: Colors.white),),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Dangkyscreen()),
                );
              },
              child: const Text("Chưa có tài khoản? Đăng ký",style: TextStyle(color: Colors.blueGrey),),
            ),
          ],
        ),
      ),
    );
  }
}