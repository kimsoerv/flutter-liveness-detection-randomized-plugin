import 'package:flutter_liveness_detection_randomized_plugin/index.dart';

class LivenessDetectionStepItem {
  final LivenessDetectionStep step;
  final String title;
  final double? thresholdToCheck;
  /// Optional icon (e.g. SvgPicture, Image.asset for PNG).
  final Widget? icon;

  LivenessDetectionStepItem({
    required this.step,
    required this.title,
    this.thresholdToCheck,
    this.icon,
  });

  LivenessDetectionStepItem copyWith({
    LivenessDetectionStep? step,
    String? title,
    double? thresholdToCheck,
    Widget? icon,
  }) {
    return LivenessDetectionStepItem(
      step: step ?? this.step,
      title: title ?? this.title,
      thresholdToCheck: thresholdToCheck ?? this.thresholdToCheck,
      icon: icon ?? this.icon,
    );
  }
  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'step': step.index});
    result.addAll({'title': title});
    if (thresholdToCheck != null) {
      result.addAll({'thresholdToCheck': thresholdToCheck});
    }

    return result;
  }

  factory LivenessDetectionStepItem.fromMap(Map<String, dynamic> map) {
    return LivenessDetectionStepItem(
      step: LivenessDetectionStep.values[map['step'] ?? 0],
      title: map['title'] ?? '',
      thresholdToCheck: map['thresholdToCheck']?.toDouble(),
    );
  }

  String toJson() => json.encode(toMap());

  factory LivenessDetectionStepItem.fromJson(String source) =>
      LivenessDetectionStepItem.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Liveness Detection (step: $step, title: $title, thresholdToCheck: $thresholdToCheck)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LivenessDetectionStepItem &&
        other.step == step &&
        other.title == title &&
        other.thresholdToCheck == thresholdToCheck &&
        other.icon == icon;
  }

  @override
  int get hashCode {
    return step.hashCode ^
        title.hashCode ^
        thresholdToCheck.hashCode ^
        icon.hashCode;
  }
}
