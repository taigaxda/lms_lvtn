import 'package:flutter/material.dart';

class AdminMenuBar extends StatelessWidget {
  final String hoTen;
  final String vaiTro;

  const AdminMenuBar({
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
            accountEmail: const Text("Quản trị viên"),
            currentAccountPicture: const CircleAvatar(
              child: Icon(Icons.admin_panel_settings),
            ),
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
          ),

          ListTile(
            leading: const Icon(Icons.class_),
            title: const Text("Quản lý lớp học"),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/classroom');
            },
          ),

          ListTile(
            leading: const Icon(Icons.people),
            title: const Text("Quản lý người dùng"),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/users');
            },
          ),

          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text("Dashboard"),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/dashBoardAdmin');
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