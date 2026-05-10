import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math' as math;

class BenchPressTrainer {
  int counter = 0;
  bool isDown = false;
  String feedbackMessage = "準備中...";
  bool isBadForm = false;

  // 公開的角度計算工具
  double calculateAngle(PoseLandmark p1, PoseLandmark p2, PoseLandmark p3) {
    double angle = math.atan2(p3.y - p2.y, p3.x - p2.x) -
        math.atan2(p1.y - p2.y, p1.x - p2.x);
    double degree = (angle * 180 / math.pi).abs();
    if (degree > 180.0) {
      degree = 360.0 - degree;
    }
    return degree;
  }

  void processPose(Pose pose, {String exerciseName = "臥推"}) {
    // 臥推通常拍側面，我們抓單側(例如右側)的手臂來判斷即可
    final shoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final elbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final wrist = pose.landmarks[PoseLandmarkType.rightWrist];

    if (shoulder != null && elbow != null && wrist != null) {
      double armAngle = calculateAngle(shoulder, elbow, wrist);

      // 【動作下放】啞鈴/槓鈴下放到胸口 (手肘小於 85 度)
      if (armAngle < 85) {
        if (!isDown) {
          isDown = true;
          isBadForm = false;

          // 根據名稱給不同提示
          if (exerciseName.contains('啞鈴')) {
            feedbackMessage = "推！頂點可以微夾胸！";
          } else {
            feedbackMessage = "推！腳踩穩！";
          }
        }
      }

      // 【動作推起】手臂伸直 (大於 150 度)
      if (armAngle > 150) {
        if (isDown) {
          isDown = false;
          counter++;
          isBadForm = false;
          feedbackMessage = "漂亮！放慢下放";
        }
      }
    }
  }

  void reset() {
    counter = 0;
    isDown = false;
    feedbackMessage = "準備中...";
    isBadForm = false;
  }
}