import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_liveness_detection_randomized_plugin/index.dart';

class LivenessLocalizations {
  final String languageCode;

  const LivenessLocalizations._(this.languageCode);

  static const String _packageName =
      'flutter_liveness_detection_randomized_plugin';
  static const String _assetBase = 'packages/$_packageName/assets/i18n';

  static final Map<String, Map<String, dynamic>> _cache = {};

  factory LivenessLocalizations.of(String? languageCode) {
    return LivenessLocalizations._(_normalize(languageCode));
  }

  static String _normalize(String? code) {
    final value = (code ?? 'en').toLowerCase().trim();
    if (value.startsWith('km') || value.startsWith('kh')) return 'km';
    if (value.startsWith('zh')) return 'zh';
    return 'en';
  }

  static Future<void> load(String? languageCode) async {
    final code = _normalize(languageCode);
    if (_cache.containsKey(code)) return;

    final resolved = await _resolveAssetPath(code);
    if (kDebugMode) {
      debugPrint('[LivenessLocalizations] load code=$code resolved=$resolved');
    }
    if (resolved != null) {
      try {
        final jsonString = await rootBundle.loadString(resolved);
        final decoded = json.decode(jsonString);
        if (decoded is Map<String, dynamic>) {
          _cache[code] = decoded;
          if (kDebugMode) {
            debugPrint(
              '[LivenessLocalizations] loaded ${decoded.length} keys for $code',
            );
          }
          return;
        }
      } catch (_) {
        // Fall through to empty map.
      }
    }

    if (kDebugMode) {
      debugPrint('[LivenessLocalizations] failed to load for $code');
    }
    _cache[code] = const {};
  }

