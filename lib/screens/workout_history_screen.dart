import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart'; // 🌟 引入日曆套件

class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  DateTime _focusedDay = DateTime.now(); // 日曆當前顯示的月份
  DateTime? _selectedDay; // 使用者點選的那一天

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay; // 預設選中今天
  }

  // 將 DateTime 格式化為 yyyy-MM-dd 以對應資料庫
  String _formatDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  // 🌟 手動新增紀錄的對話框
  void _showAddWorkoutDialog() {
    final nameController = TextEditingController();
    final repsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("${_formatDate(_selectedDay!)} 新增紀錄"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "動作名稱")),
            TextField(controller: repsController, decoration: const InputDecoration(labelText: "次數 / 秒數"), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("取消")),
          ElevatedButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null || nameController.text.isEmpty) return;

              await FirebaseFirestore.instance.collection('workouts').add({
                'uid': user.uid,
                'exerciseName': nameController.text,
                'reps': int.tryParse(repsController.text) ?? 0,
                'date': _formatDate(_selectedDay!), // 🌟 存入選定的日期
                'timestamp': FieldValue.serverTimestamp(),
              });
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("儲存"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("運動日曆")),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddWorkoutDialog,
        backgroundColor: Colors.orangeAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // 📅 1. 日曆組件
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay; // 更新月份視圖
              });
            },
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(color: Colors.orangeAccent, shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
              markerDecoration: BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
            ),
            headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
          ),

          const Divider(height: 20, thickness: 1),

          // 📋 2. 當日紀錄清單
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${_formatDate(_selectedDay!)} 的紀錄", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Icon(Icons.fitness_center, color: Colors.orangeAccent),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // 🌟 核心查詢：根據 UID 且日期必須等於「選中的那一天」
              stream: FirebaseFirestore.instance
                  .collection('workouts')
                  .where('uid', isEqualTo: user?.uid)
                  .where('date', isEqualTo: _formatDate(_selectedDay!))
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print("錯誤詳情: ${snapshot.error}");
                  return Center(child: Text("讀取失敗，請檢查索引"));
                }
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                var docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text("這天沒有運動紀錄喔 😴", style: TextStyle(color: Colors.white54)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    return Card(
                      color: Colors.grey[900],
                      child: ListTile(
                        title: Text(data['exerciseName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("時間: ${data['timestamp'] != null ? DateFormat('HH:mm').format((data['timestamp'] as Timestamp).toDate()) : '紀錄中...'}"),
                        trailing: Text("${data['reps']} 次", style: const TextStyle(color: Colors.greenAccent, fontSize: 18)),
                        onLongPress: () => docs[index].reference.delete(),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}