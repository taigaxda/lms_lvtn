import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/authentication/dangKyScreen.dart';
import 'package:frontend/api.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'forgotPasswordScreen.dart';

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
    {"taiKhoan": "danhlcjwt", "matKhau": "29122004"},
    {"taiKhoan": "danhhv", "matKhau": "291204"},
    {"taiKhoan": "danhgv", "matKhau": "291204"},
  ];

  String? selectedUser;

  Future<void> guiFCMToken(int idNguoiDung) async{
    try{
      String? oneSignalSubId = OneSignal.User.pushSubscription.id;
      if (oneSignalSubId == null || oneSignalSubId.isEmpty) {
        print("Chưa lấy được Token từ OneSignal. Đang đợi subscription đổi trạng thái...");
        return;
      }
      print("Lấy được OneSignal Subscription ID: $oneSignalSubId");
      final response = await http.post(Uri.parse("${ApiConfig.baseUrl}/auth/luu-fcm-token"),
        headers: {"Content-Type": "application/json"},
        body:jsonEncode({
          "idNguoiDung": idNguoiDung,
          "token": oneSignalSubId
        }),
      );
      if (response.statusCode == 200) {
        print("Đã đồng bộ và lưu FCM token lên hệ thống Backend thành công!");
      } else {
        print("Backend từ chối lưu Token: ${response.body}");
      }
    }
    catch(e){
      print("Lỗi gửi FCM token: $e");
    }
  }
   void _setupOneSignalListeners() {
   OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      print('Nhận thông báo khi app đang mở: ${event.notification.title}');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            event.notification.title ?? 'Thông báo mới',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 4),
        ),
      );
    });
  }
  void _navigateToForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
    );
  }

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
        await guiFCMToken(user["id"]);
        _setupOneSignalListeners();

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
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _navigateToForgotPassword,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                ),
                child: const Text('Quên mật khẩu?'),
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