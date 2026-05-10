import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/pose_painter.dart';
import 'dart:typed_data';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../data/exercise_dictionary.dart';

import '../trainers/bicep_trainer.dart';
import '../trainers/squat_trainer.dart';
import '../trainers/shoulder_press_trainer.dart';
import '../trainers/incline_press_trainer.dart';
import '../trainers/rdl_trainer.dart';
import '../trainers/barbell_row_trainer.dart';
import '../trainers/bench_press_trainer.dart';
import '../trainers/tricep_extension_trainer.dart';

class TrainingScreen extends StatefulWidget {
  final String exerciseName;

  const TrainingScreen({super.key, required this.exerciseName});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  CustomPaint? _customPaint;

  final PoseDetector _poseDetector = PoseDetector(options: PoseDetectorOptions());
  bool _canProcess = true;
  bool _isBusy = false;

  final BicepTrainer _bicepTrainer = BicepTrainer();
  final SquatTrainer _squatTrainer = SquatTrainer();
  final ShoulderPressTrainer _shoulderPressTrainer = ShoulderPressTrainer();  final InclinePressTrainer _inclineTrainer = InclinePressTrainer();
  final RdlTrainer _rdlTrainer = RdlTrainer();
  final BarbellRowTrainer _barbellRowTrainer = BarbellRowTrainer();
  final BenchPressTrainer _benchPressTrainer = BenchPressTrainer();
  final TricepExtensionTrainer _tricepTrainer = TricepExtensionTrainer();

  int _repCounter = 0;
  double _primaryAngle = 0.0;
  String _feedbackMessage = "準備中，請站入畫面...";
  Color _feedbackColor = Colors.white.withOpacity(0.05);

  final FlutterTts flutterTts = FlutterTts();
  String _lastSpokenMessage = '';
  DateTime _lastWarningTime = DateTime.now();

  int _currentSet = 0;
  bool _hasAiDetection = true;

