import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

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

  // 手動新增紀錄的對話框
  void _showAddWorkoutDialog() {
    final nameController = TextEditingController();
    final repsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text("${_formatDate(_selectedDay!)} 新增紀錄", style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "動作名稱", labelStyle: TextStyle(color: Colors.white54))
            ),
            TextField(
                controller: repsController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "次數 / 秒數", labelStyle: TextStyle(color: Colors.white54)),
                keyboardType: TextInputType.number
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("取消", style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null || nameController.text.isEmpty) return;

              String selectedDateStr = _formatDate(_selectedDay!);

              // 新增：手動加入紀錄時，也自動把那天的「休息」標籤刪掉
              final restRecords = await FirebaseFirestore.instance
                  .collection('workouts')
                  .where('uid', isEqualTo: user.uid)
                  .where('date', isEqualTo: selectedDateStr)
                  .where('category', isEqualTo: '休息')
                  .get();

              for (var doc in restRecords.docs) {
                await doc.reference.delete();
              }

              // 原本的存檔邏輯
              await FirebaseFirestore.instance.collection('workouts').add({
                'uid': user.uid,
                'exerciseName': nameController.text,
                'reps': int.tryParse(repsController.text) ?? 0,
                'category': '手動新增', // 幫它加上個分類避免讀取錯誤
                'date': selectedDateStr,
                'timestamp': FieldValue.serverTimestamp(),
              });
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("儲存", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("運動日曆"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddWorkoutDialog,
        backgroundColor: Colors.orangeAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // 1. 日曆組件
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
              defaultTextStyle: TextStyle(color: Colors.white),
              weekendTextStyle: TextStyle(color: Colors.orangeAccent),
              outsideTextStyle: TextStyle(color: Colors.white38),
              todayDecoration: BoxDecoration(color: Colors.orangeAccent, shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
              markerDecoration: BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 18),
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: Colors.white70),
              weekendStyle: TextStyle(color: Colors.orangeAccent),
            ),
          ),

          const Divider(height: 20, thickness: 1, color: Colors.white24),

          // 2. 當日紀錄清單
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${_formatDate(_selectedDay!)} 的紀錄", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const Icon(Icons.fitness_center, color: Colors.orangeAccent),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('workouts')
                  .where('uid', isEqualTo: user?.uid)
                  .where('date', isEqualTo: _formatDate(_selectedDay!))
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  debugPrint("錯誤詳情: ${snapshot.error}");
                  return const Center(child: Text("讀取失敗，請檢查索引", style: TextStyle(color: Colors.redAccent)));
                }
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                var docs = snapshot.data!.docs;

                // 核心修改：如果這天沒有任何運動紀錄，顯示「自動設為休息日」
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.nightlight_round, size: 80, color: Colors.orangeAccent),
                        const SizedBox(height: 15),
                        const Text("這天沒有運動紀錄", style: TextStyle(color: Colors.white70, fontSize: 18)),
                        const SizedBox(height: 5),
                        Text("系統已自動設為休息日", style: TextStyle(color: Colors.orangeAccent[100], fontSize: 16)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;

                    // 抓取資料庫裡的欄位，判斷這筆紀錄是什麼類型
                    bool isRest = data['isRest'] == true || data['category'] == '休息';
                    int? calories = data['calories'];
                    int? reps = data['reps'];
                    String timeText = data['timestamp'] != null
                        ? DateFormat('HH:mm').format((data['timestamp'] as Timestamp).toDate())
                        : '紀錄中...';

                    // 根據類型決定右側要顯示什麼文字
                    Widget trailingWidget;
                    if (isRest) {
                      trailingWidget = const Text("休息", style: TextStyle(color: Colors.orangeAccent, fontSize: 16, fontWeight: FontWeight.bold));
                    } else if (calories != null) {
                      trailingWidget = Text("🔥 $calories 大卡", style: const TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold));
                    } else {
                      trailingWidget = Text("${reps ?? 0} 次", style: const TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold));
                    }

                    return Card(
                      color: Colors.grey[900],
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        // 根據類型換圖示
                        leading: CircleAvatar(
                          backgroundColor: isRest ? Colors.orangeAccent.withAlpha(40) : (calories != null ? Colors.redAccent.withAlpha(40) : Colors.blueAccent.withAlpha(40)),
                          child: Icon(
                            isRest ? Icons.bed : (calories != null ? Icons.directions_run : Icons.fitness_center),
                            color: isRest ? Colors.orangeAccent : (calories != null ? Colors.redAccent : Colors.blueAccent),
                          ),
                        ),
                        title: Text(data['exerciseName'] ?? '未命名動作', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                        subtitle: Text("時間: $timeText", style: const TextStyle(color: Colors.white54)),
                        trailing: trailingWidget, // 顯示計算結果
                        onLongPress: () async {
                          // 長按刪除確認對話框
                          bool? confirm = await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: const Color(0xFF1E1E1E),
                              title: const Text("刪除紀錄", style: TextStyle(color: Colors.white)),
                              content: const Text("確定要刪除這筆紀錄嗎？", style: TextStyle(color: Colors.white70)),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("取消", style: TextStyle(color: Colors.white54))),
                                ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text("刪除", style: TextStyle(color: Colors.white))
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            docs[index].reference.delete();
                          }
                        },
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