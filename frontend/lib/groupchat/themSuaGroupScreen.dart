import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/api.dart';
import 'danhSachGroupScreen.dart';

class Themsuagroupscreen extends StatefulWidget {
  final int? idGroup;
  final int? idKhoaHoc;

  const Themsuagroupscreen({super.key, this.idGroup, this.idKhoaHoc});

  @override
  State<Themsuagroupscreen> createState() => _ThemsuagroupscreenState();
}

class _ThemsuagroupscreenState extends State<Themsuagroupscreen> {
  final TextEditingController _tenNhomController = TextEditingController();
  final TextEditingController _moTaController = TextEditingController();
  bool isLoading = false;
  bool isSaving = false;
  bool isEdit = false;

  final String apiUrl = '${ApiConfig.baseUrl}/groups';

  @override
  void initState() {
    super.initState();
    if (widget.idGroup != null) {
      isEdit = true;
      _fetchGroupDetail();
    }
  }

  @override
  void dispose() {
    _tenNhomController.dispose();
    _moTaController.dispose();
    super.dispose();
  }

  Future<void> _fetchGroupDetail() async {
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final response = await http.get(
        Uri.parse('$apiUrl/chitiet/${widget.idGroup}'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final group = data['data'];

        setState(() {
          _tenNhomController.text = group['tenNhom'] ?? '';
          _moTaController.text = group['moTa'] ?? '';
          isLoading = false;
        });
      } else {
        throw Exception("Không thể tải thông tin nhóm");
      }
    } catch (e) {
      print("Lỗi fetch group detail: $e");
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi tải thông tin: $e")));
    }
  }

  Future<void> _createGroup() async {
    final tenNhom = _tenNhomController.text.trim();
    final moTa = _moTaController.text.trim();
    if (tenNhom.isEmpty || moTa.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng nhập đầy đủ thông tin"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (widget.idKhoaHoc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Không tìm thấy ID khóa học"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final response = await http.post(
        Uri.parse('$apiUrl/${widget.idKhoaHoc}'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"tenNhom": tenNhom, "moTa": moTa}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Tạo nhóm thành công"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception(data['message'] ?? "Tạo nhóm thất bại");
      }
    } catch (e) {
      print("Lỗi tạo nhóm: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => isSaving = false);
    }
  }

  Future<void> _updateGroup() async {
    final tenNhom = _tenNhomController.text.trim();
    final moTa = _moTaController.text.trim();

    if (tenNhom.isEmpty || moTa.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng nhập đầy đủ thông tin"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final response = await http.put(
        Uri.parse('$apiUrl/${widget.idGroup}'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"tenNhom": tenNhom, "moTa": moTa}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Cập nhật nhóm thành công"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception(data['message'] ?? "Cập nhật thất bại");
      }
    } catch (e) {
      print("Lỗi cập nhật nhóm: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => isSaving = false);
    }
  }

  void _saveGroup() {
    if (isEdit) {
      _updateGroup();
    } else {
      _createGroup();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Sửa nhóm" : "Tạo nhóm mới"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchGroupDetail,
              tooltip: "Tải lại",
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isEdit ? Icons.edit : Icons.group_add,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isEdit
                                ? "Chỉnh sửa thông tin nhóm"
                                : "Tạo nhóm mới trong lớp học",
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _tenNhomController,
                    decoration: const InputDecoration(
                      labelText: "Tên nhóm *",
                      hintText: "Nhập tên nhóm",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.group),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _moTaController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: "Mô tả *",
                      hintText: "Nhập mô tả nhóm",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Thông tin thêm
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isEdit
                                ? "Chỉ trưởng nhóm mới có quyền sửa nhóm"
                                : "Bạn sẽ là trưởng nhóm của nhóm này",
                            style: TextStyle(
                              color: isEdit
                                  ? Colors.orange.shade700
                                  : Colors.green.shade700,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (isEdit)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              "Bạn có thể thay đổi tên và mô tả nhóm tại đây",
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const Spacer(),

                  // Nút lưu
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : _saveGroup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              isEdit ? "Cập nhật nhóm" : "Tạo nhóm",
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Nút hủy
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("Hủy"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
