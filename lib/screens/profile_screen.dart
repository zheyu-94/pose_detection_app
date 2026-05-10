import 'dart:convert'; // 🌟 處理 Base64 編碼
import 'dart:io';
import 'dart:typed_data'; // 🌟 處理圖片位元組
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart'; // 🌟 圖片選擇套件

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

  // 🌟 新增：處理大頭貼的狀態變數
  String? _base64Image;
  bool _isUploadingImage = false;

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
        _base64Image = doc.data()?['photoBase64']; // 🌟 讀取儲存的頭像字串
      });
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      // 使用 merge: true 確保更新資料時，不會覆蓋掉大頭貼的欄位
      await FirebaseFirestore.instance.collection('users').doc(user?.uid).set({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
      }, SetOptions(merge: true));

      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✨ 個人檔案更新成功！")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("更新失敗: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 🌟 新增：選擇圖片、壓縮並轉存 Base64 的核心邏輯
  Future<void> _pickAndSaveImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 200,    // 限制尺寸以防超過 Firestore 1MB 限制
      maxHeight: 200,
      imageQuality: 30, // 壓縮品質
    );

    if (image == null) return;

    setState(() => _isUploadingImage = true);

    try {
      File imageFile = File(image.path);
      Uint8List imageBytes = await imageFile.readAsBytes();
      String base64String = base64Encode(imageBytes);

      // 直接存入 Firestore
      await FirebaseFirestore.instance.collection('users').doc(user?.uid).set({
        'photoBase64': base64String,
      }, SetOptions(merge: true));

      setState(() {
        _base64Image = base64String;
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📸 頭像更新成功！')));
    } catch (e) {
      debugPrint("儲存失敗: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("頭像更新失敗: $e")));
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // 極致黑背景
      appBar: AppBar(
        title: const Text("帳戶中心", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          child: Column(
            children: [
              // 🌟 1. 大頭貼區域 (加入點擊事件與圖片預覽)
              Center(
                child: GestureDetector(
                  onTap: _isUploadingImage ? null : _pickAndSaveImage,
                  child: Stack(
                    alignment: Alignment.bottomRight, // 讓小相機圖示貼在右下角
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                        child: CircleAvatar(
                          radius: 55,
                          backgroundColor: const Color(0xFF1E1E1E),
                          // 根據有無 Base64 字串決定顯示圖片還是預設 Icon
                          backgroundImage: _base64Image != null ? MemoryImage(base64Decode(_base64Image!)) : null,
                          child: _isUploadingImage
                              ? const CircularProgressIndicator(color: Colors.blueAccent)
                              : (_base64Image == null
                              ? const Icon(Icons.person, size: 60, color: Colors.blueAccent)
                              : null),
                        ),
                      ),
                      // 提示可以編輯的小相機 Icon
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent[700],
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF121212), width: 3),
                        ),
                        child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // 2. 資訊卡片區 (保留你原本精美的設計)
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
                  ? const CircularProgressIndicator(color: Colors.blueAccent)
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