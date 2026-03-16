import 'package:flutter_liveness_detection_randomized_plugin/index.dart';
import 'package:flutter_liveness_detection_randomized_plugin/src/localization/liveness_localizations.dart';

List<LivenessDetectionStepItem> buildDefaultSteps(String? languageCode) {
  final labels = LivenessLocalizations.of(languageCode).defaultLabels();
  return [
    LivenessDetectionStepItem(
      step: LivenessDetectionStep.blink,
      title: labels.blink ?? 'Blink 2-3 Times',
    ),
    LivenessDetectionStepItem(
      step: LivenessDetectionStep.lookUp,
      title: labels.lookUp ?? 'Look UP',
    ),
    LivenessDetectionStepItem(
      step: LivenessDetectionStep.lookDown,
      title: labels.lookDown ?? 'Look DOWN',
    ),
    LivenessDetectionStepItem(
      step: LivenessDetectionStep.lookRight,
      title: labels.lookRight ?? 'Look RIGHT',
    ),
    LivenessDetectionStepItem(
      step: LivenessDetectionStep.lookLeft,
      title: labels.lookLeft ?? 'Look LEFT',
    ),
    LivenessDetectionStepItem(
      step: LivenessDetectionStep.smile,
      title: labels.smile ?? 'Smile',
    ),
  ];
}
