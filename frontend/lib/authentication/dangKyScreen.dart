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
  String _vaiTro = 'hocvien';
  bool _isLoading = false;
  final String apiUrl = "${ApiConfig.baseUrl}/auth/dangky";
  
  Future<void> dangKy() async{
    setState(() {
      _isLoading = true;
    });
    try{
      final response= await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'hoTen': _hoTenController.text,
          'taiKhoan': _taiKhoanController.text,
          'email': _emailController.text,
          'matKhau': _matKhauController.text,
          'vaiTro': _vaiTro,
        }),
      );
      final data = jsonDecode(response.body);
      if((response.statusCode == 200 || response.statusCode == 201) && data["success"]){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Đăng ký thành công! Vui lòng đăng nhập để tiếp tục.")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Đăng ký thất bại")),
        );
      }
    }
    catch(e){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đăng ký thất bại: $e")),
      );
    }
    finally{
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
      appBar: AppBar(title: const Text('Đăng ký'),
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
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _taiKhoanController,
              decoration: const InputDecoration(
                labelText: "Tài khoản",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
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
            const SizedBox(height: 10),
            _buildVaiTroDropdown(),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : dangKy,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Đăng ký", style: TextStyle(color: Colors.white),),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
