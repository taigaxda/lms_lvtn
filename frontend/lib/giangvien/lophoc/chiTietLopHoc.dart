// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:frontend/api.dart';
// import 'package:frontend/giangvien/menuUI/giangVienMenuBar.dart';
// import 'addBaiHocScreen.dart';
// import 'package:frontend/giangvien/baikiemtra/baiKiemTraGVScreen.dart';
// import 'package:frontend/giangvien/quanlyhocvien/qlhvGVScreen.dart';
// import 'package:frontend/giangvien/baitap/baiTapGVScreen.dart';
// import 'package:frontend/giangvien/thongbao/thongBaoGVScreen.dart';
// import 'package:frontend/comments/commentsScreen.dart';
// import 'package:frontend/groupchat/danhSachGroupScreen.dart';
// import 'thoiGianHocBaiScreen.dart';

// class ChiTietLopHocScreen extends StatefulWidget {
//   final int idKhoaHoc;
//   const ChiTietLopHocScreen({super.key, required this.idKhoaHoc});

//   @override
//   State<ChiTietLopHocScreen> createState() => _ChiTietLopHocScreen();
// }

// class _ChiTietLopHocScreen extends State<ChiTietLopHocScreen> {
//   int _selectedIndex = 0;
//   bool isLoading = true;
//   Map<String, dynamic>? lopHoc;
//   List baiHocs = [];

//   final String apiUrl = '${ApiConfig.baseUrl}/giangvien';
//   String hoTen = "";
//   String vaiTro = "";

//   @override
//   void initState() {
//     super.initState();
//     loadUserInfo();
//     loadAllData();
//   }

//   Future<void> loadUserInfo() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       hoTen = prefs.getString("hoTen") ?? "";
//       vaiTro = prefs.getString("vaiTro") ?? "";
//     });
//   }

//   Future<void> loadAllData() async {
//     setState(() => isLoading = true);
//     try {
//       await Future.wait([loadChiTietLopHoc(), loadBaiHoc()]);
//     } catch (e) {
//       debugPrint("Lỗi tải dữ liệu: $e");
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }

//   Future<void> loadChiTietLopHoc() async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString("token");
//     final res = await http.get(
//       Uri.parse('$apiUrl/lophoc/${widget.idKhoaHoc}'),
//       headers: {
//         "Content-Type": "application/json",
//         "Authorization": "Bearer $token",
//       },
//     );
//     if (res.statusCode == 200) lopHoc = json.decode(res.body)['data'];
//   }

//   Future<void> loadBaiHoc() async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString("token");
//     final res = await http.get(
//       Uri.parse('$apiUrl/baihoc/${widget.idKhoaHoc}'),
//       headers: {
//         "Content-Type": "application/json",
//         "Authorization": "Bearer $token",
//       },
//     );
//     if (res.statusCode == 200) {
//       setState(() {
//         baiHocs = json.decode(res.body)['data'];
//       });
//     }
//   }

//   Future<void> openAddBaiHoc(int id) async {
//     final result = await Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => Addbaihocscreen(idKhoaHoc: id)),
//     );
//     if (result == true) loadAllData();
//   }

//   Future<void> deleteBaiHoc(int idBaiHoc) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString("token");
//       final response = await http.delete(
//         Uri.parse('${apiUrl}/baihoc/$idBaiHoc'),
//         headers: {
//           "Content-Type": "application/json",
//           "Authorization": "Bearer $token",
//         },
//       );
//       final data = jsonDecode(response.body);
//       if (data["success"] == true) {
//         loadAllData();
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(const SnackBar(content: Text("Xoá bài học thành công")));
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(data["message"] ?? "Xoá thất bại")),
//         );
//       }
//     } catch (e) {
//       print(e);
//     }
//   }

//   Future<void> openEditBaiHoc(Map<String, dynamic> baiHoc) async {
//     final result = await Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) =>
//             Addbaihocscreen(idKhoaHoc: widget.idKhoaHoc, baiHoc: baiHoc),
//       ),
//     );
//     if (result == true) loadAllData();
//   }

//   void confirmDelete(int idBaiHoc) {
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text("Xoá bài học"),
//         content: const Text("Bạn có chắc muốn xoá bài học này không?"),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("Huỷ"),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               deleteBaiHoc(idBaiHoc);
//             },
//             child: const Text("Xoá", style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );
//   }

//   void openGroupScreen() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => Danhsachgroupscreen(
//           idKhoaHoc: widget.idKhoaHoc,
//           vaiTro: 'giangvien',
//         ),
//       ),
//     );
//   }

//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });

