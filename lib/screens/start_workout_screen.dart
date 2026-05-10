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
      debugPrint("讀取失敗: $e");
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
          .doc(user.uid)
          .collection('daily_workouts')
          .doc(dateString)
          .update({
        'exercises': _todayWorkout,
      });
      debugPrint("雲端資料同步成功！");
    } catch (e) {
      debugPrint("更新失敗: $e");
    }
  }

  int _getNextUncompletedIndex() {
    return _todayWorkout.indexWhere((exercise) => exercise['isCompleted'] != true);
  }

  // 獨立出一個「完成動作並寫入歷史紀錄」的通用函數
  Future<void> _markAsCompletedAndSave(int index, {bool isRest = false, int? calories, int? actualReps}) async {
    setState(() {
      _todayWorkout[index]['isCompleted'] = true;
    });

    // 1. 更新本日清單進度 (打勾)
    await _updateWorkoutInFirebase();

    // 2. 寫入到 workouts 歷史紀錄集合
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String todayStr = "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";

      // 新增防呆邏輯 1：如果現在完成的是「真正的運動」，就把當天的「休息紀錄」通通清掉！
      if (!isRest) {
        final restRecords = await FirebaseFirestore.instance
            .collection('workouts')
            .where('uid', isEqualTo: user.uid)
            .where('date', isEqualTo: todayStr)
            .where('category', isEqualTo: '休息') // 專門抓休息的紀錄
            .get();

        for (var doc in restRecords.docs) {
          await doc.reference.delete(); // 刪除它
        }
      }
      // 新增防呆邏輯 2：如果現在是按「休息」，為了避免同一天產生多筆休息紀錄，先把舊的休息刪掉
      else {
        final existingRestRecords = await FirebaseFirestore.instance
            .collection('workouts')
            .where('uid', isEqualTo: user.uid)
            .where('date', isEqualTo: todayStr)
            .where('category', isEqualTo: '休息')
            .get();

        for (var doc in existingRestRecords.docs) {
          await doc.reference.delete();
        }
      }

      // 接著才是原本的寫入邏輯
      String exerciseName = _todayWorkout[index]['name'];
      String category = _todayWorkout[index]['category'] ?? (isRest ? '休息' : '運動');

      Map<String, dynamic> historyData = {
        'uid': user.uid,
        'exerciseName': exerciseName,
        'category': category,
        'date': todayStr,
        'timestamp': FieldValue.serverTimestamp(),
      };

      if (isRest) {
        historyData['isRest'] = true;
      } else if (calories != null) {
        historyData['calories'] = calories;
      } else {
        // 💡 這裡會優先使用傳入的真實次數 (actualReps)，如果沒有才用預設計算！
        historyData['reps'] = actualReps ?? ((_todayWorkout[index]['sets'] ?? 1) * (_todayWorkout[index]['reps'] ?? 0));
      }

      await FirebaseFirestore.instance.collection('workouts').add(historyData);
    }
  }

  // 有氧專用的彈出視窗
  Future<void> _showCardioDialog(int index, String exerciseName) async {
    TextEditingController calController = TextEditingController();
    await showDialog(
      context: context,
      barrierDismissible: false, // 避免點擊旁邊關閉
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text("完成 $exerciseName", style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: calController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "請輸入消耗的卡路里 (kcal)",
            hintStyle: TextStyle(color: Colors.white54),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("取消", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () async {
              int calories = int.tryParse(calController.text) ?? 0;
              Navigator.pop(context); // 關閉視窗
              await _markAsCompletedAndSave(index, calories: calories); // 存檔
            },
            child: const Text("儲存", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // 核心訓練邏輯
  Future<void> _startTrainingProcess() async {
    int nextIndex = _getNextUncompletedIndex();
    if (nextIndex == -1) return;

    Map<String, dynamic> currentExercise = _todayWorkout[nextIndex];
    String exerciseName = currentExercise['name'] ?? '';
    String category = currentExercise['category'] ?? '';

    // 情況 1：如果是【休息】
    if (category == '休息' || exerciseName == '睡覺') {
      await _markAsCompletedAndSave(nextIndex, isRest: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("💤 已記錄為休息！"), backgroundColor: Colors.orangeAccent),
        );
      }
      return;
    }

    // 情況 2：如果是【有氧】
    if (category == '有氧' || exerciseName == '跑步機' || exerciseName == '飛輪') {
      await _showCardioDialog(nextIndex, exerciseName);
      return;
    }

    // 情況 3：一般重量訓練
    final dynamic result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TrainingScreen(exerciseName: exerciseName)),
    );

    // 只要有回傳值，且不是 false（代表不是按取消離開的）
    if (result != null && result != false && context.mounted) {
      int actualReps;

      // 檢查收到的 result 是不是數字
      if (result is int) {
        actualReps = result;
      } else {
        // 防呆機制：萬一還是收到 true，就用預設計算
        actualReps = (_todayWorkout[nextIndex]['sets'] ?? 1) * (_todayWorkout[nextIndex]['reps'] ?? 0);
      }

      // 將真實次數傳進去存檔
      await _markAsCompletedAndSave(nextIndex, actualReps: actualReps);
    }
  }

  @override
  Widget build(BuildContext context) {
    int nextIndex = _getNextUncompletedIndex();
    bool isAllCompleted = _todayWorkout.isNotEmpty && nextIndex == -1;
    String buttonText = '進入第一項訓練';

    if (isAllCompleted) {
      buttonText = '今日訓練已全數完成！';
    } else if (nextIndex != -1) {
      buttonText = nextIndex == 0 ? '開始: ${_todayWorkout[0]['name']}' : '繼續: ${_todayWorkout[nextIndex]['name']}';
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('開始運動', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  setState(() { _selectedDate = picked; });
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
                    const Text('訓練日期', style: TextStyle(color: Colors.white, fontSize: 16)),
                    Text(
                      "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}",
                      style: const TextStyle(color: Colors.blueAccent, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

            const Text('訓練清單', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            const Text('長按右側圖示可上下拖曳調整順序，左滑可刪除動作。', style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 15),

            // --- 動作清單 ---
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                  : _todayWorkout.isEmpty
                  ? const Center(
                child: Text('今天沒有安排菜單喔！\n快去「菜單規劃」新增吧', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16, height: 1.5)),
              )
                  : ReorderableListView.builder(
                itemCount: _todayWorkout.length,
                onReorder: (int oldIndex, int newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = _todayWorkout.removeAt(oldIndex);
                    _todayWorkout.insert(newIndex, item);
                  });
                  _updateWorkoutInFirebase();
                },
                itemBuilder: (context, index) {
                  final exercise = _todayWorkout[index];
                  final exerciseName = exercise['name'] ?? '未知動作';
                  final category = exercise['category'] ?? '';
                  final sets = exercise['sets'] ?? 3;
                  final reps = exercise['reps'] ?? 12;
                  final bool isCompleted = exercise['isCompleted'] == true;

                  // 判斷是否為有氧或休息，來改變顯示文字
                  bool isCardio = category == '有氧' || exerciseName == '跑步機' || exerciseName == '飛輪';
                  bool isRest = category == '休息' || exerciseName == '睡覺';

                  return Dismissible(
                    key: Key('${exerciseName}_$index'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(15)),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (direction) {
                      setState(() { _todayWorkout.removeAt(index); });
                      _updateWorkoutInFirebase();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isCompleted ? Colors.grey[900]!.withAlpha(120) : Colors.grey[900],
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: isCompleted ? Colors.green.withAlpha(127) : Colors.grey[800]!),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isCompleted ? Colors.green.withAlpha(50) : Colors.blueAccent.withAlpha(50),
                          child: isCompleted
                              ? const Icon(Icons.check, color: Colors.green)
                              : Icon(isRest ? Icons.bed : (isCardio ? Icons.directions_run : Icons.fitness_center), color: Colors.blueAccent, size: 20),
                        ),
                        title: Text(
                            exerciseName,
                            style: TextStyle(
                              color: isCompleted ? Colors.grey : Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                            )
                        ),
                        subtitle: Text(
                            isRest ? '恢復與休息' : (isCardio ? '有氧訓練' : '建議組數: $sets組 x $reps下'),
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
                  backgroundColor: (_todayWorkout.isEmpty || isAllCompleted) ? Colors.grey[800] : Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: (_todayWorkout.isEmpty || isAllCompleted)
                    ? null
                    : _startTrainingProcess,
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}