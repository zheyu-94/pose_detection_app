import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math' as math;

class RdlTrainer {
  int counter = 0;
  bool isDown = false;
  String feedbackMessage = "準備中...";

  // 把角度計算的邏輯也搬進來
  double calculateAngle(PoseLandmark p1, PoseLandmark p2, PoseLandmark p3) {
    double angle = math.atan2(p3.y - p2.y, p3.x - p2.x) -
        math.atan2(p1.y - p2.y, p1.x - p2.x);
    double degree = (angle * 180 / math.pi).abs();
    if (degree > 180.0) {
      degree = 360.0 - degree;
    }
    return degree;
  }


  // 每次相機抓到新骨架，就呼叫這個 Function
  void processPose(Pose pose) {
    final shoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final hip = pose.landmarks[PoseLandmarkType.rightHip];
    final knee = pose.landmarks[PoseLandmarkType.rightKnee];
    final ankle = pose.landmarks[PoseLandmarkType.rightAnkle];

    if (shoulder != null && hip != null && knee != null && ankle != null) {
      double hipAngle = calculateAngle(shoulder, hip, knee);
      double kneeAngle = calculateAngle(hip, knee, ankle);

      // --- RDL 判斷邏輯開始 ---
      if (kneeAngle < 130) {
        feedbackMessage = "膝蓋彎太多了！屁股往後推！";
        return;
      }

      if (hipAngle < 110 && kneeAngle >= 130) {
        if (!isDown) {
          isDown = true;
          feedbackMessage = "很好！現在站直！";
        }
      }

      if (hipAngle > 160) {
        if (isDown) {
          isDown = false;
          counter++;
          feedbackMessage = "漂亮！完成 1 次";
        }
      }
    }
  }

  void reset() {
    counter = 0;
    isDown = false;
    feedbackMessage = "準備中...";
  }
}