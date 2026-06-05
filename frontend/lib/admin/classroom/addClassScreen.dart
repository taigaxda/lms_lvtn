import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/api.dart';

class AddClassScreen extends StatefulWidget {
  const AddClassScreen({super.key, this.khoahoc});
  final Map<String, dynamic>? khoahoc;

  @override
  State<AddClassScreen> createState() => _AddClassScreenState();
}

class _AddClassScreenState extends State<AddClassScreen> {
  final TextEditingController tenController = TextEditingController();
  final TextEditingController moTaController = TextEditingController();
  final TextEditingController danhMucController = TextEditingController();

  List giangViens = [];
  int? selectedGiangVienId;

  bool trangThai = true;

  bool get isEdit => widget.khoahoc != null;

  final String apiUrl = "${ApiConfig.baseUrl}/admin/lophoc";
  Future<void> fetchGiangViens() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/admin/nguoidung'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        giangViens = data.where((u) => u['vaiTro'] == 'giangvien').toList();
      });
    }
  }
  Future<void> addClass() async {
    if (selectedGiangVienId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn giảng viên")),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      body: json.encode({
        'tenKhoaHoc': tenController.text,
        'moTa': moTaController.text,
        'danhMuc': danhMucController.text,
        'idGiangVien': selectedGiangVienId,
        'trangThai': trangThai,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data["message"] ?? "Thêm lớp thất bại")),
      );
    }
  }
  Future<void> updateClass() async {
    if (selectedGiangVienId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn giảng viên")),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final response = await http.put(
      Uri.parse('$apiUrl/${widget.khoahoc!['idKhoaHoc']}'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token"
      },
      body: json.encode({
        'tenKhoaHoc': tenController.text,
        'moTa': moTaController.text,
        'danhMuc': danhMucController.text,
        'idGiangVien': selectedGiangVienId,
        'trangThai': trangThai,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data["message"] ?? "Cập nhật thất bại")),
      );
    }
  }
  @override
  void initState() {
    super.initState();
    fetchGiangViens();
    if (widget.khoahoc != null) {
      tenController.text = widget.khoahoc!['tenKhoaHoc'] ?? '';
      moTaController.text = widget.khoahoc!['moTa'] ?? '';
      danhMucController.text = widget.khoahoc!['danhMuc'] ?? '';
      selectedGiangVienId = widget.khoahoc!['idGiangVien'];
      trangThai = widget.khoahoc!['trangThai'] ?? true;
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Sửa lớp học' : 'Thêm lớp học'),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: ListView(
          children: [
            TextField(
              controller: tenController,
              decoration: const InputDecoration(labelText: 'Tên khóa học'),
            ),
            TextField(
              controller: moTaController,
              decoration: const InputDecoration(labelText: 'Mô tả'),
            ),
            TextField(
              controller: danhMucController,
              decoration: const InputDecoration(labelText: 'Danh mục'),
            ),

            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              value: selectedGiangVienId,
              items: giangViens.map<DropdownMenuItem<int>>((gv) {
                return DropdownMenuItem<int>(
                  value: gv['idNguoiDung'],
                  child: Text("${gv['hoTen']} (${gv['email']})"),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedGiangVienId = value;
                });
              },
              decoration: const InputDecoration(labelText: 'Giảng viên'),
            ),

            const SizedBox(height: 10),

            SwitchListTile(
              title: const Text('Trạng thái'),
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
                  updateClass();
                } else {
                  addClass();
                }
              },
              child: Text(isEdit ? 'Cập nhật' : 'Thêm lớp',style: TextStyle(color: Colors.white),),
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