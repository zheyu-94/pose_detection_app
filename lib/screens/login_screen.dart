import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isLoginMode = true; // 切換登入或註冊模式

  String _selectedRole = 'user'; // 預設是學員

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      if (_isLoginMode) {
        // 登入邏輯
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        // 註冊邏輯 - 這裡只呼叫「一次」建立帳號
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // 成功後立即將身分寫入資料庫
        if (userCredential.user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
            'uid': userCredential.user!.uid,
            'email': _emailController.text.trim(),
            'role': _selectedRole, // 'user' 或 'coach'
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
      // 成功後，main.dart 的 StreamBuilder 會自動帶你進入首頁
    } on FirebaseAuthException catch (e) {
      String message = e.message ?? '發生錯誤';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      print("Firestore 寫入錯誤: $e"); // 這行能幫你在 Debug Console 看到具體原因
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fitness_center, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 20),
              Text(
                _isLoginMode ? '歡迎回來，AI 健身大師' : '建立你的專屬訓練帳號',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 40),

              // 信箱輸入框
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: '電子郵件',
                  labelStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.email, color: Colors.white54),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white24),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.blueAccent),
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 密碼輸入框
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: '密碼 (至少 6 碼)',
                  labelStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.lock, color: Colors.white54),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white24),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.blueAccent),
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              if (!_isLoginMode) ...[
                const SizedBox(height: 20),
                const Text("請選擇您的身分：", style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text("我是學員")),
                        selected: _selectedRole == 'user',
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedRole = 'user');
                        },
                        selectedColor: Colors.blueAccent,
                        labelStyle: TextStyle(color: _selectedRole == 'user' ? Colors.white : Colors.white54),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text("我是教練")),
                        selected: _selectedRole == 'coach',
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedRole = 'coach');
                        },
                        selectedColor: Colors.blueAccent,
                        labelStyle: TextStyle(color: _selectedRole == 'coach' ? Colors.white : Colors.white54),
                      ),
                    ),
                  ],
                ),
              ],

              // 登入/註冊按鈕
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_isLoginMode ? '登入' : '註冊', style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),

              // 切換模式按鈕
              TextButton(
                onPressed: () => setState(() => _isLoginMode = !_isLoginMode),
                child: Text(
                  _isLoginMode ? '還沒有帳號？點此註冊' : '已經有帳號了？點此登入',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}