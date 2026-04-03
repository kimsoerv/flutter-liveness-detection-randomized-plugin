import 'package:flutter_liveness_detection_randomized_plugin/index.dart';
import 'package:flutter_liveness_detection_randomized_plugin/src/localization/liveness_localizations.dart';

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
    // reset TotalFailedAttempts
    LivenessCooldownService.instance.setTotalFailedAttempts = 0;
    await LivenessCooldownService.instance.reset();
  }

  /// Get status
  Future<LivenessDetectionCooldown> getStatusLivenessDetection() async {
    return await LivenessCooldownService.instance.getCooldownState();
  }

  int get getTotalFailedAttempts {
    return LivenessCooldownService.instance.getTotalFailedAttempts;
  }

  String _formatMinutesSeconds(Duration duration) {
    final totalSeconds = duration.inSeconds.clamp(0, 24 * 60 * 60);
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<String?> _openCaptureOnly({
    required BuildContext context,
    required LivenessDetectionConfig config,
  }) async {
    if (!context.mounted) return null;
    return await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LivenessCaptureOnlyView(config: config),
      ),
    );
  }

  Future<void> _closeBottomSheet(BuildContext context) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.pop();
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  Future<String?> _openCaptureOnlyAndHandleResult({
    required BuildContext context,
    required LivenessDetectionConfig config,
  }) async {
    final result = await _openCaptureOnly(context: context, config: config);
    if (result != null && config.enableCooldownOnFailure) {
      await LivenessCooldownService.instance.recordSuccessfulAttempt();
    }
    return result;
  }

  Future<String?> livenessDetection({
    required BuildContext context,
    required LivenessDetectionConfig config,
    final VoidCallback? onTryAgain,
  }) async {
    await LivenessLocalizations.load(config.languageCode);
    final strings = LivenessLocalizations.of(config.languageCode);



    if (config.enableCooldownOnFailure) {
      await LivenessCooldownService.instance.configureAndNormalize(
        maxFailedAttempts: config.maxFailedAttempts,
        cooldownMinutes: config.cooldownMinutes,
        maxCooldownRounds: config.maxCooldownRounds,
      );

      final cooldownState = await LivenessCooldownService.instance.getCooldownState();

      if ((cooldownState.isInCooldown || cooldownState.isBlocked) && context.mounted) {
        if (cooldownState.isBlocked) {
          final completer = Completer<String?>();
          bool didStartCapture = false;

          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) {
              return LivenessBottomSheetInfoWidget.forType(
                type: LivenessBottomSheetInfoType.blocked,
                isDarkMode: config.isDarkMode,
                languageCode: config.languageCode,
                countdownDuration: cooldownState.remainingCooldownTime,
                primaryColor: config.primaryColor,
                icon: config.icons?[2],
                onTryAgain: () async {
                  didStartCapture = true;
                  await _closeBottomSheet(context);
                  final result = await _openCaptureOnlyAndHandleResult(
                    context: context,
                    config: config,
                  );
                  if (!completer.isCompleted) {
                    completer.complete(result);
                  }
                },
              );
            },
          );

          if (!didStartCapture) {
            return null;
          }

          return await completer.future;
        } else if (cooldownState.isInCooldown) {
          final wait = _formatMinutesSeconds(cooldownState.remainingCooldownTime);
          final completer = Completer<String?>();

          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) {
              return LivenessBottomSheetInfoWidget.forType(
                type: LivenessBottomSheetInfoType.locked,
                isDarkMode: config.isDarkMode,
                languageCode: config.languageCode,
                formattedWaitTime: wait,
                primaryColor: config.primaryColor,
                countdownDuration: cooldownState.remainingCooldownTime,
                icon: config.icons?[2],
                onTryAgain: () {
                  onTryAgain?.call();
                  if (!completer.isCompleted) {
                    completer.complete(null);
                  }
                },
              );
            },
          );

          if (!completer.isCompleted) {
            return null;
          }
          return await completer.future;
        }

        if (cooldownState.isBlocked) {
          return await _openCaptureOnlyAndHandleResult(
            context: context,
            config: config,
          );
        }
      }
    }

    if (!context.mounted) return null;

    final String? capturedFacePath = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LivenessDetectionView(config: config),
      ),
    );

    if (config.enableCooldownOnFailure) {
      if (capturedFacePath != null) {
        await LivenessCooldownService.instance.recordSuccessfulAttempt();
      } else {
        final updatedState = await LivenessCooldownService.instance.recordFailedAttempt();

        if (context.mounted) {
          if (updatedState.isBlocked) {

            final completer = Completer<String?>();
            bool didStartCapture = false;

            await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) {
                return LivenessBottomSheetInfoWidget.forType(
                  type: LivenessBottomSheetInfoType.blocked,
                  isDarkMode: config.isDarkMode,
                  languageCode: config.languageCode,
                  countdownDuration: updatedState.remainingCooldownTime,
                  primaryColor: config.primaryColor,
                  icon: config.icons?[2],
                  onTryAgain: () async {
                    didStartCapture = true;
                    await _closeBottomSheet(context);
                    final result = await _openCaptureOnlyAndHandleResult(
                      context: context,
                      config: config,
                    );
                    if (!completer.isCompleted) {
                      completer.complete(result);
                    }
                  },
                );
              },
            );

            if (!didStartCapture) {
              return null;
            }
            return await completer.future;

          } else if (updatedState.isInCooldown) {
            final wait = _formatMinutesSeconds(updatedState.remainingCooldownTime);
            final completer = Completer<String?>();

            await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) {
                return LivenessBottomSheetInfoWidget.forType(
                  type: LivenessBottomSheetInfoType.locked,
                  isDarkMode: config.isDarkMode,
                  languageCode: config.languageCode,
                  primaryColor: config.primaryColor,
                  formattedWaitTime: wait,
                  countdownDuration: updatedState.remainingCooldownTime,
                  icon: config.icons?[2],
                  onTryAgain: () {
                    onTryAgain?.call();
                    if (!completer.isCompleted) {
                      completer.complete(null);
                    }
                  },
                );
              },
            );

            if (!completer.isCompleted) {
              return null;
            }
            return await completer.future;
          } else {
            final maxAttempts = config.maxFailedAttempts;
            final attemptsUsed = updatedState.failedAttempts.clamp(
              0,
              maxAttempts,
            );
            final completer = Completer<String?>();

            await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) {
                return LivenessBottomSheetInfoWidget.forType(
                  type: LivenessBottomSheetInfoType.manyAttempts,
                  isDarkMode: config.isDarkMode,
                  languageCode: config.languageCode,
                  primaryColor: config.primaryColor,
                  attemptsLeftText: strings.attemptsText(
                    attemptsUsed,
                    maxAttempts,
                  ),
                  icon: config.icons?[1],
                  onTryAgain: () {
                    onTryAgain?.call();
                    if (!completer.isCompleted) {
                      completer.complete(null);
                    }
                  },
                );
              },
            );

            if (!completer.isCompleted) {
              return null;
            }
            return await completer.future;

          }
        }
      }
    } else {
      // No cooldown tracking: still show timeout sheet if requested.
      if (capturedFacePath == null && context.mounted) {
        final completer = Completer<String?>();
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) {
            return LivenessBottomSheetInfoWidget.forType(
              type: LivenessBottomSheetInfoType.manyAttempts,
              isDarkMode: config.isDarkMode,
              languageCode: config.languageCode,
              primaryColor: config.primaryColor,
              attemptsLeftText: strings.failedText(),
              icon: config.icons?[1],
              onTryAgain: () {
                onTryAgain?.call();
                if (!completer.isCompleted) {
                  completer.complete(null);
                }
              },
            );
          },
        );
        if (!completer.isCompleted) {
          return null;
        }
        return await completer.future;
      }
    }

    return capturedFacePath;
  }

  Future<String?> getPlatformVersion() {
    return FlutterLivenessDetectionRandomizedPluginPlatform.instance
        .getPlatformVersion();
  }
}