//     switch (index) {
//       case 0:
//         // Bài học (ở lại trang hiện tại)
//         break;
//       case 1:
//         openAddBaiHoc(widget.idKhoaHoc);
//         break;
//       case 2:
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => Baikiemtragvscreen(idKhoaHoc: widget.idKhoaHoc),
//           ),
//         );
//         break;
//       case 3:
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => QlhvGVScreen(idKhoaHoc: widget.idKhoaHoc),
//           ),
//         );
//         break;
//       case 4:
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => Thongbaogvscreen(idKhoaHoc: widget.idKhoaHoc),
//           ),
//         );
//         break;
//       case 5:
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => Baitapgvscreen(idKhoaHoc: widget.idKhoaHoc),
//           ),
//         );
//         break;
//       case 6:
//         openGroupScreen();
//         break;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           isLoading ? "Đang tải..." : (lopHoc?['tenKhoaHoc'] ?? "Chi tiết lớp"),
//         ),
//         backgroundColor: Colors.blue,
//         foregroundColor: Colors.white,
//         elevation: 0,
//       ),
//       drawer: GiangVienMenuBar(hoTen: hoTen, vaiTro: vaiTro),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : RefreshIndicator(
//               onRefresh: loadAllData,
//               child: _buildBodyContent(),
//             ),

//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _selectedIndex,
//         onTap: _onItemTapped,
//         selectedItemColor: Colors.blue,
//         unselectedItemColor: Colors.grey,
//         type: BottomNavigationBarType.fixed,
//         showSelectedLabels: true,
//         showUnselectedLabels: true,
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: "Bài học"),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.add_circle_outline),
//             label: "Tạo bài học",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.quiz),
//             label: "Bài kiểm tra",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.people_outline),
//             label: "Quản lý học viên",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.notifications),
//             label: "Thông báo",
//           ),
//           BottomNavigationBarItem(icon: Icon(Icons.book), label: "Bài tập"),
//           BottomNavigationBarItem(icon: Icon(Icons.group), label: "Nhóm chat"),
//         ],
//       ),
//     );
//   }

