import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/api.dart';
import 'themSuaGroupScreen.dart';
import 'messsage/chiTietGroupScreen.dart';

class Danhsachgroupscreen extends StatefulWidget {
  final int idKhoaHoc;
  final String vaiTro;
  const Danhsachgroupscreen({
    super.key,
    required this.idKhoaHoc,
    required this.vaiTro,
  });
  @override
  State<Danhsachgroupscreen> createState() => _Danhsachgroupscreen();
}

class _Danhsachgroupscreen extends State<Danhsachgroupscreen> {
  List groups = [];
  bool isLoading = true;

  final String apiUrl = '${ApiConfig.baseUrl}/groups';
  String hoTen = "";
  String vaiTro = "";

  @override
  void initState() {
    super.initState();
    loadUserInfo();
    fetchGroups();
  }

  Future<void> loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      hoTen = prefs.getString("hoTen") ?? "";
      vaiTro = prefs.getString("vaiTro") ?? "";
    });
  }

  Future<void> fetchGroups() async {
    try {
      setState(() {
        isLoading = true;
      });
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final res = await http.get(
        Uri.parse('$apiUrl/${widget.idKhoaHoc}'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          groups = data['data'] ?? [];
          isLoading = false;
        });
      } else {
        throw Exception("Lỗi tải danh sách nhóm");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi tải danh sách nhóm: $e")));
    }
  }

  Future<void> joinGroup(int idGroup) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final response = await http.post(
        Uri.parse('$apiUrl/join/$idGroup'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tham gia nhóm thành công")),
        );
        await fetchGroups();
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? "Tham gia thất bại");
      }
    } catch (e) {
      print("Lỗi join group: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  Future<void> leaveGroup(int idGroup) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final response = await http.post(
        Uri.parse('$apiUrl/leave/$idGroup'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Rời nhóm thành công")));
        await fetchGroups();
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? "Rời nhóm thất bại");
      }
    } catch (e) {
      print("Lỗi leave group: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  Future<void> deleteGroup(int idGroup) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final response = await http.delete(
        Uri.parse('$apiUrl/$idGroup'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Xóa nhóm thành công")));
        await fetchGroups();
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? "Xóa nhóm thất bại");
      }
    } catch (e) {
      print("Lỗi delete group: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  void _confirmDeleteGroup(int idGroup, String tenNhom) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xóa nhóm"),
        content: Text("Bạn có chắc chắn muốn xóa nhóm \"$tenNhom\" không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              deleteGroup(idGroup);
            },
            child: const Text("Xóa"),
          ),
        ],
      ),
    );
  }
  void _navigateToChat(Map group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Chitietgroupscreen(
          groupId: group['idGroup'],
          tenNhom: group['tenNhom'] ?? 'Nhóm chat',
        ),
      ),
    );
  }

  Widget _buildGroupItem(Map group) {
    final isMember = group['isMember'] ?? false;
    final isTruongNhom = group['isTruongNhom'] ?? false;
    final isGiangVien = widget.vaiTro == 'giangvien';
    final memberCount = group['memberCount'] ?? 0;
    final canDelete = isGiangVien || isTruongNhom;
    final canEdit = isTruongNhom;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isMember ? Colors.blue : Colors.grey,
          child: Text(
            group['tenNhom']?[0]?.toUpperCase() ?? 'N',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          group['tenNhom'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$memberCount thành viên'),
            if (isTruongNhom)
              const Text(
                'Trưởng nhóm',
                style: TextStyle(color: Colors.orange, fontSize: 12),
              ),
            if (group['moTa'] != null && group['moTa'].isNotEmpty)
              Text(
                group['moTa'],
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isMember)
              ElevatedButton(
                onPressed: () => joinGroup(group['idGroup']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: const Text("Tham gia"),
              ),
            if (isMember)
              OutlinedButton(
                onPressed: () => leaveGroup(group['idGroup']),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: const Text("Rời"),
              ),
            if (canEdit || canDelete)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onSelected: (value) {
                  if (value == 'edit') {
                    _navigateToEditGroup(group);
                  } else if (value == 'delete') {
                    _confirmDeleteGroup(
                      group['idGroup'],
                      group['tenNhom'] ?? '',
                    );
                  }
                },
                itemBuilder: (context) => [
                  if (canEdit)
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Sửa nhóm'),
                        ],
                      ),
                    ),
                  if (canDelete)
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Xóa nhóm'),
                        ],
                      ),
                    ),
                ],
              ),
          ],
        ),
        onTap: () {
          _navigateToChat(group);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_off, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "Chưa có nhóm nào",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.vaiTro == 'giangvien'
                ? "Hãy tạo nhóm đầu tiên cho lớp học"
                : "Hãy tham gia nhóm để thảo luận",
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          if (widget.vaiTro == 'giangvien' || widget.vaiTro == 'hocvien')
            ElevatedButton.icon(
              onPressed: _navigateToCreateGroup,
              icon: const Icon(Icons.add),
              label: const Text("Tạo nhóm mới"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  void _navigateToCreateGroup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Themsuagroupscreen(idKhoaHoc: widget.idKhoaHoc),
      ),
    ).then((result) {
      if (result == true) {
        fetchGroups();
      }
    });
  }

  void _navigateToEditGroup(Map group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Themsuagroupscreen(idGroup: group['idGroup']),
      ),
    ).then((result) {
      if (result == true) {
        fetchGroups();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nhóm chat"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchGroups,
            tooltip: "Tải lại",
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : groups.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: fetchGroups,
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 80),
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  return _buildGroupItem(groups[index]);
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateGroup,
        child: const Icon(Icons.add),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        tooltip: "Tạo nhóm mới",
      ),
    );
  }
}
