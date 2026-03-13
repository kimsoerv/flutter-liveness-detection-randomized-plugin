class LivenessDetectionCooldown {
  final int failedAttempts;
  final int cooldownRounds;
  final DateTime? cooldownEndTime;
  final bool isInCooldown;
  final bool isBlocked;

  const LivenessDetectionCooldown({
    this.failedAttempts = 0,
    this.cooldownRounds = 0,
    this.cooldownEndTime,
    this.isInCooldown = false,
    this.isBlocked = false,
  });

  LivenessDetectionCooldown copyWith({
    int? failedAttempts,
    int? cooldownRounds,
    DateTime? cooldownEndTime,
    bool? isInCooldown,
    bool? isBlocked,
  }) {
    return LivenessDetectionCooldown(
      failedAttempts: failedAttempts ?? this.failedAttempts,
      cooldownRounds: cooldownRounds ?? this.cooldownRounds,
      cooldownEndTime: cooldownEndTime ?? this.cooldownEndTime,
      isInCooldown: isInCooldown ?? this.isInCooldown,
      isBlocked: isBlocked ?? this.isBlocked,
    );
  }

  Duration get remainingCooldownTime {
    if (cooldownEndTime == null || !isInCooldown) {
      return Duration.zero;
    }
    final remaining = cooldownEndTime!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Map<String, dynamic> toJson() {
    return {
      'failedAttempts': failedAttempts,
      'cooldownRounds': cooldownRounds,
      'cooldownEndTime': cooldownEndTime?.millisecondsSinceEpoch,
      'isInCooldown': isInCooldown,
      'isBlocked': isBlocked,
    };
  }

  factory LivenessDetectionCooldown.fromJson(Map<String, dynamic> json) {
    return LivenessDetectionCooldown(
      failedAttempts: json['failedAttempts'] ?? 0,
      cooldownRounds: json['cooldownRounds'] ?? 0,
      cooldownEndTime: json['cooldownEndTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['cooldownEndTime'])
          : null,
      isInCooldown: json['isInCooldown'] ?? false,
      isBlocked: json['isBlocked'] ?? false,
    );
  }
}