  static Future<String?> _resolveAssetPath(String code) async {
    // Fast path with expected package asset location.
    final direct = '$_assetBase/$code.json';
    try {
      await rootBundle.loadString(direct);
      return direct;
    } catch (_) {
      // Continue to manifest scan.
    }

    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifest = json.decode(manifestContent);
      final candidates = manifest.keys.where(
        (k) => k.contains(_packageName) && k.endsWith('/i18n/$code.json'),
      );
      if (kDebugMode) {
        debugPrint(
          '[LivenessLocalizations] manifest candidates for $code: ${candidates.toList()}',
        );
      }
      return candidates.isNotEmpty ? candidates.first : null;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> get _data => _cache[languageCode] ?? const {};

  String _format(String template, Map<String, String> params) {
    var result = template;
    params.forEach((key, value) {
      result = result.replaceAll('{$key}', value);
    });
    return result;
  }

  String _t(String key, {Map<String, String>? params}) {
    final value = _data[key] ?? _fallbackEn[key];
    final text = value is String ? value : '';
    if (text.isEmpty) return key;
    if (params == null || params.isEmpty) return text;
    return _format(text, params);
  }

  List<String> _list(String key) {
    final value = _data[key] ?? _fallbackEn[key];
    if (value is List) {
      return value.whereType<String>().toList();
    }
    return const [];
  }

  LivenessDetectionLabelModel defaultLabels() {
    return LivenessDetectionLabelModel(
      blink: _t('step_blink'),
      lookUp: _t('step_look_up'),
      lookDown: _t('step_look_down'),
      lookLeft: _t('step_look_left'),
      lookRight: _t('step_look_right'),
      smile: _t('step_smile'),
    );
  }

  String tutorialSufficientLightingTitle() =>
      _t('tutorial_sufficient_lighting_title');

  String tutorialSufficientLightingDescription() =>
      _t('tutorial_sufficient_lighting_desc');

  String tutorialTitle() => _t('tutorial_title');

  String tutorialStraightAheadTitle() => _t('tutorial_straight_ahead_title');

  String tutorialStraightAheadDescription() =>
      _t('tutorial_straight_ahead_desc');

  String tutorialTimeLimitTitle() => _t('tutorial_time_limit_title');

  String tutorialTimeLimitDescription(int seconds) => _t(
        'tutorial_time_limit_desc',
        params: {'seconds': seconds.toString()},
      );

  String tutorialStartButton() => _t('tutorial_start_button');

  String faceVerificationTitle() => _t('face_verification_title');

  String faceNotFound() => _t('face_not_found');

  String tipsTitle() => _t('tips_title');

  List<String> tipsList() => _list('tips_list');

  String tooManyFailedAttemptsTitle() => _t('too_many_failed_attempts_title');

  String failedAttemptsMessage(int maxAttempts) => _t(
        'failed_attempts_message',
        params: {'max': maxAttempts.toString()},
      );

  String remainingWaitTime() => _t('remaining_wait_time');

  String back() => _t('back');

  String packageVersionLabel(String version) => _t(
        'package_version_label',
        params: {'version': version},
      );

  String retryIn(String formattedTime) => _t(
        'retry_in',
        params: {'time': formattedTime},
      );

  String scanTimedOutTitle() => _t('scan_timed_out_title');

  String scanTimedOutMessage() => _t('scan_timed_out_message');

  String tryAgain() => _t('try_again');

  String temporarilyBlockedTitle() => _t('temporarily_blocked_title');

  String temporarilyLockedMessage(String waitWithSuffix) => _t(
        'temporarily_locked_message',
        params: {'wait': waitWithSuffix},
      );

  String temporarilyBlockedMessage() => _t('temporarily_blocked_message');

  String ok() => _t('ok');
  String retake() => _t('retake');

  String verificationFailed(int seconds) => _t(
        'verification_failed',
        params: {'seconds': seconds.toString()},
      );

  String verificationSuccess() => _t('verification_success');

  String attemptsText(int used, int max) => _t(
        'attempts_text',
        params: {'used': used.toString(), 'max': max.toString()},
      );

  String failedText() => _t('failed_text');
}

const Map<String, dynamic> _fallbackEn = {
  'step_blink': 'Blink 2-3 Times',
  'step_look_up': 'Look UP',
  'step_look_down': 'Look DOWN',
  'step_look_left': 'Look LEFT',
  'step_look_right': 'Look RIGHT',
  'step_smile': 'Smile',
  'tutorial_title': 'Liveness Detection - Tutorial',
  'tutorial_sufficient_lighting_title': 'Sufficient Lighting',
  'tutorial_sufficient_lighting_desc':
      'Make sure you are in an area that has sufficient lighting and that your ears are not covered by anything',
  'tutorial_straight_ahead_title': 'Straight Ahead View',
  'tutorial_straight_ahead_desc':
      'Hold the phone at eye level and look straight at the camera',
  'tutorial_time_limit_title': 'Time Limit Verification',
  'tutorial_time_limit_desc':
      'The time limit given for the liveness detection system verification process is {seconds} seconds',
  'tutorial_start_button': 'Start the Liveness Detection System',
  'face_verification_title': 'Face Verification',
  'face_not_found': 'User Face Not Found...',
  'tips_title': 'Tips for the best result',
  'tips_list': [
    'Position your face in the oval',
    'Look directly at the camera',
    'Ensure good lighting on your face',
    'Remove your glasses or mask',
  ],
  'too_many_failed_attempts_title': 'Too Many Failed Attempts',
  'failed_attempts_message':
      'You have failed liveness verification {max} times.\nPlease wait before trying again.',
  'remaining_wait_time': 'Remaining Wait Time',
  'back': 'Back',
  'package_version_label': 'Package Version: {version}',
  'retry_in': 'Retry in: {time}',
  'scan_timed_out_title': 'Scan timed out',
  'scan_timed_out_message':
      "We couldn't complete the scan in time. Please ensure you are in a well-lit area and follow the prompts closely.",
  'try_again': 'Try Again',
  'temporarily_blocked_title': 'Temporarily blocked',
  'temporarily_locked_message':
      'For your protection, we’ve temporarily locked this feature after multiple unsuccessful attempts. Please wait {wait} before trying again.',
  'temporarily_blocked_message':
      'For your protection, we’ve temporarily locked this feature after multiple unsuccessful attempts. Please take a photo',
  'ok': 'OK',
  'verification_failed':
      'Verification of liveness detection failed, please try again. (Exceeds time limit {seconds} second.)',
  'verification_success': 'Verification of liveness detection success!',
  'attempts_text': 'Attempts: {used}/{max}',
  'failed_text': 'Failed',
};
