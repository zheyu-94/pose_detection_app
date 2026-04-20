import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math' as math;

class BarbellRowTrainer {
  int counter = 0;
  bool isPulling = false;
  String feedbackMessage = "準備中...";
  bool isBadForm = false; // 用來觸發紅色警告背景

  double calculateAngle(PoseLandmark p1, PoseLandmark p2, PoseLandmark p3) {
    double angle = math.atan2(p3.y - p2.y, p3.x - p2.x) -
        math.atan2(p1.y - p2.y, p1.x - p2.x);
    double degree = (angle * 180 / math.pi).abs();
    if (degree > 180.0) {
      degree = 360.0 - degree;
    }
    return degree;
  }

  // 加上 exerciseName 參數，讓我們可以根據正反握給不同提示！
  void processPose(Pose pose, {String exerciseName = "划船"}) {
    final shoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final elbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final wrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final hip = pose.landmarks[PoseLandmarkType.rightHip];

    if (shoulder != null && elbow != null && wrist != null && hip != null) {
      // 1. 身體前傾角度 (看肩膀-骨盆的垂直關係，這裡簡化用 Y 軸或抓膝蓋，
      // 但為了簡單，我們先抓一個大概的手臂角度來計數)
      double armAngle = calculateAngle(shoulder, elbow, wrist);
      // 假設身體已經壓低了，我們專心看手肘的夾角 (armAngle)

      // 【下放到底】手臂幾乎伸直
      if (armAngle > 150) {
        if (!isPulling) {
          isPulling = true;
          isBadForm = false;
          // 根據名稱給不同提示
          if (exerciseName.contains('反握')) {
            feedbackMessage = "手肘貼緊，往肚臍拉！";
          } else {
            feedbackMessage = "準備拉起，感受背部夾緊！";
          }
        }
      }

      // 【拉到頂點】手肘彎曲小於 90 度 (這個數值可以根據你實際拉的角度微調)
      if (armAngle < 90) {
        if (isPulling) {
          isPulling = false;
          counter++;
          isBadForm = false;
          feedbackMessage = "漂亮！慢慢下放⬇️";
        }
      }
    }
  }

  void reset() {
    counter = 0;
    isPulling = false;
    feedbackMessage = "準備中...";
    isBadForm = false;
  }
}