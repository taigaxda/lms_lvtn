import 'package:flutter/material.dart';

class GiangVienMenuBar extends StatelessWidget {
  final String hoTen;
  final String vaiTro;

  const GiangVienMenuBar({
    super.key,
    required this.hoTen,
    required this.vaiTro,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(hoTen),
            accountEmail: const Text("Giảng viên"),
            currentAccountPicture: const CircleAvatar(
              child: Icon(Icons.admin_panel_settings),
            ),
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
          ),

          ListTile(
            leading: const Icon(Icons.class_),
            title: const Text("Trang chủ"),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/homeGiangVien');
            },
          ),

          ListTile(
            leading: const Icon(Icons.recycling),
            title: const Text("Lớp học đã lưu trữ"),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/lopHocDaLuuTru');
            },
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text("Dashboard"),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/dashboardGiangVien');
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Đăng xuất"),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }
}