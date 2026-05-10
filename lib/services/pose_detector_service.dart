import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PoseDetectorService {
  late PoseDetector _poseDetector;

  PoseDetectorService() {
    // 修正點：在新版 ML Kit 中，參數名稱從 modelSize 改為 modelQuantity
    // 請確保妳的程式碼是這樣寫的：
    final options = PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.base,
    );
    _poseDetector = PoseDetector(options: options);
  }

  Future<List<Pose>> getPoses(InputImage inputImage) async {
    return await _poseDetector.processImage(inputImage);
  }

  void close() {
    _poseDetector.close();
  }
}