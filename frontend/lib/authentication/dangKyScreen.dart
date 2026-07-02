import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/api.dart';

class Dangkyscreen extends StatefulWidget {
  @override
  State<Dangkyscreen> createState() => _DangkyscreenState();
}

class _DangkyscreenState extends State<Dangkyscreen> {
  final TextEditingController _hoTenController = TextEditingController();
  final TextEditingController _taiKhoanController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _matKhauController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  String _vaiTro = 'hocvien';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final String apiUrl = "${ApiConfig.baseUrl}/auth/dangky";
  
  Future<void> dangKy() async {
    if (_matKhauController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Mật khẩu xác nhận không khớp"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });
    
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'hoTen': _hoTenController.text,
          'taiKhoan': _taiKhoanController.text,
          'email': _emailController.text,
          'matKhau': _matKhauController.text,
          'confirmPassword': _confirmPasswordController.text,
          'vaiTro': _vaiTro,
        }),
      );
      
      final data = jsonDecode(response.body);
      
      if ((response.statusCode == 200 || response.statusCode == 201) && data["success"]) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Đăng ký thành công! Vui lòng đăng nhập để tiếp tục."),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["message"] ?? "Đăng ký thất bại"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Đăng ký thất bại: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildVaiTroDropdown() {
    return DropdownButtonFormField<String>(
      value: _vaiTro,
      decoration: const InputDecoration(
        labelText: "Vai trò",
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.badge),
      ),
      onChanged: (value) {
        setState(() {
          _vaiTro = value!;
        });
      },
      items: const [
        DropdownMenuItem(value: 'hocvien', child: Text('Học viên')),
        DropdownMenuItem(value: 'giangvien', child: Text('Giảng viên')),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký'),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _hoTenController,
              decoration: const InputDecoration(
                labelText: "Họ tên",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _taiKhoanController,
              decoration: const InputDecoration(
                labelText: "Tài khoản",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_circle),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _matKhauController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: "Mật khẩu",
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                helperText: "Ít nhất 6 ký tự, bao gồm chữ hoa, chữ thường, số và ký tự đặc biệt",
                helperMaxLines: 2,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: "Xác nhận mật khẩu",
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildVaiTroDropdown(),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : dangKy,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Đăng ký",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),    
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Đã có tài khoản? "),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Đăng nhập",
                    style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _hoTenController.dispose();
    _taiKhoanController.dispose();
    _emailController.dispose();
    _matKhauController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}