import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MenuPlanningScreen extends StatefulWidget {
  const MenuPlanningScreen({super.key});

  @override
  State<MenuPlanningScreen> createState() => _MenuPlanningScreenState();
}

class _MenuPlanningScreenState extends State<MenuPlanningScreen> {
  // 🌟 1. 專業級動作資料庫 (完美移植妳的圖片分類)
  final Map<String, Map<String, List<String>>> _exerciseDatabase = {
    '胸': {
      '上胸': ['上斜槓鈴臥推', '上斜啞鈴臥推', '低到高滑輪夾胸', '滑輪上斜夾胸', '上斜機械推'],
      '中胸': ['平板槓鈴臥推', '平板啞鈴臥推', '蝴蝶機'],
      '下胸': ['雙槓臂屈伸', '高到低滑輪夾胸', '下斜胸推機'],
    },
    '背': {
      '上背 (厚度)': ['正握槓鈴划船', 'T-Bar Row', '寬握坐姿划船'],
      '背闊肌 (寬)': ['寬握高位下拉', '單手啞鈴划船'],
      '下背闊': ['反握槓鈴划船', '窄握高位下拉'],
    },
    '腿': {
      '股四頭肌': ['深蹲', '腿伸肌', '分腿蹲'],
      '股二頭肌': ['羅馬尼亞硬舉', '趴姿腿彎舉', '坐姿腿彎舉'],
      '臀': ['保加利亞分腿蹲', '臀推'],
      '小腿': ['站姿提踵', '坐姿提踵'],
      '腿推機變化': ['腿推機踩踏板下方 (股四頭肌)', '踩踏板中間 (股四頭肌+臀肌)', '踩踏板上方 (股二頭肌)', '腳踩寬 (內收肌)'],
    },
    '肩': {
      '前束': ['站姿槓鈴肩推', '坐姿啞鈴肩推', '前平舉'],
      '中束': ['啞鈴飛鳥', '滑輪側平舉', '側平舉機'],
      '後束': ['反向夾胸機', '俯身飛鳥', '滑輪後三角飛鳥'],
    },
    '手': {
      '二頭肌': ['W槓彎舉', '啞鈴交替彎舉', '牧師椅彎舉', '上斜啞鈴彎舉', '捶式彎舉'],
      '三頭肌': ['窄握臥推', '繩索下壓', 'W槓過頭屈伸'],
      '前臂': ['手腕彎舉', '反向手腕彎舉'],
    },
    '有氧': {

    },
    '休息': {

    }
  };

  // 2. 狀態變數 (修正重複宣告)
  String _selectedBodyPart = '胸';
  final List<String> _selectedExercises = [];

  // 🌟 新增 1：用來記錄使用者選擇的日期 (預設為今天)
  DateTime _selectedDate = DateTime.now();

  // 🌟 新增 2：儲存到 Firebase 的函數
  // 🌟 修正版：儲存到 Firebase 的函數 (解決陣列覆蓋問題)
  Future<void> _saveWorkoutPlanToFirebase() async {
    String dateString = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

    List<Map<String, dynamic>> exercisesToSave = _selectedExercises.map((exerciseName) {
      return {
        'name': exerciseName,
        'sets': 3,
        'reps': 12,
        'isCompleted': false,
      };
    }).toList();

    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc('test_user')
          .collection('daily_workouts')
          .doc(dateString);

      // 1. 先把今天的雲端資料抓下來看看
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists && docSnapshot.data() != null && docSnapshot.data()!.containsKey('exercises')) {
        // 2. 如果今天已經有存過動作了，我們就把舊的拿出來，新的加進去
        List<dynamic> existingExercises = docSnapshot.get('exercises');
        existingExercises.addAll(exercisesToSave); // 追加到舊陣列後面

        // 更新回資料庫
        await docRef.update({
          'exercises': existingExercises,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        // 3. 如果今天是空的，就照原本的方式直接建立
        await docRef.set({
          'date': dateString,
          'timestamp': FieldValue.serverTimestamp(),
          'exercises': exercisesToSave,
        });
      }

      debugPrint("✅ 菜單追加/儲存成功！日期：$dateString");
    } catch (e) {
      debugPrint("❌ 儲存失敗: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('📝 菜單規劃', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 選擇日期區塊 ---
            GestureDetector(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
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
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
                margin: const EdgeInsets.only(bottom: 15), // 修正 margin 語法
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('📅 選擇訓練日期', style: TextStyle(color: Colors.white, fontSize: 16)),
                    Text(
                      "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}",
                      style: const TextStyle(color: Colors.blueAccent, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

            // --- 區塊 1：選擇部位 ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedBodyPart,
                  isExpanded: true,
                  dropdownColor: Colors.grey[900],
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  items: _exerciseDatabase.keys.map((String part) {
                    return DropdownMenuItem<String>(
                      value: part,
                      child: Text('鍛鍊部位：$part'),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      if (newValue != null) {
                        _selectedBodyPart = newValue;
                      }
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- 區塊 2：動態生成的動作清單 ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('選擇動作', style: TextStyle(color: Colors.grey, fontSize: 16)),
                Text('已選: ${_selectedExercises.length} 項', style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),

            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[800]!),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.black26,
                ),
                child: ListView(
                  padding: const EdgeInsets.all(10),
                  children: _buildExerciseList(),
                ),
              ),
            ),

            // --- 區塊 3：底部加入按鈕 ---
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                // 修正：補回 icon 和 label
                icon: const Icon(Icons.add_task, color: Colors.white),
                label: const Text('加入訓練菜單', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedExercises.isEmpty ? Colors.grey[800] : Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: _selectedExercises.isEmpty
                    ? null
                    : () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('儲存中...'), duration: Duration(seconds: 1)),
                  );

                  await _saveWorkoutPlanToFirebase();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('成功將 ${_selectedExercises.length} 個動作加入 ${_selectedDate.month}/${_selectedDate.day} 菜單！'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🌟 動態生成清單與子標題的函數
  List<Widget> _buildExerciseList() {
    List<Widget> listItems = [];
    var subCategories = _exerciseDatabase[_selectedBodyPart]!;

    subCategories.forEach((subCategory, exercises) {
      listItems.add(
        Padding(
          padding: const EdgeInsets.only(top: 15, bottom: 8, left: 5),
          child: Text(
              subCategory,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
          ),
        ),
      );

      for (var exercise in exercises) {
        final isChecked = _selectedExercises.contains(exercise);
        listItems.add(
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: isChecked ? Colors.blueAccent.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: CheckboxListTile(
                title: Text(
                    exercise,
                    style: TextStyle(
                        color: isChecked ? Colors.white : Colors.white70,
                        fontWeight: isChecked ? FontWeight.bold : FontWeight.normal
                    )
                ),
                activeColor: Colors.blueAccent,
                checkColor: Colors.white,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: const EdgeInsets.symmetric(horizontal: 5),
                dense: true,
                value: isChecked,
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedExercises.add(exercise);
                    } else {
                      _selectedExercises.remove(exercise);
                    }
                  });
                },
              ),
            )
        );
      }
    });

    return listItems;
  }
}