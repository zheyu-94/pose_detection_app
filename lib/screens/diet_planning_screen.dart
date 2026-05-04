import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // 🌟 用來處理日期格式

class DietPlanningScreen extends StatefulWidget {
  const DietPlanningScreen({super.key});

  @override
  State<DietPlanningScreen> createState() => _DietPlanningScreenState();
}

class _DietPlanningScreenState extends State<DietPlanningScreen> {
  // 取得今天的日期字串 (例如: 2023-12-25)
  String get _todayDate => DateFormat('yyyy-MM-dd').format(DateTime.now());

  // 🌟 彈出新增飲食的對話框
  void _showAddMealDialog() {
    final nameController = TextEditingController();
    final calController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("新增飲食紀錄"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "食物名稱")),
            TextField(controller: calController, decoration: const InputDecoration(labelText: "熱量 (kcal)"), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("取消")),
          ElevatedButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null || nameController.text.isEmpty) return;

              // 寫入資料庫
              await FirebaseFirestore.instance.collection('diets').add({
                'uid': user.uid,
                'foodName': nameController.text,
                'calories': int.tryParse(calController.text) ?? 0,
                'date': _todayDate,
                'timestamp': FieldValue.serverTimestamp(),
              });

              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("新增"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("今日飲食規劃")),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMealDialog,
        backgroundColor: Colors.greenAccent,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        // 1. 先抓使用者的 TDEE
        stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());

          var userData = userSnapshot.data!.data() as Map<String, dynamic>;
          double tdee = (userData['tdee'] ?? 2000).toDouble();

          return StreamBuilder<QuerySnapshot>(
            // 2. 再抓今天吃了什麼
            stream: FirebaseFirestore.instance
                .collection('diets')
                .where('uid', isEqualTo: user.uid)
                .where('date', isEqualTo: _todayDate)
                .snapshots(),
            builder: (context, dietSnapshot) {
              if (!dietSnapshot.hasData) return const CircularProgressIndicator();

              // 計算總攝取熱量
              int totalEaten = 0;
              var meals = dietSnapshot.data!.docs;
              for (var m in meals) {
                totalEaten += (m['calories'] as int);
              }

              double progress = totalEaten / tdee;

              return Column(
                children: [
                  // --- 上方熱量進度儀表板 ---
                  _buildCalorieHeader(totalEaten, tdee, progress),

                  const Padding(
                    padding: EdgeInsets.all(15.0),
                    child: Align(alignment: Alignment.centerLeft, child: Text("今日飲食明細", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                  ),

                  // --- 下方飲食清單 ---
                  Expanded(
                    child: meals.isEmpty
                        ? const Center(child: Text("今天還沒吃東西喔 🥗", style: TextStyle(color: Colors.white54)))
                        : ListView.builder(
                      itemCount: meals.length,
                      itemBuilder: (context, index) {
                        var meal = meals[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                          color: Colors.grey[900],
                          child: ListTile(
                            leading: const Icon(Icons.restaurant, color: Colors.greenAccent),
                            title: Text(meal['foodName']),
                            trailing: Text("${meal['calories']} kcal", style: const TextStyle(fontWeight: FontWeight.bold)),
                            onLongPress: () => meal.reference.delete(), // 長按可以刪除
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // 熱量儀表板組件
  Widget _buildCalorieHeader(int eaten, double target, double progress) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.1),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 150,
                height: 150,
                child: CircularProgressIndicator(
                  value: progress > 1 ? 1.0 : progress,
                  strokeWidth: 12,
                  backgroundColor: Colors.white10,
                  color: progress > 1 ? Colors.redAccent : Colors.greenAccent,
                ),
              ),
              Column(
                children: [
                  Text("$eaten", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  const Text("已攝取 kcal", style: TextStyle(color: Colors.white54)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text("每日目標：${target.round()} kcal", style: const TextStyle(fontSize: 16, color: Colors.white70)),
          if (eaten > target)
            const Text("\n⚠️ 熱量爆表啦！明天要多動一點喔！", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}