//   // Trong _buildBodyContent của ChiTietLopHocScreen
//   Widget _buildBodyContent() {
//     return SingleChildScrollView(
//       physics: const AlwaysScrollableScrollPhysics(),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.all(20),
//             decoration: const BoxDecoration(
//               color: Colors.blue,
//               borderRadius: BorderRadius.only(
//                 bottomLeft: Radius.circular(24),
//                 bottomRight: Radius.circular(24),
//               ),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   lopHoc?['tenKhoaHoc'] ?? "",
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         const Icon(
//                           Icons.qr_code,
//                           color: Colors.white70,
//                           size: 18,
//                         ),
//                         const SizedBox(width: 8),
//                         Text(
//                           "Mã lớp: ${lopHoc?['code'] ?? ""}",
//                           style: const TextStyle(color: Colors.white70),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       "Số bài học: ${baiHocs.length}",
//                       style: const TextStyle(color: Colors.white70),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           const Padding(
//             padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
//             child: Text(
//               "DANH SÁCH BÀI GIẢNG",
//               style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
//             ),
//           ),
//           ListView.builder(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             itemCount: baiHocs.length,
//             itemBuilder: (context, index) {
//               final b = baiHocs[index];
//               final hasVideo = b['videoUrl'] != null && b['videoUrl'] != "";

//               return Card(
//                 margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 elevation: 1,
//                 child: ListTile(
//                   contentPadding: const EdgeInsets.symmetric(
//                     horizontal: 16,
//                     vertical: 8,
//                   ),
//                   leading: CircleAvatar(
//                     backgroundColor: hasVideo
//                         ? Colors.blue.withOpacity(0.1)
//                         : Colors.orange.withOpacity(0.1),
//                     child: Icon(
//                       hasVideo ? Icons.play_circle : Icons.description,
//                       color: hasVideo ? Colors.blue : Colors.orange,
//                     ),
//                   ),
//                   title: Text(
//                     b['tenBaiHoc'] ?? "",
//                     style: const TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   subtitle: Padding(
//                     padding: const EdgeInsets.only(top: 4),
//                     child: Text("Thứ tự: ${b['thuTu'] ?? index + 1}"),
//                   ),
//                   trailing: PopupMenuButton<String>(
//                     icon: const Icon(Icons.more_vert),
//                     onSelected: (value) {
//                       switch (value) {
//                         case 'thoi_gian':
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => Thoigianhocbaiscreen(
//                                 idKhoaHoc: widget.idKhoaHoc,
//                                 idBaiHoc: b['idBaiHoc'],
//                                 tenBaiHoc: b['tenBaiHoc'] ?? '',
//                               ),
//                             ),
//                           );
//                           break;
//                         case 'edit':
//                           openEditBaiHoc(b);
//                           break;
//                         case 'comment':
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) =>
//                                   Commentsscreen(idBaiHoc: b['idBaiHoc']),
//                             ),
//                           );
//                           break;
//                         case 'delete':
//                           confirmDelete(b['idBaiHoc']);
//                           break;
//                       }
//                     },
//                     itemBuilder: (context) => [
//                       const PopupMenuItem(
//                         value: 'thoi_gian',
//                         child: Row(
//                           children: [
//                             Icon(Icons.timer, color: Colors.purple, size: 20),
//                             SizedBox(width: 12),
//                             Text('Thời gian học'),
//                           ],
//                         ),
//                       ),
//                       const PopupMenuItem(
//                         value: 'edit',
//                         child: Row(
//                           children: [
//                             Icon(Icons.edit, color: Colors.blue, size: 20),
//                             SizedBox(width: 12),
//                             Text('Sửa'),
//                           ],
//                         ),
//                       ),
//                       const PopupMenuItem(
//                         value: 'comment',
//                         child: Row(
//                           children: [
//                             Icon(Icons.comment, color: Colors.blue, size: 20),
//                             SizedBox(width: 12),
//                             Text('Bình luận'),
//                           ],
//                         ),
//                       ),
//                       const PopupMenuItem(
//                         value: 'delete',
//                         child: Row(
//                           children: [
//                             Icon(Icons.delete, color: Colors.red, size: 20),
//                             SizedBox(width: 12),
//                             Text('Xoá'),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           ),
//           const SizedBox(height: 100),
//         ],
//       ),
//     );
//   }
// }
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/api.dart';
import 'package:frontend/giangvien/menuUI/giangVienMenuBar.dart';
import 'addBaiHocScreen.dart';
import 'addChuongScreen.dart';
import 'package:frontend/giangvien/baikiemtra/baiKiemTraGVScreen.dart';
import 'package:frontend/giangvien/quanlyhocvien/qlhvGVScreen.dart';
import 'package:frontend/giangvien/baitap/baiTapGVScreen.dart';
import 'package:frontend/giangvien/thongbao/thongBaoGVScreen.dart';
import 'package:frontend/comments/commentsScreen.dart';
import 'package:frontend/groupchat/danhSachGroupScreen.dart';
import 'thoiGianHocBaiScreen.dart';

class ChiTietLopHocScreen extends StatefulWidget {
  final int idKhoaHoc;
  const ChiTietLopHocScreen({super.key, required this.idKhoaHoc});

  @override
  State<ChiTietLopHocScreen> createState() => _ChiTietLopHocScreen();
}

class _ChiTietLopHocScreen extends State<ChiTietLopHocScreen> {
  int _selectedIndex = 0;
  bool isLoading = true;
  Map<String, dynamic>? lopHoc;
  List<Map<String, dynamic>> chuongs = [];
  List<Map<String, dynamic>> baiHocKhongChuong = [];

  final String apiUrl = '${ApiConfig.baseUrl}/giangvien';
  String hoTen = "";
  String vaiTro = "";

  @override
  void initState() {
    super.initState();
    loadUserInfo();
    loadAllData();
  }

  Future<void> loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      hoTen = prefs.getString("hoTen") ?? "";
      vaiTro = prefs.getString("vaiTro") ?? "";
    });
  }

  Future<void> loadAllData() async {
    setState(() => isLoading = true);
    try {
      await loadChiTietLopHoc();
      await loadBaiHocTheoChuong();
    } catch (e) {
      debugPrint("Lỗi tải dữ liệu: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> loadChiTietLopHoc() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final res = await http.get(
      Uri.parse('$apiUrl/lophoc/${widget.idKhoaHoc}'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body)['data'];
      setState(() {
        lopHoc = data;
        final chuongData = data['chuong'] ?? [];
        if (chuongData is List) {
          chuongs = chuongData.cast<Map<String, dynamic>>();
        }
      });
    }
  }

  Future<void> loadBaiHocTheoChuong() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final res = await http.get(
      Uri.parse('$apiUrl/baihoc/${widget.idKhoaHoc}'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body)['data'];
      setState(() {
        final chuongData = data['chuongs'] ?? [];
        if (chuongData is List) {
          chuongs = chuongData.cast<Map<String, dynamic>>();
        }
        final baiKhongChuongData = data['baiHocKhongChuong'] ?? [];
        if (baiKhongChuongData is List) {
          baiHocKhongChuong = baiKhongChuongData.cast<Map<String, dynamic>>();
        }
      });
    }
  }

  Future<void> _openAddChuong() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddChuongScreen(idKhoaHoc: widget.idKhoaHoc),
      ),
    );
    if (result == true) loadAllData();
  }

  Future<void> _openEditChuong(Map<String, dynamic> chuong) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddChuongScreen(chuong: chuong)),
    );
    if (result == true) loadAllData();
  }

  Future<void> _deleteChuong(int idChuong, String tenChuong) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Xóa chương"),
        content: Text("Bạn có chắc muốn xóa chương '$tenChuong'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final response = await http.delete(
        Uri.parse('$apiUrl/baihoc/chuong/$idChuong'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      final data = jsonDecode(response.body);
      if (data["success"] == true) {
        loadAllData();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Xóa chương thành công")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Xóa thất bại")),
        );
      }
    } catch (e) {
      print('Lỗi xóa chương: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  // ============================================================
  // BÀI HỌC
  // ============================================================

  Future<void> openAddBaiHoc() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Addbaihocscreen(idKhoaHoc: widget.idKhoaHoc),
      ),
    );
    if (result == true) loadAllData();
  }

  Future<void> deleteBaiHoc(int idBaiHoc) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final response = await http.delete(
        Uri.parse('$apiUrl/baihoc/$idBaiHoc'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      final data = jsonDecode(response.body);
      if (data["success"] == true) {
        loadAllData();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Xóa bài học thành công")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Xóa thất bại")),
        );
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> openEditBaiHoc(Map<String, dynamic> baiHoc) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            Addbaihocscreen(idKhoaHoc: widget.idKhoaHoc, baiHoc: baiHoc),
      ),
    );
    if (result == true) loadAllData();
  }

  void confirmDeleteBaiHoc(int idBaiHoc) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Xóa bài học"),
        content: const Text("Bạn có chắc muốn xóa bài học này không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              deleteBaiHoc(idBaiHoc);
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void openGroupScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Danhsachgroupscreen(
          idKhoaHoc: widget.idKhoaHoc,
          vaiTro: 'giangvien',
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        break;
      case 1:
        openAddBaiHoc();
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Baikiemtragvscreen(idKhoaHoc: widget.idKhoaHoc),
          ),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QlhvGVScreen(idKhoaHoc: widget.idKhoaHoc),
          ),
        );
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Thongbaogvscreen(idKhoaHoc: widget.idKhoaHoc),
          ),
        );
        break;
      case 5:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Baitapgvscreen(idKhoaHoc: widget.idKhoaHoc),
          ),
        );
        break;
      case 6:
        openGroupScreen();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isLoading ? "Đang tải..." : (lopHoc?['tenKhoaHoc'] ?? "Chi tiết lớp"),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.folder_open),
        //     onPressed: _openAddChuong,
        //     tooltip: 'Thêm chương',
        //   ),
        // ],
      ),
      drawer: GiangVienMenuBar(hoTen: hoTen, vaiTro: vaiTro),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadAllData,
              child: _buildBodyContent(),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: "Bài học"),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: "Tạo bài học",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz),
            label: "Bài kiểm tra",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: "Quản lý học viên",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: "Thông báo",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: "Bài tập"),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: "Nhóm chat"),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD BODY
  // ============================================================

  Widget _buildBodyContent() {
    final hasChuong = chuongs.isNotEmpty;
    final hasBaiKhongChuong = baiHocKhongChuong.isNotEmpty;

    List<Widget> children = [];

    // Header
    children.add(_buildHeader());

    // Nút thêm chương
    children.add(_buildAddChuongButton());

    // Danh sách chương
    if (hasChuong) {
      children.add(_buildChuongHeader());
      for (var chuong in chuongs) {
        children.add(_buildChuongItem(chuong));
      }
    }

    // Bài học không chương
    if (hasBaiKhongChuong) {
      children.add(_buildBaiKhongChuongHeader());
      for (var b in baiHocKhongChuong) {
        children.add(_buildBaiHocItem(b, null));
      }
    }

    // Empty state
    if (!hasChuong && !hasBaiKhongChuong) {
      children.add(_buildEmptyState());
    }

    children.add(const SizedBox(height: 100));

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lopHoc?['tenKhoaHoc'] ?? "",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.qr_code, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Text(
                "Mã lớp: ${lopHoc?['code'] ?? ""}",
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.folder, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Text(
                "Số chương: ${chuongs.length}",
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.book, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Text(
                "Tổng bài học: ${_totalBaiHoc()}",
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddChuongButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton.icon(
        onPressed: _openAddChuong,
        icon: const Icon(Icons.folder_open),
        label: const Text("Thêm chương mới"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 45),
        ),
      ),
    );
  }

  Widget _buildChuongHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        "CHƯƠNG",
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }

  Widget _buildBaiKhongChuongHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        "BÀI HỌC KHÔNG CHƯƠNG",
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }

  // ============================================================
  // BUILD EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Center(
        child: Text(
          "Chưa có bài học nào. Hãy thêm chương hoặc bài học mới!",
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildChuongItem(Map<String, dynamic> chuong) {
    final baiHocs = chuong['baiHocs'] is List
        ? (chuong['baiHocs'] as List).cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề chương
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.folder, color: Colors.purple, size: 20),
            ),
            title: Text(
              chuong['tenChuong'] ?? 'Chương không tên',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "${baiHocs.length} bài học",
              style: const TextStyle(color: Colors.grey),
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  // case 'add_bai':
                  //   openAddBaiHoc();
                  //   break;
                  case 'edit':
                    _openEditChuong(chuong);
                    break;
                  case 'delete':
                    _deleteChuong(
                      chuong['idChuong'],
                      chuong['tenChuong'] ?? '',
                    );
                    break;
                }
              },
              itemBuilder: (context) => [
                // const PopupMenuItem(
                //   value: 'add_bai',
                //   child: Row(
                //     children: [
                //       Icon(
                //         Icons.add_circle_outline,
                //         color: Colors.blue,
                //         size: 20,
                //       ),
                //       SizedBox(width: 12),
                //       Text('Thêm bài học'),
                //     ],
                //   ),
                // ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue, size: 20),
                      SizedBox(width: 12),
                      Text('Sửa chương'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 20),
                      SizedBox(width: 12),
                      Text('Xóa chương'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Danh sách bài học trong chương
          if (baiHocs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                children: baiHocs
                    .map((b) => _buildBaiHocItem(b, chuong['idChuong']))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD BAI HOC ITEM - Có dấu 3 chấm
  // ============================================================

  Widget _buildBaiHocItem(Map<String, dynamic> b, int? idChuong) {
    final hasVideo = b['videoUrl'] != null && b['videoUrl'] != "";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        leading: CircleAvatar(
          radius: 14,
          backgroundColor: hasVideo
              ? Colors.blue.withOpacity(0.1)
              : Colors.orange.withOpacity(0.1),
          child: Icon(
            hasVideo ? Icons.play_circle : Icons.description,
            color: hasVideo ? Colors.blue : Colors.orange,
            size: 18,
          ),
        ),
        title: Text(b['tenBaiHoc'] ?? "", style: const TextStyle(fontSize: 14)),
        subtitle: Text(
          "Thứ tự: ${b['thuTu'] ?? 0}",
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 18),
          onSelected: (value) {
            switch (value) {
              case 'thoi_gian':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Thoigianhocbaiscreen(
                      idKhoaHoc: widget.idKhoaHoc,
                      idBaiHoc: b['idBaiHoc'],
                      tenBaiHoc: b['tenBaiHoc'] ?? '',
                    ),
                  ),
                );
                break;
              case 'comment':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Commentsscreen(idBaiHoc: b['idBaiHoc']),
                  ),
                );
                break;
              case 'edit':
                final baiHocFull = {...b, "idChuong": idChuong};

                openEditBaiHoc(baiHocFull);
                break;
              case 'delete':
                confirmDeleteBaiHoc(b['idBaiHoc']);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'thoi_gian',
              child: Row(
                children: [
                  Icon(Icons.timer, color: Colors.purple, size: 20),
                  SizedBox(width: 12),
                  Text('Thời gian học'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'comment',
              child: Row(
                children: [
                  Icon(Icons.comment, color: Colors.blue, size: 20),
                  SizedBox(width: 12),
                  Text('Bình luận'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.blue, size: 20),
                  SizedBox(width: 12),
                  Text('Sửa bài học'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red, size: 20),
                  SizedBox(width: 12),
                  Text('Xóa bài học'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TOTAL BAI HOC
  // ============================================================

  int _totalBaiHoc() {
    int total = 0;
    for (var chuong in chuongs) {
      final baiHocs = chuong['baiHocs'];
      if (baiHocs is List) {
        total += baiHocs.length;
      }
    }
    if (baiHocKhongChuong is List) {
      total += baiHocKhongChuong.length;
    }
    return total;
  }
}
