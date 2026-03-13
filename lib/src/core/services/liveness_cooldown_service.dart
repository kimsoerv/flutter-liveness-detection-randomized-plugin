import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_liveness_detection_randomized_plugin/src/models/liveness_detection_cooldown.dart';

class LivenessCooldownService {
  static const String _cooldownKey = 'liveness_detection_cooldown';
  int _maxFailedAttempts = 3;
  int _cooldownMinutes = 5;
  int _maxCooldownRounds = 2;

  static LivenessCooldownService? _instance;
  static LivenessCooldownService get instance {
    _instance ??= LivenessCooldownService._();
    return _instance!;
  }

  LivenessCooldownService._();

  void configure({
    required int maxFailedAttempts,
    required int cooldownMinutes,
    required int maxCooldownRounds,
  }) {
    _maxFailedAttempts = maxFailedAttempts;
    _cooldownMinutes = cooldownMinutes;
    _maxCooldownRounds = maxCooldownRounds;
  }

  /// Configures the service and normalizes any persisted cooldown to the
  /// configured duration. This prevents older app versions (e.g. 10 minutes)
  /// from keeping users blocked longer than the current config (e.g. 5 minutes).
  Future<void> configureAndNormalize({
    required int maxFailedAttempts,
    required int cooldownMinutes,
    required int maxCooldownRounds,
  }) async {
    configure(
      maxFailedAttempts: maxFailedAttempts,
      cooldownMinutes: cooldownMinutes,
      maxCooldownRounds: maxCooldownRounds,
    );
    await capActiveCooldownToConfiguredDuration();
  }

  /// If an older, longer cooldown is already persisted, cap it to the currently
  /// configured duration (e.g. change 10 minutes -> 5 minutes).
  Future<LivenessDetectionCooldown> capActiveCooldownToConfiguredDuration() async {
    final state = await getCooldownState();
    if (!state.isInCooldown) return state;

    final max = Duration(minutes: _cooldownMinutes);
    final remaining = state.remainingCooldownTime;
    if (remaining <= max) return state;

    final capped = state.copyWith(
      cooldownEndTime: DateTime.now().add(max),
      isInCooldown: true,
    );
    await _saveCooldownState(capped);
    _cooldownController.add(capped);
    _startCooldownTimer(capped);
    return capped;
  }

  Timer? _cooldownTimer;
  final StreamController<LivenessDetectionCooldown> _cooldownController =
      StreamController<LivenessDetectionCooldown>.broadcast();

  Stream<LivenessDetectionCooldown> get cooldownStream =>
      _cooldownController.stream;

  Future<LivenessDetectionCooldown> getCooldownState() async {
    final prefs = await SharedPreferences.getInstance();
    final cooldownJson = prefs.getString(_cooldownKey);

    if (cooldownJson == null) {
      return const LivenessDetectionCooldown();
    }

    final cooldown = LivenessDetectionCooldown.fromJson(
      jsonDecode(cooldownJson),
    );

    // Check if cooldown has expired
    if (cooldown.isInCooldown &&
        cooldown.remainingCooldownTime.inSeconds <= 0) {
      return await _resetCooldown(clearRounds: false, clearBlocked: false);
    }

    return cooldown;
  }

  Future<LivenessDetectionCooldown> recordFailedAttempt() async {
    final currentState = await getCooldownState();

    if (currentState.isInCooldown || currentState.isBlocked) {
      return currentState;
    }

    final newFailedAttempts = currentState.failedAttempts + 1;

    LivenessDetectionCooldown newState;

    if (newFailedAttempts >= _maxFailedAttempts) {
      final nextRounds = currentState.cooldownRounds + 1;
      // Start cooldown
      final cooldownEndTime = DateTime.now().add(
        Duration(minutes: _cooldownMinutes),
      );

      newState = LivenessDetectionCooldown(
        failedAttempts: newFailedAttempts,
        cooldownRounds: nextRounds,
        cooldownEndTime: cooldownEndTime,
        isInCooldown: true,
        isBlocked: nextRounds >= _maxCooldownRounds,
      );

      _startCooldownTimer(newState);
    } else {
      newState = LivenessDetectionCooldown(
        failedAttempts: newFailedAttempts,
        cooldownRounds: currentState.cooldownRounds,
        cooldownEndTime: null,
        isInCooldown: false,
        isBlocked: false,
      );
    }

    await _saveCooldownState(newState);
    _cooldownController.add(newState);
    return newState;
  }

  Future<LivenessDetectionCooldown> recordSuccessfulAttempt() async {
    return await _resetCooldown(clearRounds: true, clearBlocked: true);
  }

  /// Clears failed-attempts and any active cooldown.
  /// Useful if you want to reset state between test runs.
  Future<LivenessDetectionCooldown> reset() async {
    return await _resetCooldown(clearRounds: true, clearBlocked: true);
  }

  Future<LivenessDetectionCooldown> _resetCooldown({
    required bool clearRounds,
    required bool clearBlocked,
  }) async {
    final currentState = await _loadCooldownState();
    final newState = LivenessDetectionCooldown(
      failedAttempts: 0,
      cooldownRounds: clearRounds ? 0 : currentState.cooldownRounds,
      cooldownEndTime: null,
      isInCooldown: false,
      isBlocked: clearBlocked ? false : currentState.isBlocked,
    );
    await _saveCooldownState(newState);
    _cooldownController.add(newState);
    _cooldownTimer?.cancel();
    return newState;
  }

  Future<void> _saveCooldownState(LivenessDetectionCooldown state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cooldownKey, jsonEncode(state.toJson()));
  }

  void _startCooldownTimer(LivenessDetectionCooldown state) {
    _cooldownTimer?.cancel();

    final remaining = state.remainingCooldownTime;
    if (remaining.inSeconds <= 0) return;

    _cooldownTimer = Timer(remaining, () async {
      await _resetCooldown(clearRounds: false, clearBlocked: false);
    });
  }

  Future<void> initializeCooldownTimer() async {
    final state = await getCooldownState();
    if (state.isInCooldown && state.remainingCooldownTime.inSeconds > 0) {
      _startCooldownTimer(state);
    }
    _cooldownController.add(state);
  }

  void dispose() {
    _cooldownTimer?.cancel();
    _cooldownController.close();
  }

  Future<LivenessDetectionCooldown> _loadCooldownState() async {
    final prefs = await SharedPreferences.getInstance();
    final cooldownJson = prefs.getString(_cooldownKey);
    if (cooldownJson == null) {
      return const LivenessDetectionCooldown();
    }
    return LivenessDetectionCooldown.fromJson(jsonDecode(cooldownJson));
  }
}