  @override
  void initState() {
    super.initState();
    _checkAiSupport();
    _initTts();
    _initCamera();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowTutorial();
    });
  }

  void _checkAiSupport() {
    if (!widget.exerciseName.contains('二頭') &&
        !widget.exerciseName.contains('彎舉') &&
        !widget.exerciseName.contains('深蹲') &&
        !widget.exerciseName.contains('肩推') &&
        !widget.exerciseName.contains('硬舉') &&
        !widget.exerciseName.contains('划船') &&
        !widget.exerciseName.contains('RDL') &&
        !widget.exerciseName.contains('屈伸') &&
        !widget.exerciseName.contains('臥推')) {

      setState(() { // 有 setState 才會更新畫面
        _hasAiDetection = false;
        _feedbackMessage = "此動作無 AI 計數，請自主訓練並手動儲存";
      });
    }
  }

  Future<void> _checkAndShowTutorial({bool forceShow = false}) async {
    final prefs = await SharedPreferences.getInstance();
    bool hasSeen = prefs.getBool('tutorial_${widget.exerciseName}') ?? false;

    if (!hasSeen || forceShow) {
      if (!mounted) return;
      _showTutorialDialog();
      await prefs.setBool('tutorial_${widget.exerciseName}', true);
    }
  }

  void _showTutorialDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.fitness_center, color: Colors.blueAccent),
            const SizedBox(width: 10),
            Expanded(child: Text("${widget.exerciseName} 教學", style: const TextStyle(color: Colors.white))),
          ],
        ),
        content: Text(
          _getTutorialText(widget.exerciseName),
          style: const TextStyle(color: Colors.white70, height: 1.5, fontSize: 16),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("我知道了", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  String _getTutorialText(String name) {
    return ExerciseDictionary.get(name);
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage("zh-TW");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
  }

  // 修好的相機初始化，防當機、防黑屏
  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        final frontCamera = _cameras!.firstWhere((c) => c.lensDirection == CameraLensDirection.front, orElse: () => _cameras!.first);
        _cameraController = CameraController(
          frontCamera,
          ResolutionPreset.medium,
          enableAudio: false,
          imageFormatGroup: defaultTargetPlatform == TargetPlatform.iOS
              ? ImageFormatGroup.bgra8888
              : ImageFormatGroup.nv21,
        );

        await _cameraController!.initialize();
        if (!mounted) return;
        setState(() { _isCameraInitialized = true; });

        _cameraController!.startImageStream((CameraImage image) {
          // 瘋狂印出狀態，看是不是卡在某個布林值
          debugPrint("🔄 收到影格! isBusy: $_isBusy");
          if (_isBusy) return;
          _isBusy = true;
          _processImage(image);
        });
      }
    } catch (e) { debugPrint("❌ 相機初始化失敗: $e"); }
  }

  // 處理圖片邏輯
  Future<void> _processImage(CameraImage image) async {
    debugPrint("📸 進入 _processImage！圖片格式 raw: ${image.format.raw}");

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) {
        debugPrint("⚠️ 糟糕！_inputImageFromCameraImage 回傳了 null，轉換失敗！");
        _isBusy = false;
        return;
      }

      debugPrint("🧠 影像轉換成功！準備交給 AI 分析...");
      final poses = await _poseDetector.processImage(inputImage);

      debugPrint("🤖 AI 分析完畢！抓到 ${poses.length} 個人");

      if (mounted) {
        setState(() {
          if (poses.isNotEmpty) {
            // 補上 CameraLensDirection.front
            _customPaint = CustomPaint(
                painter: PosePainter(
                  poses,
                  inputImage.metadata!.size,
                  inputImage.metadata!.rotation,
                  CameraLensDirection.front,
                )
            );
            _delegateToTrainer(poses.first);
          } else {
            _customPaint = null;
          }
        });
      }
    } catch (e) {
      debugPrint("❌ 骨架偵測發生錯誤: $e");
    } finally {
      _isBusy = false;
      debugPrint("✅ 單張影格處理結束，釋放 isBusy");
    }
  }

  // 修好的格式轉換，完美支援所有手機
  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameras == null || _cameras!.isEmpty) return null;
    final camera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras!.first,
    );

    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (defaultTargetPlatform == TargetPlatform.android) {
      var rotationCompensation = (sensorOrientation + 0) % 360;
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    } else {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    }

    if (rotation == null) return null;

    final int width = image.width;
    final int height = image.height;

    // 算出 ML Kit 嚴格要求的「完美陣列長度」 (長 x 寬 x 1.5)
    final int ySize = width * height;
    final int uvSize = ySize ~/ 2;
    final Uint8List nv21Bytes = Uint8List(ySize + uvSize);

    final Uint8List yPlane = image.planes[0].bytes;
    final int stride = image.planes[0].bytesPerRow; // 包含 padding 的實際寬度

    // 核心魔法：一行一行複製，把手機相機偷偷加的 Padding 剪掉！
    for (int y = 0; y < height; y++) {
      final int srcOffset = y * stride;
      final int dstOffset = y * width;
      // 安全保護，避免讀取超出範圍
      if (srcOffset + width <= yPlane.length) {
        nv21Bytes.setRange(dstOffset, dstOffset + width, yPlane.sublist(srcOffset, srcOffset + width));
      }
    }

    // U/V 通道填入 128 (代表純灰色，消除所有彩色雜訊)
    nv21Bytes.fillRange(ySize, ySize + uvSize, 128);

    final Size imageSize = Size(width.toDouble(), height.toDouble());
    final InputImageMetadata imageMetadata = InputImageMetadata(
      size: imageSize,
      rotation: rotation,
      format: InputImageFormat.nv21,
      //
      bytesPerRow: width,
    );

    return InputImage.fromBytes(bytes: nv21Bytes, metadata: imageMetadata);
  }

  // AI 派發中心

  void _delegateToTrainer(Pose pose) {
    if (widget.exerciseName.contains('二頭') || widget.exerciseName.contains('彎舉')) {
      _processBicep(pose);
    } else if (widget.exerciseName.contains('深蹲')) {
      _processSquat(pose);
    } else if (widget.exerciseName.contains('肩推')) {
      _processShoulderPress(pose);
    } else if (widget.exerciseName.contains('硬舉') || widget.exerciseName.contains('RDL')) {
      _processRdl(pose);
    } else if (widget.exerciseName.contains('划船')) {
      _processRow(pose);
    }
    else if (widget.exerciseName.contains('屈伸')) {
      _processTricepExtension(pose);
    }
    //只要名字裡同時有「上斜」跟「臥推」，就一定是上斜臥推系列！(不管啞鈴還槓鈴、不管順序)
    else if (widget.exerciseName.contains('上斜') && widget.exerciseName.contains('臥推')) {
      _processInclinePress(pose);
    }
    //剩下的，只要有「臥推」兩個字，通通歸類給平板臥推！
    else if (widget.exerciseName.contains('臥推')) {
      _processBenchPress(pose);
    }
  }

  // --- 教練 1：二頭肌 ---
  void _processBicep(Pose pose) {
    final shoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final elbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final wrist = pose.landmarks[PoseLandmarkType.rightWrist];

    if (shoulder != null && elbow != null && wrist != null) {
      double angle = _bicepTrainer.calculateAngle(shoulder.x, shoulder.y, elbow.x, elbow.y, wrist.x, wrist.y);
      _primaryAngle = angle;
      _bicepTrainer.processPose(angle);
      _repCounter = _bicepTrainer.counter;
      _feedbackMessage = _bicepTrainer.feedback;
      _updateFeedbackColor(_feedbackMessage);
      _speakIfNeeded(_feedbackMessage);
    }
  }

  // --- 教練 2：深蹲 ---
  void _processSquat(Pose pose) {
    final shoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final hip = pose.landmarks[PoseLandmarkType.rightHip];
    final knee = pose.landmarks[PoseLandmarkType.rightKnee];
    final ankle = pose.landmarks[PoseLandmarkType.rightAnkle];

    if (shoulder != null && hip != null && knee != null && ankle != null) {
      double kneeAngle = _squatTrainer.calculateAngle(hip.x, hip.y, knee.x, knee.y, ankle.x, ankle.y);
      double torsoAngle = _squatTrainer.calculateTorsoAngle(shoulder.x, shoulder.y, hip.x, hip.y);
      _primaryAngle = kneeAngle;
      _squatTrainer.processPose(kneeAngle: kneeAngle, torsoAngle: torsoAngle);
      _repCounter = _squatTrainer.counter;
      _feedbackMessage = _squatTrainer.feedback;
      _updateFeedbackColor(_feedbackMessage, isWarning: _squatTrainer.isBadForm);
      _speakIfNeeded(_feedbackMessage, isWarning: _squatTrainer.isBadForm);
    }
  }



  // --- 教練 3：肩推 ---
  void _processShoulderPress(Pose pose) {
    final lShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final lElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final lWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final rElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final rWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    // 必須同時抓到上半身 6 個點才會啟動
    if (lShoulder != null && lElbow != null && lWrist != null &&
        rShoulder != null && rElbow != null && rWrist != null) {

      // 計算四個角度
      double lArmAngle = _shoulderPressTrainer.calculateAngle(lShoulder.x, lShoulder.y, lElbow.x, lElbow.y, lWrist.x, lWrist.y);
      double rArmAngle = _shoulderPressTrainer.calculateAngle(rShoulder.x, rShoulder.y, rElbow.x, rElbow.y, rWrist.x, rWrist.y);
      double lTuckAngle = _shoulderPressTrainer.calculateAngle(rShoulder.x, rShoulder.y, lShoulder.x, lShoulder.y, lElbow.x, lElbow.y);
      double rTuckAngle = _shoulderPressTrainer.calculateAngle(lShoulder.x, lShoulder.y, rShoulder.x, rShoulder.y, rElbow.x, rElbow.y);

      // 畫面顯示右手的角度
      _primaryAngle = rArmAngle;

      // 丟給教練處理
      _shoulderPressTrainer.processPose(
        leftArmAngle: lArmAngle,
        rightArmAngle: rArmAngle,
        leftTuckAngle: lTuckAngle,
        rightTuckAngle: rTuckAngle,
        exerciseName: widget.exerciseName, // 傳入名稱讓它判斷站姿還坐姿
      );

      _repCounter = _shoulderPressTrainer.counter;
      _feedbackMessage = _shoulderPressTrainer.feedback;

      bool isWarning = _feedbackMessage.contains('!!!');
      _updateFeedbackColor(_feedbackMessage, isWarning: isWarning);
      _speakIfNeeded(_feedbackMessage, isWarning: isWarning);
    }
  }

  // --- 教練 4：上斜臥推 ---
  void _processInclinePress(Pose pose) {
    final lShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final lElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final lWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final rElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final rWrist = pose.landmarks[PoseLandmarkType.rightWrist];

    if (lShoulder != null && lElbow != null && lWrist != null && rShoulder != null && rElbow != null && rWrist != null) {
      double lArmAngle = _inclineTrainer.calculateAngle(lShoulder.x, lShoulder.y, lElbow.x, lElbow.y, lWrist.x, lWrist.y);
      double rArmAngle = _inclineTrainer.calculateAngle(rShoulder.x, rShoulder.y, rElbow.x, rElbow.y, rWrist.x, rWrist.y);
      double lTuckAngle = _inclineTrainer.calculateAngle(rShoulder.x, rShoulder.y, lShoulder.x, lShoulder.y, lElbow.x, lElbow.y);
      double rTuckAngle = _inclineTrainer.calculateAngle(lShoulder.x, lShoulder.y, rShoulder.x, rShoulder.y, rElbow.x, rElbow.y);

      _primaryAngle = rArmAngle;
      _inclineTrainer.processPose(leftArmAngle: lArmAngle, rightArmAngle: rArmAngle, leftTuckAngle: lTuckAngle, rightTuckAngle: rTuckAngle);

      _repCounter = _inclineTrainer.counter;
      _feedbackMessage = _inclineTrainer.feedback;
      bool isWarning = _feedbackMessage.contains('!!!');
      _updateFeedbackColor(_feedbackMessage, isWarning: isWarning);
      _speakIfNeeded(_feedbackMessage, isWarning: isWarning);
    }
  }

  // --- 教練 5：羅馬尼亞硬舉 (RDL) ---
  void _processRdl(Pose pose) {
    _rdlTrainer.processPose(pose);

    final shoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final hip = pose.landmarks[PoseLandmarkType.rightHip];
    final knee = pose.landmarks[PoseLandmarkType.rightKnee];

    if (shoulder != null && hip != null && knee != null) {
      _primaryAngle = _rdlTrainer.calculateAngle(shoulder, hip, knee);
    }

    _repCounter = _rdlTrainer.counter;
    _feedbackMessage = _rdlTrainer.feedbackMessage;

    bool isWarning = _feedbackMessage.contains('!!!');
    _updateFeedbackColor(_feedbackMessage, isWarning: isWarning);
    _speakIfNeeded(_feedbackMessage, isWarning: isWarning);
  }

  // --- 教練 6：槓鈴划船 ---
  void _processRow(Pose pose) {
    // 把 pose 跟現在的運動名稱傳進去
    _barbellRowTrainer.processPose(pose, exerciseName: widget.exerciseName);

    // 抓取肩膀、手肘、手腕來算畫面要顯示的「目前角度」
    final shoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final elbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final wrist = pose.landmarks[PoseLandmarkType.rightWrist];

    if (shoulder != null && elbow != null && wrist != null) {
      _primaryAngle = _barbellRowTrainer.calculateAngle(shoulder, elbow, wrist);    }

    _repCounter = _barbellRowTrainer.counter;
    _feedbackMessage = _barbellRowTrainer.feedbackMessage;

    _updateFeedbackColor(_feedbackMessage, isWarning: _barbellRowTrainer.isBadForm);
    _speakIfNeeded(_feedbackMessage, isWarning: _barbellRowTrainer.isBadForm);
  }

  void _updateFeedbackColor(String message, {bool isWarning = false}) {
    if (isWarning) {
      _feedbackColor = Colors.redAccent.withOpacity(0.3);
    } else if (message.contains("完成") || message.contains("完美") || message.contains("好")) {
      _feedbackColor = Colors.greenAccent.withOpacity(0.2);
    } else if (message.contains("推") || message.contains("站起") || message.contains("彎舉") || message.contains("碰胸")) {
      _feedbackColor = Colors.purpleAccent.withOpacity(0.2);
    } else {
      _feedbackColor = Colors.blueAccent.withOpacity(0.15);
    }
  }

  // --- 教練 7：平板臥推 (啞鈴/槓鈴共用) ---
  void _processBenchPress(Pose pose) {
    _benchPressTrainer.processPose(pose, exerciseName: widget.exerciseName);

    final shoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final elbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final wrist = pose.landmarks[PoseLandmarkType.rightWrist];

    if (shoulder != null && elbow != null && wrist != null) {
      _primaryAngle = _benchPressTrainer.calculateAngle(shoulder, elbow, wrist);
    }

    _repCounter = _benchPressTrainer.counter;
    _feedbackMessage = _benchPressTrainer.feedbackMessage;

    bool isWarning = _benchPressTrainer.isBadForm;
    _updateFeedbackColor(_feedbackMessage, isWarning: isWarning);
    _speakIfNeeded(_feedbackMessage, isWarning: isWarning);
  }

  Future<void> _speakIfNeeded(String text, {bool isWarning = false}) async {
    if (isWarning) {
      if (DateTime.now().difference(_lastWarningTime).inSeconds > 3) {
        await flutterTts.speak(text.replaceAll('⚠️', ''));
        _lastWarningTime = DateTime.now();
      }
    } else {
      if (_lastSpokenMessage != text) {
        String speakText = text.replaceAll('💡', '').replaceAll('⬇️', '').replaceAll('⬆️', '');
        if (speakText.length < 15) await flutterTts.speak(speakText);
        _lastSpokenMessage = text;
      }
    }
  }

  // --- 教練 8：過頭屈伸 ---
  void _processTricepExtension(Pose pose) {
    _tricepTrainer.processPose(pose);

    final shoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final elbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final wrist = pose.landmarks[PoseLandmarkType.rightWrist];

    // 顯示右手肘的角度
    if (shoulder != null && elbow != null && wrist != null) {
      _primaryAngle = _tricepTrainer.calculateAngle(shoulder, elbow, wrist);
    }

    _repCounter = _tricepTrainer.counter;
    _feedbackMessage = _tricepTrainer.feedback;

    bool isWarning = _tricepTrainer.isBadForm;
    _updateFeedbackColor(_feedbackMessage, isWarning: isWarning);
    _speakIfNeeded(_feedbackMessage, isWarning: isWarning);
  }

  Widget _buildGlassBox({required Widget child, double blur = 10.0, Color? borderColor, double borderRadius = 20.0, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: borderColor ?? Colors.white.withOpacity(0.15), width: 1.5),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildSetDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        bool isCompleted = index < _currentSet;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted ? Colors.greenAccent : Colors.grey.withOpacity(0.4),
            boxShadow: isCompleted ? [BoxShadow(color: Colors.greenAccent.withOpacity(0.5), blurRadius: 8)] : [],
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isCameraInitialized
          ? Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _cameraController!.value.previewSize!.height,
              height: _cameraController!.value.previewSize!.width,
              child: CameraPreview(_cameraController!),
            ),
          ),
          if (_customPaint != null && _hasAiDetection) _customPaint!,
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  child: _buildGlassBox(
                    borderRadius: 15,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context, true)),
                            Expanded(child: Center(child: Text(widget.exerciseName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)))),
                            IconButton(icon: const Icon(Icons.info_outline, color: Colors.white), onPressed: () => _checkAndShowTutorial(forceShow: true)),
                          ],
                        ),
                        const SizedBox(height: 5),
                        _buildSetDots(),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: _buildGlassBox(
                    blur: 15.0,
                    borderColor: _feedbackColor,
                    child: Center(
                      child: Text(
                        _feedbackMessage,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: _buildGlassBox(
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.blueAccent.withOpacity(0.5), width: 1.5),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_hasAiDetection)
                                  Text("目前角度: ${_primaryAngle.toStringAsFixed(0)}°", style: const TextStyle(color: Colors.yellow, fontSize: 14)),
                                const SizedBox(height: 5),
                                Text("次數: $_repCounter", style: const TextStyle(color: Colors.greenAccent, fontSize: 22, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          flex: 1,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: SizedBox(
                              height: 80,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.save, color: Colors.white, size: 28),
                                label: Text(
                                    _currentSet < 2 ? "存檔\n(下一組)" : "完成\n訓練",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
                                ),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.7), elevation: 0),
                                  onPressed: () async {
                                    // 顯示個小提示讓使用者知道有按到
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(_currentSet < 2 ? '這組完成！' : '訓練完成，正在儲存...'),
                                          duration: const Duration(seconds: 1)
                                      ),
                                    );

                                    if (_currentSet < 2) {
                                      // === 還沒練滿 3 組：換組並重置 ===
                                      setState(() {
                                        _currentSet++;
                                        _repCounter = 0;
                                        _primaryAngle = 0;

                                        // 重置所有教練
                                        _bicepTrainer.reset();
                                        _squatTrainer.reset();
                                        _shoulderPressTrainer.reset();
                                        _inclineTrainer.reset();
                                        _rdlTrainer.reset();
                                        _barbellRowTrainer.reset();
                                        _benchPressTrainer.reset();
                                        _tricepTrainer.reset();

                                        _feedbackMessage = "休息一下！準備開始第 ${_currentSet + 1} 組";
                                      });
                                    } else {
                                      // === 練滿 3 組了：準備離開 ===
                                      setState(() {
                                        _currentSet = 3;
                                        _canProcess = false; // 停止 AI 運算
                                      });

                                      // 稍等半秒，讓畫面把第三顆綠色圈圈亮起來
                                      await Future.delayed(const Duration(milliseconds: 500));

                                      // 關鍵：帶著 true 退回上一頁，讓 start_workout_screen 去更新 Firebase！
                                      if (context.mounted) {
                                        Navigator.pop(context, true);
                                      }
                                    }
                                  },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      )
          : const Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }

  @override
  void dispose() {
    _canProcess = false;
    flutterTts.stop();
    _poseDetector.close();
    _cameraController?.dispose();
    super.dispose();
  }
}