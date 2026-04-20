import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class TricepExtensionTrainer {
  static const int stateTop = 0;    // 狀態：手臂伸直在頭頂
  static const int stateBottom = 1; // 狀態：手臂彎曲在腦後

  int counter = 0;
  int currentState = stateTop;
  String feedback = "💡 準備：將W槓高舉過頭，大臂盡量貼近耳朵";
  bool isBadForm = false;

  double calculateAngle(PoseLandmark p1, PoseLandmark p2, PoseLandmark p3) {
    double angle = atan2(p3.y - p2.y, p3.x - p2.x) - atan2(p1.y - p2.y, p1.x - p2.x);
    double degree = (angle * 180 / pi).abs();
    if (degree > 180.0) degree = 360.0 - degree;
    return degree;
  }

  void processPose(Pose pose) {
    // 側拍視角最清楚，這裡抓右手作為代表計算
    final shoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final elbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final wrist = pose.landmarks[PoseLandmarkType.rightWrist];

    if (shoulder != null && elbow != null && wrist != null) {
      double armAngle = calculateAngle(shoulder, elbow, wrist);

      if (currentState == stateTop) {
        // 下放到腦後（角度小於 80 度）
        if (armAngle <= 80.0) {
          currentState = stateBottom;
          feedback = "很好！三頭肌發力推直！";
          isBadForm = false;
        } else if (armAngle <= 120.0) {
          feedback = "控制重量慢慢下放...";
        }
      } else if (currentState == stateBottom) {
        // 向上推直到頂（角度大於 150 度）
        if (armAngle >= 150.0) {
          counter++;
          currentState = stateTop;
          feedback = "完成 $counter 次！擠壓三頭肌！";
          isBadForm = false;
        }
      }
    }
  }

  void reset() {
    counter = 0;
    currentState = stateTop;
    feedback = "💡 準備：將W槓高舉過頭，大臂盡量貼近耳朵";
    isBadForm = false;
  }
}