import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/api.dart';

class ThanhVienGroupScreen extends StatefulWidget {
  final int idGroup;
  final String tenNhom;

  const ThanhVienGroupScreen({
    super.key,
    required this.idGroup,
    required this.tenNhom,
  });

  @override
  State<ThanhVienGroupScreen> createState() => _ThanhVienGroupScreenState();
}

class _ThanhVienGroupScreenState extends State<ThanhVienGroupScreen> {
  List<Map<String, dynamic>> members = [];
  bool isLoading = true;
  int? currentUserId;
  String? currentUserRole;
  bool isGroupLeader = false;
  String? errorMessage;
  int memberCount = 0;

  final String apiUrl = '${ApiConfig.baseUrl}/groups';

  @override
  void initState() {
    super.initState();
    loadUserInfo();
  }

  Future<void> loadUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final userId = prefs.getInt('userId');
      final userRole = prefs.getString('vaiTro');
      
      if (userId != null) {
        setState(() {
          currentUserId = userId;
          currentUserRole = userRole;
        });
        await fetchGroupDetails();
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Không tìm thấy thông tin người dùng';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Lỗi tải thông tin: $e';
      });
    }
  }

  Future<void> fetchGroupDetails() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('$apiUrl/chitiet/${widget.idGroup}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final groupData = data['data'];
          
          List<Map<String, dynamic>> memberList = [];
          if (groupData['members'] != null && groupData['members'] is List) {
            for (var member in groupData['members']) {
              Map<String, dynamic> memberMap = {};
              
              if (member is Map) {
                memberMap['vaiTroNhom'] = member['vaiTroNhom'] ?? 'thanh_vien';
                
                if (member['nguoidung'] != null && member['nguoidung'] is Map) {
                  var nguoidung = member['nguoidung'];
                  Map<String, dynamic> userMap = {};
                  userMap['idNguoiDung'] = nguoidung['idNguoiDung'] ?? 0;
                  userMap['hoTen'] = nguoidung['hoTen'] ?? 'Không có tên';
                  userMap['email'] = nguoidung['email'] ?? '';
                  userMap['vaiTro'] = nguoidung['vaiTro'] ?? 'hocvien';
                  memberMap['nguoidung'] = userMap;
                } else {
                  memberMap['nguoidung'] = {
                    'idNguoiDung': 0,
                    'hoTen': 'Không có tên',
                    'email': '',
                    'vaiTro': 'hocvien',
                  };
                }
              }
              
              memberList.add(memberMap);
            }
          }
          
          setState(() {
            members = memberList;
            memberCount = groupData['memberCount'] ?? 0;
            isGroupLeader = groupData['isTruongNhom'] ?? false;
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = data['message'] ?? 'Không thể tải danh sách thành viên';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Lỗi kết nối đến máy chủ';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Lỗi fetchGroupDetails: $e');
      setState(() {
        errorMessage = 'Lỗi: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> kickMember(int userId, String userName) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: Text('Bạn có chắc chắn muốn kick "$userName" khỏi nhóm?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await performKickMember(userId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Kick'),
          ),
        ],
      ),
    );
  }

  Future<void> performKickMember(int userId) async {
    try {
      setState(() {
        isLoading = true;
      });

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('$apiUrl/kick/${widget.idGroup}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'idNguoiDungKick': userId}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã kick thành viên khỏi nhóm')),
        );
        await fetchGroupDetails();
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Không thể kick thành viên'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
    }
  }

  Future<void> transferLeadership(int userId, String userName) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận chuyển trưởng nhóm'),
        content: Text(
          'Bạn có chắc chắn muốn chuyển quyền trưởng nhóm cho "$userName"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await performTransferLeadership(userId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  Future<void> performTransferLeadership(int userId) async {
    try {
      setState(() {
        isLoading = true;
      });

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.put(
        Uri.parse('$apiUrl/chuyenNT/${widget.idGroup}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'idNguoiDungMoi': userId}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chuyển trưởng nhóm thành công')),
        );
        await fetchGroupDetails();
        Navigator.pop(context, true);
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Không thể chuyển trưởng nhóm'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: ${e.toString()}')));
    }
  }

  Widget _buildMemberItem(Map<String, dynamic> member) {
    Map<String, dynamic> user = {};
    if (member['nguoidung'] is Map) {
      user = Map<String, dynamic>.from(member['nguoidung']);
    }
    
    final userId = user['idNguoiDung'] ?? 0;
    final userRole = user['vaiTro'] ?? 'hocvien';
    final userName = user['hoTen'] ?? 'Không có tên';
    final userEmail = user['email'] ?? '';
    
    final isCurrentUser = userId == currentUserId;
    final isLeader = member['vaiTroNhom'] == 'truong_nhom';
    final isGiangVien = userRole == 'giangvien';

    final canKick = isGroupLeader && !isLeader && !isCurrentUser && !isGiangVien;
    final canTransfer = isGroupLeader && !isCurrentUser && !isLeader;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isLeader ? Colors.orange : (isGiangVien ? Colors.green : Colors.blue),
          child: Text(
            userName.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          userName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              userEmail,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            Wrap(
              spacing: 4,
              runSpacing: 2,
              children: [
                if (isLeader)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Text(
                      'Trưởng nhóm',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (isGiangVien)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Text(
                      'Giảng viên',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (isCurrentUser)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text(
                      '👤 Bạn',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canTransfer)
              IconButton(
                icon: const Icon(Icons.person_add_alt_1, color: Colors.blue),
                onPressed: () => transferLeadership(userId, userName),
                tooltip: 'Chuyển trưởng nhóm',
              ),
            if (canKick)
              IconButton(
                icon: const Icon(Icons.exit_to_app, color: Colors.red),
                onPressed: () => kickMember(userId, userName),
                tooltip: 'Kick thành viên',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Chưa có thành viên',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nhóm này chưa có thành viên nào',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            errorMessage ?? 'Đã có lỗi xảy ra',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                errorMessage = null;
              });
              fetchGroupDetails();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thành viên - ${widget.tenNhom}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Chip(
              label: Text(
                '$memberCount thành viên',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              backgroundColor: Colors.blue.shade700,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchGroupDetails,
            tooltip: 'Tải lại',
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang tải danh sách thành viên...'),
                ],
              ),
            )
          : errorMessage != null
          ? _buildErrorState()
          : members.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: fetchGroupDetails,
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                itemCount: members.length,
                itemBuilder: (context, index) {
                  return _buildMemberItem(members[index]);
                },
              ),
            ),
    );
  }
}