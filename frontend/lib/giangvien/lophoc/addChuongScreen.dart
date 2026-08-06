import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:frontend/api.dart';

class AddChuongScreen extends StatefulWidget {
  final int? idKhoaHoc;
  final Map<String, dynamic>? chuong;  

  const AddChuongScreen({
    super.key,
    this.idKhoaHoc,
    this.chuong,
  });

  @override
  State<AddChuongScreen> createState() => _AddChuongScreenState();
}

class _AddChuongScreenState extends State<AddChuongScreen> {
  final TextEditingController tenController = TextEditingController();
  final TextEditingController thuTuController = TextEditingController();
  bool isLoading = false;

  bool get isEdit => widget.chuong != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      tenController.text = widget.chuong!['tenChuong'] ?? '';
      thuTuController.text = widget.chuong!['thuTu']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    tenController.dispose();
    thuTuController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (tenController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên chương')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final body = {
        'tenChuong': tenController.text.trim(),
        'thuTu': thuTuController.text.isNotEmpty
            ? int.parse(thuTuController.text)
            : null,
      };

      late http.Response response;

      if (isEdit) {
        // ===== SỬA CHƯƠNG =====
        final idChuong = widget.chuong!['idChuong'];
        response = await http.put(
          Uri.parse('${ApiConfig.baseUrl}/giangvien/baihoc/chuong/$idChuong'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        );
      } else {
        if (widget.idKhoaHoc == null) {
          throw Exception('Thiếu ID khóa học');
        }
        response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/giangvien/baihoc/chuong/${widget.idKhoaHoc}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        );
      }

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Lỗi lưu chương')),
        );
      }
    } catch (e) {
      print('Lỗi: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Sửa chương' : 'Thêm chương mới'),
        backgroundColor: isEdit ? Colors.blue : Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: tenController,
              decoration: const InputDecoration(
                labelText: 'Tên chương *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.folder),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: thuTuController,
              decoration: const InputDecoration(
                labelText: 'Thứ tự (để trống tự tăng)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
                helperText: 'Để trống hệ thống sẽ tự động tăng',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : _save,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(isEdit ? 'Cập nhật' : 'Thêm chương'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isEdit ? Colors.blue : Colors.purple,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}