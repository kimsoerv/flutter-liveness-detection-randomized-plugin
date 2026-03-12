import 'package:flutter_liveness_detection_randomized_plugin/index.dart';

class FlutterLivenessDetectionRandomizedPlugin {
  FlutterLivenessDetectionRandomizedPlugin._privateConstructor();
  static final FlutterLivenessDetectionRandomizedPlugin instance =
      FlutterLivenessDetectionRandomizedPlugin._privateConstructor();
  final List<LivenessDetectionThreshold> _thresholds = [];

  List<LivenessDetectionThreshold> get thresholdConfig {
    return _thresholds;
  }

  /// Clears cooldown + failed-attempts stored on device.
  Future<void> resetCooldown() async {
    await LivenessCooldownService.instance.reset();
  }

  String _formatMinutesSeconds(Duration duration) {
    final totalSeconds = duration.inSeconds.clamp(0, 24 * 60 * 60);
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<String?> livenessDetection({
    required BuildContext context,
    required LivenessDetectionConfig config,
    required bool isBottomSheetUI,
  }) async {
    if (config.enableCooldownOnFailure) {
      await LivenessCooldownService.instance.configureAndNormalize(
        maxFailedAttempts: config.maxFailedAttempts,
        cooldownMinutes: config.cooldownMinutes,
      );
      final cooldownState = await LivenessCooldownService.instance.getCooldownState();
      if (cooldownState.isInCooldown && context.mounted) {

        if (isBottomSheetUI) {
          final wait = _formatMinutesSeconds(
            cooldownState.remainingCooldownTime,
          );

          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) {
              return LivenessBottomSheetInfoWidget.forType(
                type: LivenessBottomSheetInfoType.locked,
                isDarkMode: config.isDarkMode,
                formattedWaitTime: wait,
                countdownDuration: cooldownState.remainingCooldownTime,
                icon: config.icons?[2],
              );
            },
          );

          return null;
        }

        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => LivenessCooldownWidget(
              cooldownState: cooldownState,
              isDarkMode: config.isDarkMode,
              maxFailedAttempts: config.maxFailedAttempts,
            ),
          ),
        );

        return null;
      }
    }

    if (!context.mounted) return null;
    
    final String? capturedFacePath = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LivenessDetectionView(
          config: config,
        ),
      ),
    );

    if (config.enableCooldownOnFailure) {
      if (capturedFacePath != null) {
        await LivenessCooldownService.instance.recordSuccessfulAttempt();
      } else {
        final updatedState =
            await LivenessCooldownService.instance.recordFailedAttempt();

        if (context.mounted && isBottomSheetUI) {
          if (updatedState.isInCooldown) {
            final wait = _formatMinutesSeconds(
              updatedState.remainingCooldownTime,
            );
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) {
                return LivenessBottomSheetInfoWidget.forType(
                  type: LivenessBottomSheetInfoType.locked,
                  isDarkMode: config.isDarkMode,
                  formattedWaitTime: wait,
                  countdownDuration: updatedState.remainingCooldownTime,
                  icon: config.icons?[2],
                );
              },
            );
          } else {
            final maxAttempts = config.maxFailedAttempts;
            final attemptsUsed =
                updatedState.failedAttempts.clamp(0, maxAttempts);
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) {
                return LivenessBottomSheetInfoWidget.forType(
                  type: LivenessBottomSheetInfoType.manyAttempts,
                  isDarkMode: config.isDarkMode,
                  attemptsLeftText: 'Attempts: $attemptsUsed/$maxAttempts',
                  icon: config.icons?[1],
                );
              },
            );
          }
        }
      }
    } else {
      // No cooldown tracking: still show timeout sheet if requested.
      if (capturedFacePath == null && context.mounted && isBottomSheetUI) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) {
            return LivenessBottomSheetInfoWidget.forType(
              type: LivenessBottomSheetInfoType.manyAttempts,
              isDarkMode: config.isDarkMode,
              icon: config.icons?[1],
            );
          },
        );
      }
    }

    return capturedFacePath;
  }

  Future<String?> getPlatformVersion() {
    return FlutterLivenessDetectionRandomizedPluginPlatform.instance
        .getPlatformVersion();
  }
}
