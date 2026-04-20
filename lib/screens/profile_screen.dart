import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    var doc = await FirebaseFirestore.instance.collection('users').doc(user?.uid).get();
    if (doc.exists) {
      setState(() {
        _nameController.text = doc.data()?['name'] ?? "";
        _phoneController.text = doc.data()?['phone'] ?? "";
      });
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user?.uid).update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
      });
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✨ 個人檔案更新成功！")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("更新失敗: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // 極致黑背景
      appBar: AppBar(
        title: const Text("帳戶中心", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          child: Column(
            children: [
              // 1. 大頭貼區域
              Center(
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                      child: const CircleAvatar(
                        radius: 55,
                        backgroundColor: Color(0xFF1E1E1E),
                        child: Icon(Icons.person, size: 60, color: Colors.blueAccent),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // 2. 資訊卡片區
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Column(
                  children: [
                    _buildCustomField("姓名", Icons.person_outline, _nameController, _isEditing),
                    const Divider(color: Colors.white12, height: 30),
                    _buildCustomField("電話", Icons.phone_android, _phoneController, _isEditing),
                    const Divider(color: Colors.white12, height: 30),
                    // Email 為不可修改項目
                    Row(
                      children: [
                        const Icon(Icons.mail_outline, color: Colors.white54, size: 22),
                        const SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Email", style: TextStyle(color: Colors.white54, fontSize: 13)),
                            Text(user?.email ?? "", style: const TextStyle(color: Colors.white70, fontSize: 16)),
                          ],
                        )
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // 3. 按鈕區
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isEditing ? Colors.greenAccent[700] : Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () {
                    if (_isEditing) {
                      _updateProfile();
                    } else {
                      setState(() => _isEditing = true);
                    }
                  },
                  child: Text(
                    _isEditing ? "儲存變更" : "編輯資料",
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // 登出按鈕
              TextButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) Navigator.pop(context);
                },
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: const Text("登出帳號", style: TextStyle(color: Colors.redAccent, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomField(String label, IconData icon, TextEditingController controller, bool enabled) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueAccent, size: 26),
        const SizedBox(width: 15),
        Expanded(
          child: TextField(
            controller: controller,
            enabled: enabled,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(color: Colors.white54, fontSize: 14),
              border: InputBorder.none,
              disabledBorder: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}