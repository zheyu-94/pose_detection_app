import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'training_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StartWorkoutScreen extends StatefulWidget {
  const StartWorkoutScreen({super.key});

  @override
  State<StartWorkoutScreen> createState() => _StartWorkoutScreenState();
}

class _StartWorkoutScreenState extends State<StartWorkoutScreen> {
  List<Map<String, dynamic>> _todayWorkout = [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWorkoutForDate();
  }

  Future<void> _fetchWorkoutForDate() async {
    setState(() { _isLoading = true; });

    // 🌟 獲取當前使用者 UID
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String dateString = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('daily_workouts')
          .doc(dateString)
          .get();

      if (doc.exists && doc.data() != null) {
        List<dynamic> exercises = doc.get('exercises');
        setState(() {
          _todayWorkout = List<Map<String, dynamic>>.from(exercises);
        });
      } else {
        setState(() {
          _todayWorkout = [];
        });
      }
    } catch (e) {
      debugPrint("❌ 讀取失敗: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateWorkoutInFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String dateString = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid) // 👈 改這裡：'test_user' -> user.uid
          .collection('daily_workouts')
          .doc(dateString)
          .update({
        'exercises': _todayWorkout,
      });
      debugPrint("✅ 雲端資料同步成功！");
    } catch (e) {
      debugPrint("❌ 更新失敗: $e");
    }
  }

  // 🌟 新增：找出第一個「還沒完成」的動作的索引
  int _getNextUncompletedIndex() {
    return _todayWorkout.indexWhere((exercise) => exercise['isCompleted'] != true);
  }

  // 🌟 新增：執行訓練的核心邏輯
  Future<void> _startTrainingProcess() async {
    int nextIndex = _getNextUncompletedIndex();
    if (nextIndex == -1) return; // 已經全數完成了，不做事

    String exerciseName = _todayWorkout[nextIndex]['name'];

    // 1. 導航到訓練畫面，並且「等待 (await)」它回傳結果
    final bool? isFinished = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TrainingScreen(exerciseName: exerciseName)),
    );

    // 2. 如果回傳 true，代表該動作順利完成
    if (isFinished == true && context.mounted) {
      setState(() {
        _todayWorkout[nextIndex]['isCompleted'] = true;
      });

      // A. 更新每日菜單進度 (剛剛改好的 UID 版)
      await _updateWorkoutInFirebase();

      // 🌟 B. 同時新增到「運動紀錄 (workouts)」集合中
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String todayStr = "${DateTime
            .now()
            .year}-${DateTime
            .now()
            .month
            .toString()
            .padLeft(2, '0')}-${DateTime
            .now()
            .day
            .toString()
            .padLeft(2, '0')}";

        await FirebaseFirestore.instance.collection('workouts').add({
          'uid': user.uid,
          'exerciseName': exerciseName,
          'reps': (_todayWorkout[nextIndex]['sets'] ?? 1) *
              (_todayWorkout[nextIndex]['reps'] ?? 0),
          'date': todayStr,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 判斷目前進度
    int nextIndex = _getNextUncompletedIndex();
    bool isAllCompleted = _todayWorkout.isNotEmpty && nextIndex == -1;
    String buttonText = '進入第一項訓練';
    if (isAllCompleted) {
      buttonText = '🎉 今日訓練已全數完成！';
    } else if (nextIndex != -1) {
      buttonText = nextIndex == 0 ? '▶️ 開始: ${_todayWorkout[0]['name']}' : '▶️ 繼續: ${_todayWorkout[nextIndex]['name']}';
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('🏃 開始運動', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 日期選擇器 ---
            GestureDetector(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2023),
                  lastDate: DateTime(2030),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: Colors.blueAccent,
                          onPrimary: Colors.white,
                          surface: Color(0xFF1E1E1E),
                          onSurface: Colors.white,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null && picked != _selectedDate) {
                  setState(() {
                    _selectedDate = picked;
                  });
                  _fetchWorkoutForDate();
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withAlpha(25),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.blueAccent.withAlpha(127)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('📅 訓練日期', style: TextStyle(color: Colors.white, fontSize: 16)),
                    Text(
                      "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}",
                      style: const TextStyle(color: Colors.blueAccent, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

            const Text(
              '訓練清單',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Text(
              '💡 長按右側圖示可上下拖曳調整順序，左滑可刪除動作。',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 15),

            // --- 動作清單 ---
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                  : _todayWorkout.isEmpty
                  ? const Center(
                child: Text(
                  '今天沒有安排菜單喔！\n快去「菜單規劃」新增吧💪',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16, height: 1.5),
                ),
              )
                  : ReorderableListView.builder(
                itemCount: _todayWorkout.length,
                onReorder: (int oldIndex, int newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }
                    final item = _todayWorkout.removeAt(oldIndex);
                    _todayWorkout.insert(newIndex, item);
                  });
                  _updateWorkoutInFirebase();
                },
                itemBuilder: (context, index) {
                  final exercise = _todayWorkout[index];
                  final exerciseName = exercise['name'] ?? '未知動作';
                  final sets = exercise['sets'] ?? 3;
                  final reps = exercise['reps'] ?? 12;

                  // 🌟 判斷這個動作是否已經完成
                  final bool isCompleted = exercise['isCompleted'] == true;

                  return Dismissible(
                    key: Key('${exerciseName}_$index'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (direction) {
                      setState(() {
                        _todayWorkout.removeAt(index);
                      });
                      _updateWorkoutInFirebase();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$exerciseName 已移除'), duration: const Duration(seconds: 2)),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        // 🌟 完成的話背景變暗，沒完成維持原本顏色
                        color: isCompleted ? Colors.grey[900]!.withAlpha(120) : Colors.grey[900],
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isCompleted ? Colors.green.withAlpha(127) : Colors.grey[800]!,
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isCompleted ? Colors.green.withAlpha(50) : Colors.blueAccent.withAlpha(50),
                          child: isCompleted
                              ? const Icon(Icons.check, color: Colors.green)
                              : Text('${index + 1}', style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(
                            exerciseName,
                            style: TextStyle(
                              color: isCompleted ? Colors.grey : Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              // 🌟 完成的話加上刪除線
                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                            )
                        ),
                        subtitle: Text(
                            '建議組數: $sets組 x $reps下',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12)
                        ),
                        trailing: ReorderableDragStartListener(
                          index: index,
                          child: const Icon(Icons.drag_handle, color: Colors.white54, size: 30),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // --- 底部開始按鈕 ---
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                icon: Icon(isAllCompleted ? Icons.emoji_events : Icons.play_circle_fill, color: Colors.white, size: 28),
                label: Text(buttonText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  // 🌟 如果沒排菜單或是全數完成，按鈕就變灰色且不可點擊
                  backgroundColor: (_todayWorkout.isEmpty || isAllCompleted) ? Colors.grey[800] : Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: (_todayWorkout.isEmpty || isAllCompleted)
                    ? null
                    : _startTrainingProcess, // 🌟 呼叫剛才寫好的核心邏輯
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}